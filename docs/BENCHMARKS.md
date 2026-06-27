# Benchmarks

## Recorded results

| Date       | Host       | GPUs | Backend      | Model                              | Quant   | pp t/s | tg t/s | Notes |
|------------|------------|------|--------------|------------------------------------|---------|--------|--------|-------|
| 2026-01    | Zeus       | 2    | Vulkan       | DeepSeek-R1-Distill-Qwen-32B       | Q4_K_M  | 664    | 31     | dual 3080 Ti baseline |
| 2026-01    | rrig6600b  | 8    | Vulkan/RADV  | DeepSeek-R1-Distill-Qwen-32B       | Q4_K_M  | —      | ~32    | matched Zeus; 8-GPU cold start crashed once |
| 2026-01    | rrig6600b  | 8    | Vulkan/RADV  | DeepSeek-R1-Distill-Llama-70B      | Q4_K_M  | —      | ~15–20 (est) | ran successfully, later deleted for space |

## Template for new runs

```
Date:
Host:
GPUs enumerated (Vulkan):
GPU driver version:
Model + quant:
Command:
pp t/s:
tg t/s:
Peak VRAM/card:
Power cap:
Stability (clean / crash / throttle):
```

## Things worth measuring next

- Re-confirm the 8-GPU pool benchmarks consistent with the prior ~32 t/s on 32B
  Q4 after the rig reconfiguration, power-capped.
- Prompt-processing penalty from the PCIe 1x risers at longer prompt lengths.
- Single modded-20GB-3080 (when it arrives) vs. the 8× RX 6600 pool on the same
  32B Q4 workload — bandwidth vs. aggregate-VRAM tradeoff.
