# Distributing Across Rigs (llama.cpp RPC)

Status: **researched, not yet built.** This captures what was verified before
spending money, so the prototype starts from facts rather than assumptions.

## What's confirmed possible

- **Mixed backends work over RPC.** A CUDA host paired with a ROCm/HIP worker
  has been tested working by others, so Zeus (CUDA, dual 3080 Ti) can join the
  AMD rigs (ROCm/Vulkan) in one pool. ~216 GB aggregate across all 26 GPUs.
- **AMD Vulkan clusters run large models** (70B-class confirmed on old Radeon
  clusters), so the RX 6600 side is sound.
- A single controller runs `rpc-server` on each remote GPU host and connects via
  `--rpc host1:port,host2:port,...`.

## The hard truth about speed (this is the deciding factor)

Distributing is a **capacity** play, not a speed play. For a single chat stream,
tokens pass through layers sequentially, so only one node works at a time —
adding GPUs gives room, not throughput.

Measured reality for our exact target model (Qwen3-235B) on a 4-node cluster:

| Transport | 1 node | 4 nodes |
|-----------|--------|---------|
| RDMA (Exo) | 19.5 t/s | 31.9 t/s (scales up) |
| **Plain TCP/IP (llama.cpp RPC)** | 20.4 t/s | **15.2 t/s (scales DOWN)** |

Over ordinary Ethernet, llama.cpp RPC got *slower* with more nodes. The good
scaling needed **RDMA**, which requires Mellanox/ConnectX NICs — **not** the
$16 RTL8125B 2.5G cards. Those do TCP only.

**Conclusion:** the cluster's value for us is making a 235B model *runnable at
all* (no single box can hold it), at modest single-digit/low-teens t/s — not
fast, just possible. The 2.5G upgrade lifts us off the 1 GbE floor but will not
buy linear scaling.

## Verified gotchas (handle before building)

- **Vulkan + RPC has a known bug**: Vulkan lacks fused RMS-norm / mul-unary ops
  that RPC needs. For rigs in a cluster, prefer the **ROCm/HIP** build over the
  usual Vulkan one. Test, don't assume.
- **Row-split does not work with RPC.** Layer/pipeline split only (which is what
  we want for a slow link anyway).
- **Each worker needs `--mem`** set for its available GPU memory.
- **Keep RPC on the LAN.** The port is unauthenticated.
- **Git commit must match across all nodes** — the RPC protocol version-checks
  and mismatches crash at load.

## Hardware facts that shape the plan

- Rigs: Biostar TB360-BTC Pro 2.0, single onboard **1 GbE** NIC, **8 GB system
  RAM** each. 8 GB RAM rules out CPU/MoE-offload on the rigs — everything must
  live in GPU VRAM there.
- Rigs have open PCIe x1 slots (8 of 12 used for GPUs), so a 2.5G NIC can drop in
  later if the cluster proves worth upgrading.
- Zeus: 64 GB RAM, real PCIe lanes, CUDA — best controller, and viable as a
  standalone 235B box (see ZEUS_235B.md).

## Zero-dollar prototype (do before buying anything)

1. Build llama.cpp with `-DGGML_RPC=ON` (HIP on a clone rig, CUDA on Zeus).
   Build in a fresh `build-rpc` dir; never touch rrig6600b packages.
2. Bring up `rpc-server` on **one clone rig**, controller on Zeus, over existing
   **1 GbE**. Confirm the mixed CUDA+ROCm pool actually loads and runs a model
   in our environment — proving past the Vulkan/HIP and fused-op gotchas.
3. Only if that works and the speed is worth it: buy 3× RTL8125B x1 NICs + a
   2.5G switch (~$100) to raise the floor.

## Candidate models (need >64 GB, so cluster-only)

- **Qwen3-235B-A22B** (235B total / ~22B active) — primary MoE target.
- **gpt-oss 120B** — efficient MoE, good first proof before 235B.
- Mixtral 8x22B (~141B) — older, forgiving, lighter on the pool.
