#!/usr/bin/env bash
# Download (if needed) and serve a 70B Q4 on a rig.
# Usage: ./serve_70b.sh <host> [tensor_split]
set -euo pipefail
HOST="${1:?usage: serve_70b.sh <host> [tensor_split]}"
SPLIT="${2:-1,1,1,1,1,1,1,1}"
MODEL="DeepSeek-R1-Distill-Llama-70B-Q4_K_M.gguf"
REPO="bartowski/DeepSeek-R1-Distill-Llama-70B-GGUF"
ssh "$HOST" "cd ~/llama.cpp && \
    ([ -f $MODEL ] || huggingface-cli download $REPO $MODEL --local-dir ./) && \
    ./build/bin/llama-server --model $MODEL --host 0.0.0.0 --port 8080 \
        --ctx-size 4096 --n-gpu-layers 99 --tensor-split $SPLIT"
