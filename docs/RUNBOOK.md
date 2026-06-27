# Runbook — RX 6600 LLM Inference

All commands assume you are on **SER8** and reach the rigs over SSH
(`rrig6600`, `rrig6600b`, `rrig6600c` host aliases). Pick a **clone rig**
(rrig6600 or rrig6600c) for anything that changes packages or risks a crash.
Never run package changes against rrig6600b.

---

## 1. Pre-flight: confirm device visibility

All eight cards should show up on both ROCm and Vulkan.

```bash
# ROCm device count
ssh rrig6600c "rocm-smi 2>/dev/null | grep -c '0x73ff'"   # expect 8

# Vulkan (RADV) device count
ssh rrig6600c "vulkaninfo --summary 2>/dev/null | grep -c PHYSICAL_DEVICE_TYPE_DISCRETE_GPU"  # expect 8
```

If either returns fewer than 8, a card has dropped off the bus — check risers /
power before running a job.

---

## 2. Power safety before multi-GPU load

The one recorded failure was an 8-GPU cold-start power spike that hard-reset a
rig. Mitigate before loading all cards at once:

```bash
# Cap each card's power draw before a full-pool run (tune watts to taste)
ssh rrig6600c "for i in \$(seq 0 7); do sudo rocm-smi -d \$i --setpoweroverdrive 100; done"
```

Alternatively, validate with a 4-GPU subset first (see §3), then scale up.

---

## 3. Benchmark the 32B model

Full 8-GPU pool:

```bash
ssh rrig6600c
cd ~/llama.cpp
./build/bin/llama-bench \
    -m DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf \
    -p 512 -n 128 -ngl 99
```

Conservative 4-GPU subset (more stable; the 32B still fits in 32 GB):

```bash
GGML_VULKAN_DEVICE=0,1,2,3 ./build/bin/llama-bench \
    -m DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf \
    -p 256 -n 64 -ngl 99
```

Expected: ~32 t/s generation on the full 8-GPU pool. Record results in
`docs/BENCHMARKS.md`.

---

## 4. Serve the 32B as an API

```bash
ssh rrig6600c
cd ~/llama.cpp
./build/bin/llama-server \
    --model ~/llama.cpp/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf \
    --host 0.0.0.0 --port 8080 \
    --ctx-size 4096 \
    --n-gpu-layers 99 \
    --tensor-split 1,1,1,1,1,1,1,1
```

Reach it from SER8 at `http://<RIG_C_IP>:8080`. The `--tensor-split` list
length must match the number of enumerated Vulkan devices (8).

---

## 5. Serve a 70B (optional, needs download)

```bash
ssh rrig6600c
cd ~/llama.cpp
huggingface-cli download bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF \
    DeepSeek-R1-Distill-Llama-70B-Q4_K_M.gguf --local-dir ./

./build/bin/llama-server \
    --model DeepSeek-R1-Distill-Llama-70B-Q4_K_M.gguf \
    --host 0.0.0.0 --port 8080 \
    --ctx-size 4096 --n-gpu-layers 99 \
    --tensor-split 1,1,1,1,1,1,1,1
```

70B Q4 (~40 GB) spreads ~5 GB/card across the 8 GPUs, leaving ~3 GB/card for KV
cache and context. A 70B Q6_K (~55 GB) is very tight on a 64 GB pool and not
practical with usable context — Q4 is the ceiling for 70B on a single rig.

---

## 6. Teardown

```bash
# stop a running server
ssh rrig6600c "pkill -f llama-server"

# remove power cap if set
ssh rrig6600c "for i in \$(seq 0 7); do sudo rocm-smi -d \$i --resetpoweroverdrive; done"
```

---

## Notes

- `llama.cpp` = Vulkan build; `llama-rocm` = separate ROCm build. Use the Vulkan
  build for multi-GPU LLM pooling.
- PCIe 1x risers bottleneck prompt processing and multi-step agent loops far more
  than single-stream generation. Batch/offline reasoning tolerates it well;
  interactive coding less so.
