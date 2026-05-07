---
description: Generate a structured commit or PR summary from recent git changes
---

# Change Summary

Generate a commit or PR summary from recent changes.

## Instructions

1. Gather context by running:
   - `git log --oneline -5`
   - `git diff --stat HEAD~1..HEAD`
   - `git diff HEAD~1..HEAD`

2. If `$ARGUMENTS` specifies a custom range (e.g., `HEAD~3..HEAD`), use that range instead of `HEAD~1..HEAD` for all commands above.

3. Analyze the changes and produce a structured summary:
   - **What changed**: Files and modules affected
   - **Why**: Purpose inferred from commit messages and code changes
   - **Impact**: Which systems or features are affected
   - **Testing**: Tests added or modified

4. Format the output for use in PR descriptions or commit messages. Reference `.cursor/prompts/TEMPLATE_PR_SUMMARY.md` for the canonical PR summary format.
