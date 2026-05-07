---
description: Update REPO_MAP.md AUTO sections with current repository state via scripts/dev/repo-map.ps1
allowed-tools: Bash, Read, Write
---

Update Repo_Map.md with current repository state.

## Instructions

1. Run the repo map script:
   `pwsh scripts/dev/repo-map.ps1 $ARGUMENTS`

2. If --dry-run (default): show the proposed changes
3. If --apply: confirm the update was written

The script updates only AUTO-marked sections in REPO_MAP.md.
HUMAN sections are never modified.

Proof bundle is written to .cursor/audits/repo-map/.
