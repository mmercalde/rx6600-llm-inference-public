#!/usr/bin/env bash
# Confirm Vulkan vs ROCm device counts on a rig.
# Usage: ./device_check.sh <host>   e.g. ./device_check.sh rrig6600c
set -euo pipefail
HOST="${1:?usage: device_check.sh <host>}"
echo "== $HOST =="
echo -n "ROCm devices (expect 8): "
ssh "$HOST" "rocm-smi 2>/dev/null | grep -c '0x73ff'"
echo -n "Vulkan discrete GPUs (expect 8): "
ssh "$HOST" "vulkaninfo --summary 2>/dev/null | grep -c PHYSICAL_DEVICE_TYPE_DISCRETE_GPU"
