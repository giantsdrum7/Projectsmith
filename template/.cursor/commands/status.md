---
description: Repository status summary — branch, recent commits, staged changes, last verify result
---

# Repository Status

Summarize the current state of the repository.

## Instructions

1. Gather context by running:
   - `git status`
   - `git log --oneline -10`
   - `git diff --stat`

2. Summarize:
   - Current branch and recent commits
   - Staged, unstaged, and untracked changes
   - Last verification result (read `.cursor/last-verify-failure.txt` if it exists)
   - Any open TODOs or FIXMEs in recently changed files

3. Format as a concise status report.
