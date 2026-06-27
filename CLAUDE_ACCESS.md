# How Claude Reads This Repo

A note for any future Claude chat working on this project. Reading this repo
live is possible, but only under a specific recipe — these constraints are real,
not optional.

## The working recipe

1. **The repo must be PUBLIC.** Claude cannot access the private repo at all
   (no credentials, and private repos are not web-readable). Only the public
   mirror (`rx6600-llm-inference-public`) is reachable.

2. **Use the RAW domain, not github.com.** The browser URL
   (`https://github.com/...`) is blocked by GitHub's robots rule
   (`ROBOTS_DISALLOWED`). The readable form is:
   `https://raw.githubusercontent.com/mmercalde/rx6600-llm-inference-public/main/<path>`

3. **The user must paste the raw link into chat.** Claude's fetch tool can only
   open a URL that has appeared in the conversation (or in a prior search
   result). Claude cannot type a URL on its own or browse the repo. Each file is
   a separate link.

To convert a normal GitHub file URL to a raw one: change `github.com` →
`raw.githubusercontent.com` and delete `/blob`.

Example (this file):
`https://raw.githubusercontent.com/mmercalde/rx6600-llm-inference-public/main/CLAUDE_ACCESS.md`

## What this enables / what it doesn't

- **Reading: yes** — paste a raw link, Claude reads that file live. Good for
  picking up context in a new chat, reviewing current doc state, etc.
- **Discovery: no** — Claude reads only the file you paste; it can't list or
  browse other files on its own. Want three files seen? Paste three raw links.
- **Writing: no** — Claude cannot commit or push. Edits come back as files to
  download, or are made by a local agent on the user's machine.

## File map (paste any of these as raw links)

- `README.md` — overview
- `CLAUDE_PROJECT_INSTRUCTIONS.md` — project context + rules
- `docs/RUNBOOK.md` — operating procedures
- `docs/BENCHMARKS.md` — recorded results
- `docs/DISTRIBUTED.md` — RPC cluster research
- `docs/ZEUS_235B.md` — Zeus-solo 235B + XMP fix
- `docs/MODELS.md` — model picks + agentic setup
- `configs/models.md` — model paths / VRAM math

## Note on the public mirror

This public repo is a SCRUBBED, point-in-time copy: real IPs are replaced with
placeholders (`<RIG_A_IP>` etc.). The private repo holds the real values. When
the private repo changes, this mirror does not auto-update — it must be
re-scrubbed and pushed.
