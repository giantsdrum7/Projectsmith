---
description: >
  USE WHEN checking documentation drift, verifying docs match code,
  auditing doc freshness, or detecting undocumented public functions.
  Activates on: doc drift, documentation check, doc sync, stale docs, undocumented API, signature mismatch.
allowed-tools: [Bash, Read, Grep, Glob]
---

# Documentation Sync Skill

## Purpose
Detect documentation drift by comparing code changes against existing documentation. Identifies signature mismatches, undocumented public functions, and removed functions still referenced in docs.

## When to Use
- After making code changes that affect public APIs
- During end-of-day wrap-up (invoked as part of `/eod`)
- When auditing whether docs are current with the codebase
- Before releasing or merging significant changes

## Workflow
1. Delegate to the deterministic backing script:
   `pwsh scripts/dev/doc-sync.ps1 $ARGUMENTS`
2. The script identifies today's changed `.py` files and compares function signatures against docs
3. Review the drift report for:
   - Signature mismatches between code and docs
   - New undocumented public functions
   - Removed functions still referenced in docs
4. Present the prioritized drift report with file:line proof pointers
5. Suggest patches but **never auto-apply** — propose-only by default

## Arguments
- `--dry-run` (default): Preview drift report without changes
- `--apply`: Apply suggested documentation patches (requires confirmation)
- `--format json|text`: Output format (default: text)
- `--out <dir>`: Custom proof bundle output directory

## References
- Backing script: `scripts/dev/doc-sync.ps1`
- Proof bundles: `.cursor/audits/doc-check/`
- Living docs convention: `AGENTS.md` — Living Docs Maintenance
