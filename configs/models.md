# Models

Reference for models used on the RX 6600 Vulkan pool. All paths are on the rig
under `~/llama.cpp/` unless noted. The `llama-rocm/` directory holds a parallel
ROCm build and may carry duplicate copies — keep the Vulkan build authoritative.

| Model                            | Quant  | ~Size | File / source                                            | Notes |
|----------------------------------|--------|-------|----------------------------------------------------------|-------|
| DeepSeek-R1-Distill-Qwen-32B     | Q4_K_M | 19 GB | `DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf` (local)       | Validated daily driver; ~32 t/s on 8 GPUs |
| DeepSeek-R1-Distill-Llama-70B    | Q4_K_M | 40 GB | `bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF`           | Fits 8-GPU pool (~5 GB/card); was deleted to reclaim space |
| DeepSeek-R1-Distill-Llama-70B    | Q6_K   | 55 GB | same repo, Q6_K file                                     | Too tight on a 64 GB pool with usable context — not practical; Q4 is the 70B ceiling per rig |

## Tensor-split cheatsheet

The `--tensor-split` list length must equal the number of enumerated Vulkan
devices (8).

- Full pool: `1,1,1,1,1,1,1,1`
- 4-GPU subset (safer cold start): set `GGML_VULKAN_DEVICE=0,1,2,3` and
  `--tensor-split 1,1,1,1`

## VRAM math (per card, even split across 8 GPUs)

| Model size | per card |
|------------|----------|
| 19 GB (32B Q4)  | ~2.4 GB |
| 40 GB (70B Q4)  | ~5.0 GB |
| 55 GB (70B Q6)  | ~6.9 GB — too tight for usable context |

RX 6600 has 8 GB/card, so headroom for KV cache / context is generous at Q4. The
70B Q6 leaves only ~1 GB/card for context and overhead, so Q4 is the practical
ceiling for a 70B on a single rig.
