---
description: >
  USE WHEN performing a broad quality pass, checking for code smells,
  finding dead code, identifying missing tests, or auditing convention compliance.
  Activates on: quality sweep, code smell, dead code, missing tests, convention audit, tech debt, cleanup.
allowed-tools: [Read, Grep, Glob, Bash]
---

# Quality Sweep Skill

## Purpose
Perform a broad quality pass across the codebase or a specified scope. Identifies code smells, missing tests, dead code, convention violations, and other quality concerns that targeted reviews might miss.

## When to Use
- Periodic quality audits of the codebase
- Before major releases or milestones
- After a series of rapid changes to catch accumulated issues
- When onboarding to an unfamiliar area of the codebase

## Workflow
1. Determine scope: full repo, specific directory, or recent changes
2. Run automated checks:
   - `pwsh scripts/verify-fast.ps1` for lint and type-check baseline
   - Grep for common smells: bare `except:`, `TODO`/`FIXME` without issue links, `type: ignore` without explanation
3. Scan for structural concerns:
   - Files exceeding 300 lines
   - Functions exceeding 50 lines or high cyclomatic complexity
   - Modules with excessive imports (coupling indicator)
   - Dead imports or unreachable code paths
4. Check test coverage gaps:
   - Source files without corresponding test files
   - Public functions without test coverage
   - Missing edge case / error path tests
5. Verify convention compliance against `AGENTS.md`:
   - Naming conventions (snake_case, PascalCase, UPPER_SNAKE_CASE)
   - Docstring presence on public functions (Google style)
   - Type hints on all function signatures
6. Produce a prioritized findings report

## Output Format
```
=== Quality Sweep ===
Scope:     <directory or "full repo">
Lint:      <N issues>
Smells:    <list with file:line>
Coverage:  <files without tests>
Structure: <oversized files/functions>
Conventions: <violations>
Priority:  <top 3 recommended actions>
```

## References
- Project conventions: `AGENTS.md` Part 1
- Coding standards: `.cursor/rules/core.mdc`
- Test conventions: `.cursor/rules/testing.mdc`
