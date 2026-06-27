# Claude Project Instructions — RX 6600 LLM Inference

Paste the section below into the Project's **custom instructions** field
(Project → settings → instructions). Keep this file in the repo as the
source of truth; update both together.

---

## Context

This project covers running local LLM inference across the AMD RX 6600 mining
rigs using **llama.cpp with the Vulkan/RADV backend**. This is separate from the
TFM compute work, which uses the same rigs via ROCm/HIP/CuPy. Do not
conflate the two: TFM = ROCm compute; this project = Vulkan LLM serving.

## Hardware topology

| Host       | Address          | GPUs            | Role                          |
|------------|------------------|-----------------|-------------------------------|
| SER8       | <JUMP_HOST_IP>     | —               | Daily driver / jump host      |
| Zeus       | <GPU_HOST_IP>    | 2× RTX 3080 Ti  | CUDA reference, LLM baseline  |
| rrig6600   | <RIG_A_IP>    | 8× RX 6600      | Clone — expendable test rig   |
| rrig6600b  | <RIG_B_IP>    | 8× RX 6600      | **GOLDEN REFERENCE — do not touch packages** |
| rrig6600c  | <RIG_C_IP>    | 8× RX 6600      | Clone — expendable test rig   |

Each AMD rig is **8× RX 6600** (64 GB aggregate VRAM), all eight visible to both
ROCm and the Vulkan/RADV backend. (Historically the rigs carried 12 cards and a
Mesa device cap was a concern; that is no longer the case — they are now 8-card
units, so there is no enumeration limit to work around.)

## Established facts

- **Backend:** llama.cpp Vulkan/RADV is what pools the cards for LLM inference.
  A separate `llama-rocm` build directory also exists; keep the two distinct.
- **Pool:** 8× RX 6600 = 64 GB. Enough for a 32B Q4 with generous context, or a
  70B Q4 (~40 GB, ~5 GB/card).
- **Validated model:** DeepSeek-R1-Distill-Qwen-32B-Q4_K_M (~19 GB), ~32 t/s
  generation on 8× RX 6600 — effectively matching Zeus's dual 3080 Ti (~31 t/s).
- **70B Q4:** ran successfully on the 8-GPU pool, later deleted to reclaim space.
- **Known risk:** an 8-GPU cold-start benchmark crashed a rig once — suspected
  power spike. Warm up / power-cap before loading all GPUs simultaneously.

## Standing rules (inherited from TFM, apply here too)

1. **rrig6600b is the golden reference — never modify its packages.** Any
   driver / package experiments go on rrig6600 or rrig6600c first.
2. Clone the public repo before touching code; do not commit from a sandbox.
3. Dual-push to both origin and public remotes is mandatory.
4. Lead with the simplest solution first; accept direct corrections without
   over-explaining.
5. Never use the word "lottery" in any TFM-adjacent context — always "TFM."

## Current open question

Confirm the post-reconfiguration 8-GPU pool benchmarks consistent with the prior
~32 t/s on the 32B Q4, and decide whether a 70B Q4 is worth keeping resident as a
standing service versus loading on demand. The modded 20 GB 3080 (when it
arrives) is the other path worth A/B-testing against the 8× RX 6600 pool on the
same 32B Q4 workload — single-card bandwidth vs. aggregate VRAM.
