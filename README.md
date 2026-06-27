# rx6600-llm-inference

> Note: host addresses in this public mirror are placeholders (`<RIG_A_IP>` etc.). Substitute your own LAN values.

Local LLM inference across the AMD RX 6600 rigs via **llama.cpp + Vulkan/RADV**.

Distinct from the TFM compute pipeline, which uses the same rigs through
ROCm/HIP/CuPy. This repo is **Vulkan LLM serving only**.

## TL;DR

- 8× RX 6600 (64 GB pool) per rig serves **DeepSeek-R1-Distill-Qwen-32B Q4_K_M**
  at ~32 t/s — on par with Zeus's dual 3080 Ti.
- A 70B Q4 fits and runs on the 8-GPU pool.

## Layout

```
.
├── CLAUDE_PROJECT_INSTRUCTIONS.md   Paste into the Claude Project
├── README.md                        This file
├── docs/
│   ├── RUNBOOK.md                   Step-by-step operating procedures
│   ├── BENCHMARKS.md                Recorded results + template
│   ├── DISTRIBUTED.md               RPC-cluster research + verify-before-spend
│   ├── ZEUS_235B.md                 Zeus-solo 235B (MoE offload) + XMP fix
│   └── MODELS.md                    Model picks + agentic setup (Zeus vs cluster)
├── scripts/
│   ├── device_check.sh              Confirm GPU device count (Vulkan + ROCm)
│   ├── bench_32b.sh                 Reproduce the 32B benchmark
│   ├── serve_32b.sh                 Start the 32B llama-server
│   └── serve_70b.sh                 Start a 70B llama-server (download required)
└── configs/
    └── models.md                    Model paths, sizes, split notes
```

## Safety rules (read before running anything)

- **rrig6600b is the golden reference. Never change its packages.** Test any
  driver / package changes on rrig6600 or rrig6600c first.
- 8-GPU cold start has crashed a rig (power spike). Warm up or power-cap first.
- Clone before editing; dual-push origin + public; never commit from a sandbox.

## Hosts

| Host       | Address          | GPUs            |
|------------|------------------|-----------------|
| SER8       | <JUMP_HOST_IP>     | jump host       |
| Zeus       | <GPU_HOST_IP>    | 2× RTX 3080 Ti  |
| rrig6600   | <RIG_A_IP>    | 8× RX 6600      |
| rrig6600b  | <RIG_B_IP>    | 8× RX 6600 (golden) |
| rrig6600c  | <RIG_C_IP>    | 8× RX 6600      |
