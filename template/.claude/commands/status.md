---
description: Summarize repository status — branch, recent commits, staged changes, last verify result
allowed-tools: Read, Bash, Grep
---

Provide a repository status summary.

Gather context:
!`git status`
!`git log --oneline -10`
!`git diff --stat`

## Instructions

Summarize:
1. Current branch and recent commits
2. Staged, unstaged, and untracked changes
3. Last verification result (read .cursor/last-verify-failure.txt if it exists)
4. Any open TODOs or FIXMEs in recently changed files

Format as a concise status report.
