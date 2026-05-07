---
description: Review staged or unstaged changes for quality, security, and convention compliance
---

# Code Review

Review current changes using the canonical review checklist.

## Instructions

1. Gather context by running:
   - `git diff --cached --stat` (staged changes)
   - `git diff --cached` (staged diff)
   - If nothing is staged, fall back to `git diff` (unstaged changes)

2. Apply the **canonical review checklist** at `.agent-config/checklists/code-review.md`
3. Check all changes against project conventions in `AGENTS.md`
4. Produce a review summary:
   - **Files changed**: list with brief description
   - **Issues found**: grouped by severity (critical / warning / info)
   - **Verdict**: Approve, Request Changes, or Needs Discussion

If `$ARGUMENTS` contains a file path, focus the review on that file.
