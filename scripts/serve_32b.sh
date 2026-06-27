#!/usr/bin/env bash
# Start the 32B llama-server on a rig.
# Usage: ./serve_32b.sh <host> [tensor_split]
#   default split is 8-way (one entry per RX 6600).
set -euo pipefail
HOST="${1:?usage: serve_32b.sh <host> [tensor_split]}"
SPLIT="${2:-1,1,1,1,1,1,1,1}"
MODEL="~/llama.cpp/DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
ssh "$HOST" "cd ~/llama.cpp && ./build/bin/llama-server \
    --model $MODEL --host 0.0.0.0 --port 8080 \
    --ctx-size 4096 --n-gpu-layers 99 --tensor-split $SPLIT"
