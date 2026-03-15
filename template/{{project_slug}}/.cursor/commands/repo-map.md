---
description: Update Repo_Map.md with current repository state
---

# Repo Map Update

Running repository map generator...

Run the script:
`pwsh scripts/dev/repo-map.ps1 $ARGUMENTS`

This command updates REPO_MAP.md by:
1. Building the directory tree from git-tracked files (respects .gitignore)
2. Extracting entry points from pyproject.toml
3. Capturing recent git activity
4. Updating only AUTO-marked sections (never HUMAN sections)

Default: --dry-run (preview changes)
Use --apply to write changes
