---
description: Generates and updates REPO_MAP.md with current repository state
disable-model-invocation: true
allowed-tools: [Bash, Read, Write]
argument-hint: "[--dry-run | --apply] [--format json|text]"
---

# Repo Map Generator Skill

## Purpose
Update REPO_MAP.md with the current directory tree, entry points, git activity, and verification status. Only AUTO-marked sections are updated; HUMAN sections are preserved.

## Usage
This skill is manual-invocation only (disable-model-invocation: true).
Invoke via /repo-map command.

## Implementation
Delegates to scripts/dev/repo-map.ps1 which:
1. Builds tree from git-tracked files (automatically respects .gitignore)
2. Extracts entry points from pyproject.toml [project.scripts]
3. Captures recent git activity (git log --oneline -20, git diff --stat HEAD~5..HEAD)
4. Updates content inside <!-- AUTO:START --> / <!-- AUTO:END --> markers
5. Writes proof bundle to .cursor/audits/repo-map/

## Arguments
- --dry-run (default): Preview changes without writing
- --apply: Write changes to REPO_MAP.md
- --format json|text: Output format (default: text)
- --out <dir>: Custom proof bundle output directory
