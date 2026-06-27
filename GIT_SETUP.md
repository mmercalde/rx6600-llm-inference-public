# Pushing this repo (dual-remote)

Per standing rules: two remotes, origin (private) + public (mirror), dual-push.
Do this from SER8 or Zeus — not from a Claude sandbox.

## First-time setup
1. Create two empty repos on GitHub (private "origin" and the public mirror).
2. In this folder:
   - git init
   - git add -A
   - git commit -m "Initial: RX 6600 LLM inference project + distributed research"
   - git branch -M main
   - git remote add origin   <PRIVATE_REPO_URL>
   - git remote set-url --add --push origin <PRIVATE_REPO_URL>
   - git remote set-url --add --push origin <PUBLIC_REPO_URL>
   - git push -u origin main

After that, a single `git push` writes to both remotes (dual-push enforced).

## Verify dual-push is set
   git remote -v
You should see the private URL for fetch, and BOTH URLs listed for push.
