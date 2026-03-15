---
description: Review staged or unstaged changes for quality, security, and convention compliance
---

# Code Review

Review current changes for quality, security, and convention compliance.

## Instructions

1. Gather context by running:
   - `git diff --cached --stat` (staged changes)
   - `git diff --cached` (staged diff)
   - If nothing is staged, fall back to `git diff` (unstaged changes)

2. Analyze all changes against project conventions in `AGENTS.md`:
   - **Security**: No secrets, tokens, or credentials in code
   - **Tests**: New code has corresponding tests
   - **Type hints**: All function signatures have type hints
   - **Error handling**: No bare `except:`, custom exceptions for domain errors
   - **Naming**: snake_case functions, PascalCase classes, UPPER_SNAKE_CASE constants
   - **Imports**: stdlib, then third-party, then local; no wildcards
   - **Documentation**: Public functions have Google-style docstrings

3. Produce a review summary:
   - **Files changed**: List with brief description
   - **Issues found**: Grouped by severity (critical / warning / info)
   - **Verdict**: Approve, Request Changes, or Needs Discussion

If `$ARGUMENTS` contains a file path, focus the review on that file.
