---
description: >
  USE WHEN reviewing code, checking pull requests, auditing staged changes,
  verifying quality standards, or evaluating diffs for security and convention compliance.
  Activates on: review, PR, diff, quality check, code audit, staged changes, convention compliance.
allowed-tools: [Read, Grep, Glob, Bash]
---

# Code Review Skill

## Purpose
Review code changes for quality, security, and convention compliance using the project's canonical review checklist. This skill provides contextual judgment about code quality rather than just running lint tools.

## When to Use
- Reviewing staged or unstaged changes before commit
- Evaluating pull request diffs
- Auditing code for security issues, missing tests, or convention violations
- Checking whether changes align with project architecture and standards

## Workflow
1. Gather the diff (staged preferred; fall back to unstaged if nothing staged)
2. Apply the **canonical review checklist** at `.agent-config/checklists/code-review.md`
3. Cross-reference changes against project conventions in `AGENTS.md`
4. Check for security issues: secrets, credentials, unvalidated input, excessive permissions
5. Verify test coverage: new code has tests, edge cases are handled
6. Assess architecture: correct layer, no coupling violations, file size reasonable
7. Produce a structured review summary

## Output Format
- **Files changed**: list with per-file summary
- **Issues found**: grouped by severity (critical / warning / info)
- **Verdict**: Approve, Request Changes, or Needs Discussion

## References
- Canonical checklist: `.agent-config/checklists/code-review.md`
- Project conventions: `AGENTS.md` Part 1
- Role definition: `.cursor/roles/REVIEWER.md`
