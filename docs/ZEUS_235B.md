# Zeus Solo — 235B via MoE CPU-Offload (Path A)

Status: **not yet tested.** This is the zero-dollar alternative to the RPC
cluster. Run it first; it may make the cluster unnecessary.

## The idea

Qwen3-235B is a mixture-of-experts model: ~22B of 235B params fire per token.
With `-ot ".ffn_.*_exps.=CPU"`, the MoE expert layers live in **system RAM**
while attention/non-MoE layers stay on the GPUs. Zeus has 64 GB RAM + 24 GB VRAM
= ~88 GB combined, enough to hold a small-quant (Q2-ish, ~80–88 GB) 235B.

No cluster, no NICs, no network bottleneck.

## Expected speed (estimate, unverified)

Bottleneck = DDR4 bandwidth, since experts are read from RAM each token.

- ~22B active params at Q2 ≈ ~6–7 GB read per token.
- Quad-channel DDR4-2666 ≈ ~68 GB/s → rough estimate **~5–8 t/s**.
- After XMP to 3200 (~82 GB/s) → roughly **+20%**.

Usable for considered Q&A, too slow for fast back-and-forth. A 32B Q4 at ~31 t/s
on Zeus may feel better for everyday work; the 235B earns its keep only on hard
reasoning. **The free test replaces this estimate with a real number.**

## Free win first: enable XMP

`dmidecode -t memory` readout (2026-06-25):

- 4× Corsair 16 GB in DIMM_A1/B1/C1/D1 → **quad-channel, already optimal.**
- Part number **CMK32GX4M2B3200C16** = rated **DDR4-3200**.
- Configured Memory Speed: **2666 MT/s** → running at JEDEC default, **XMP is
  off.** Leaving ~20% bandwidth on the table.

Fix (BIOS, needs a reboot — not doable over SSH):
1. Enter SAGE UEFI, enable **XMP**, select the 3200 profile.
2. XMP sets speed + timings (~16-18-18) + ~1.35 V automatically (currently 1.2 V
   at 2666).
3. Save, reboot, re-run `dmidecode -t memory` — expect Configured = 3200.

Caveat: X299 with all 4 channels populated sometimes won't hold full 3200; if
unstable, 3000 is still a clear win over 2666. Flip XMP **before** benchmarking
the model, or the result is handicapped.

## Test steps (Path A)

1. Enable XMP, confirm 3200 (or best stable) via dmidecode.
2. Build llama.cpp on Zeus with CUDA.
3. Grab a small-quant Qwen3-235B GGUF (UD-Q2_K_XL or similar).
4. Run with all non-MoE layers on GPU and experts offloaded:
   `-ngl 99 -ot ".ffn_.*_exps.=CPU" -c 16384`.
5. Record real t/s in BENCHMARKS.md.

## Decision gate

- If Zeus-solo runs 235B at a livable speed → may not need the cluster or NICs.
- If it runs but the quant's too small / too slow → the RPC cluster earns its
  place by holding a larger/better quant across the VRAM pool (see
  DISTRIBUTED.md).
