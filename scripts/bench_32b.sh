#!/usr/bin/env bash
# Reproduce the 32B benchmark. Defaults to full 8-GPU pool.
# Usage: ./bench_32b.sh <host> [device_csv]
#   ./bench_32b.sh rrig6600c              # all enumerated GPUs
#   ./bench_32b.sh rrig6600c 0,1,2,3      # 4-GPU subset (safer cold start)
set -euo pipefail
HOST="${1:?usage: bench_32b.sh <host> [device_csv]}"
DEVS="${2:-}"
MODEL="DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
ENVV=""
[ -n "$DEVS" ] && ENVV="GGML_VULKAN_DEVICE=$DEVS"
ssh "$HOST" "cd ~/llama.cpp && $ENVV ./build/bin/llama-bench -m $MODEL -p 512 -n 128 -ngl 99"
