---
description: Generate a structured commit or PR summary from recent git changes
allowed-tools: Bash, Read, Grep
---

Generate a commit or PR summary from recent changes.

Gather context:
!`git log --oneline -5`
!`git diff --stat HEAD~1..HEAD`
!`git diff HEAD~1..HEAD`

## Instructions

1. Analyze the recent changes (git diff)
2. Generate a structured summary:
   - **What changed**: List of files and modules affected
   - **Why**: Infer the purpose from commit messages and code changes
   - **Impact**: Which systems/features are affected
   - **Testing**: What tests were added or modified

If $ARGUMENTS specifies a range (e.g., "HEAD~3..HEAD"), use that range instead.

Format for use in PR descriptions or commit messages.
