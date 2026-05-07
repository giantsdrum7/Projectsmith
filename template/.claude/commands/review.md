---
description: Review staged changes for quality, security, and convention compliance
allowed-tools: Read, Grep, Glob, Bash
---

Review staged changes using the canonical review checklist.

Gather context:
!`git diff --cached --stat`
!`git diff --cached`

## Instructions

1. Gather the diff (staged preferred; fall back to unstaged if nothing staged)
2. Apply the **canonical review checklist** at `.agent-config/checklists/code-review.md`
3. Check all changes against project conventions in @AGENTS.md
4. Produce a review summary:
   - **Files changed**: list with brief description
   - **Issues found**: grouped by severity (critical / warning / info)
   - **Verdict**: Approve, Request Changes, or Needs Discussion

If `$ARGUMENTS` contains a file path, focus the review on that file.
