# Model Selection & Agentic Setup

Status: **research/decision doc.** Consolidates the model-choice analysis for the
two hardware paths. Requirements throughout: large context, coding, math, and
agentic ability (drive tools, edit files, push to GitHub).

## The governing constraint

On the cluster, speed is set by a model's **active parameters per token** (they
cross the 1 GbE network each token), and fit is set by **total parameters**.
MoE models win: high total (capability, fills the pool) + low active (stays
fast). On Zeus, the limit is 24 GB VRAM + 64 GB RAM, so low-active MoE models
that spill experts to RAM run well.

Reality check on both paths: any model is run **quantized (~Q4)** to fit, which
degrades quality below the headline benchmark numbers (those are for full
weights). Plan accordingly.

## Path 1 — Zeus alone (FAST box)

2x 3080 Ti, 24 GB VRAM + 64 GB RAM. Best for models that fit in 24 GB or MoE
with tiny active counts. Tens of t/s — the daily driver.

| Model | Why | Speed |
|-------|-----|-------|
| **Qwen3-Coder-Next (80B/3B active)** | Coding-agent specialist, 256K ctx, recovers from tool failures. **Top pick.** | fast (3B active) |
| Qwen3.6-27B / Qwen3.5-35B-A3B | Strong coding+math, fit comfortably | 50-100+ t/s |
| Qwen3-235B via RAM offload | Possible (experts in 64 GB RAM) but not worth it | ~5-8 t/s |

Free win first: enable XMP on Zeus (RAM runs 2666, rated 3200) — see ZEUS_235B.md.

## Path 2 — 26-GPU cluster (CAPACITY box)

24x RX 6600 + Zeus, ~216 GB pooled. Holds models too big for any single machine.
Does NOT add speed — ~5-8 t/s best case over 1 GbE, lower in practice. NICs don't
fix this without RDMA, which the x1 mining slots can't run. See DISTRIBUTED.md.

| Model | Total / Active | Fit | Note |
|-------|----------------|-----|------|
| **GLM-4.6 / 4.7** | ~355B / ~32B | ~130 GB | Best coding + 200K ctx. Capability ceiling, slow. |
| DeepSeek V4 | 671B / 37B | ~136 GB | Top agentic/SWE, 1M ctx. Most capable, slowest. |
| **Qwen3-235B-A22B** | 235B / 22B | ~132 GB | Speed/capability sweet spot; leads on math. |

## Picks by priority

- **Large context:** Llama 4 Scout (10M) / DeepSeek V4 (1M) > GLM (200K).
- **Coding:** GLM-4.6/4.7 (benchmark leader) or Qwen3-Coder-Next (fast, agentic).
- **Math:** Qwen3-235B-A22B (leads GPQA/AIME among the giants).
- **Agentic:** Qwen3-Coder-Next (fast loop) or GLM-4.6/DeepSeek V4 (max autonomy,
  slow).

## Agentic setup — the model is only half

A GGUF in llama.cpp just generates text. To actually edit files / run commands /
push to GitHub, pair it with an agent harness pointed at the local endpoint:

- **Aider** — purpose-built "edit repo + git commit". Lightest; closest match to
  "update my GitHub."
- **OpenHands / Cline** — fuller agents that run shell commands and iterate on
  errors. More capable, more setup.

## Safe agent workflow (do this)

Git history IS the undo system — file edits are recoverable by resetting to the
last good commit. The real risks are things that destroy history or reach outside
the repo: `git push --force`, stray `rm -rf`, committing secrets. Defenses:

1. Point the agent at a **separate working clone**, never the main folder. You
   review, then you push.
2. **Branch isolation** — agent works only on a throwaway branch; main stays
   clean; merge after review.
3. **Watch the first runs.** Keep Aider's per-change confirmation on; don't run
   full-auto unattended.

(Private/public repo split alone does NOT defend against force-push or stray rm —
the clone + branch + review loop is the real net.)

## How close to Claude?

- Well-scoped coding ("write this function / fix this bug"): **close** — usable,
  occasionally you'd notice a difference.
- Autonomous multi-step agentic ("figure out what's broken, fix across files,
  test, push"): **still a step behind** — more supervision needed, flakier mid-
  loop, and the ~Q4 quant tax widens the gap.
- Net: great for **supervised** local coding; keep a hand on the wheel for
  unattended "go push to GitHub."

## Bottom line

- Fast + agentic, today, no new hardware → **Zeus + Qwen3-Coder-Next 80B** (daily
  driver).
- Biggest/smartest the hardware can hold, accept slow → **cluster + GLM-4.6 or
  DeepSeek V4** (occasional hard-problem tool).
