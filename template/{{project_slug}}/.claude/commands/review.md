---
description: Review staged changes for quality, security, and convention compliance
allowed-tools: Read, Grep, Glob, Bash
---

Review staged changes for quality, security, and convention compliance.

Gather context:
!`git diff --cached --stat`
!`git diff --cached`

## Instructions

1. Analyze all staged changes (git diff --cached)
2. Check each file against the project conventions in @AGENTS.md
3. Look for: secrets/credentials, missing tests, missing type hints, bare exceptions, naming violations
4. Produce a review summary with: Files Changed, Issues Found (critical/warning/info), Verdict

If $ARGUMENTS contains a file path, focus the review on that file.
