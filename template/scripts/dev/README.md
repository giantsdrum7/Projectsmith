# Workflow Automation Scripts

Scripts-first architecture: these PowerShell scripts are the **single source of truth** for all workflow automation. Claude Code commands (`.claude/commands/`) and Cursor commands (`.cursor/commands/`) are thin wrappers that invoke these scripts with `$ARGUMENTS` pass-through. This ensures consistent behavior regardless of which AI tool triggers the workflow.

## Standard Interface

Every script in this directory supports a common parameter contract:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-DryRun` | **Yes** (default) | Preview changes without writing anything. Safe to run at any time. |
| `-Apply` | No | Execute changes (write files, update docs). Requires explicit opt-in. |
| `-Out <dir>` | Auto-generated | Override the proof bundle output directory. |
| `-Format json\|text` | `text` | Output format. Use `json` for tooling integration, `text` for humans. |

**Exception:** `doc-sync.ps1` is always propose-only — the `-Apply` flag is accepted but reserved for future use.

## Scripts

### `repo-map.ps1` — Repository Map Generator

Generates a current-state snapshot of the repository and updates `REPO_MAP.md`.

**What it does:**
1. Runs a directory tree (excluding noise: `__pycache__`, `.git`, `node_modules`, `.venv`, `.mypy_cache`)
2. Extracts entry points from `pyproject.toml` `[project.scripts]`
3. Captures recent git activity (`git log --oneline -20`, `git diff --stat HEAD~5..HEAD`)
4. Summarizes environment modes (offline / local-live / prod) and verification commands
5. Updates only `AUTO:START` / `AUTO:END` sections in `REPO_MAP.md` — never overwrites `HUMAN` sections
6. Writes a proof bundle to `.cursor/audits/repo-map/<date>/<timestamp>/`

**Usage:**
```powershell
# Preview what would change (dry-run, default)
pwsh scripts/dev/repo-map.ps1

# Apply changes to REPO_MAP.md
pwsh scripts/dev/repo-map.ps1 -Apply

# JSON output for tooling
pwsh scripts/dev/repo-map.ps1 -Format json

# Custom output directory
pwsh scripts/dev/repo-map.ps1 -Apply -Out ./my-audit
```

---

### `eod-file-triage.ps1` — End-of-Day File Organizer

Scans for untracked or misplaced files and produces a move-plan table.

**What it does:**
1. Runs `git status --porcelain` to find untracked files
2. Classifies each file against a placement allowlist:
   - Python source (`.py`) → `src/`
   - Tests (`test_*.py`, `*_test.py`) → `tests/`
   - Documentation (`.md` in wrong location) → `docs/`
   - Scripts (`.ps1`, `.sh`) → `scripts/`
   - Config files → leave in root
3. Produces a move-plan table showing current path, suggested path, and reason
4. On `-Apply`: executes moves using `git mv` for tracked files, plain move for untracked
5. Writes a proof bundle to `.cursor/audits/eod-triage/<date>/<timestamp>/`

**Protected files** (never moved):
`CLAUDE.md`, `AGENTS.md`, `README.md`, `pyproject.toml`, `CURSOR_RULES.md`, `CODEOWNERS`, `START_HERE.md`, `REPO_MAP.md`, `copier.yaml`, `.pre-commit-config.yaml`

**Usage:**
```powershell
# Preview move plan (dry-run, default)
pwsh scripts/dev/eod-file-triage.ps1

# Execute the moves
pwsh scripts/dev/eod-file-triage.ps1 -Apply

# JSON output
pwsh scripts/dev/eod-file-triage.ps1 -Format json
```

---

### `doc-sync.ps1` — Documentation Drift Checker

End-of-day check that detects when documentation has drifted from today's code changes. **Always propose-only** — never auto-applies fixes.

**What it does:**
1. Gets today's changed `.py` files via `git log --since="1 day ago"` and `git diff`
2. Extracts public function signatures (non-underscore-prefixed `def` statements) from each changed file
3. Compares against the previous version (`HEAD`) to detect added, changed, and removed functions
4. Searches all Markdown files in `docs/` for references to each function name
5. Flags three types of drift:

| Drift Type | Priority | Trigger |
|------------|----------|---------|
| `new_undocumented` | **High** | New public function with no documentation reference |
| `signature_mismatch` | **Medium** | Function signature changed but docs still reference old version |
| `stale_reference` | **Low** | Function removed but docs still mention it |

6. Outputs a prioritized drift report with source file:line, drift type, and suggested action
7. Writes a proof bundle to `.cursor/audits/doc-check/<date>/<timestamp>/`

**Usage:**
```powershell
# Run drift check (text output, default)
pwsh scripts/dev/doc-sync.ps1

# JSON output for CI or tooling
pwsh scripts/dev/doc-sync.ps1 -Format json

# Custom proof bundle location
pwsh scripts/dev/doc-sync.ps1 -Out ./drift-audit
```

**Example output:**
```
=== Documentation Drift Report ===
Generated: 2026-02-26 17:30:00
Files scanned: 3
Drift items found: 2

--- HIGH PRIORITY (new undocumented public API) ---

  [new_undocumented] validate_config
    Source: src/{{ project_slug }}/config/runtime_config.py:15
    Signature: def validate_config(config: dict, strict: bool = False) -> bool
    Issue: New public function 'validate_config' has no documentation reference.
    Action: Add documentation for 'validate_config' in docs/reference/ or docs/architecture/.

--- LOW PRIORITY (stale references) ---

  [stale_reference] load_legacy_config
    Source: src/{{ project_slug }}/config/runtime_config.py
    Issue: Function 'load_legacy_config' was removed but is still referenced in documentation.
    Action: Remove or update stale references in documentation.
    Doc references:
      - docs/reference/ENV_VARS.md:42
```

## Proof Bundle Convention

Every script writes an audit trail (proof bundle) to a timestamped directory:

```
.cursor/audits/<action>/<date>/<timestamp>/
```

For example: `.cursor/audits/doc-check/2026-02-26/173000/`

**Standard bundle contents:**

| File | Description |
|------|-------------|
| `meta.json` | Action name, timestamp, mode, parameters, counts |
| `summary.md` | Human-readable Markdown summary of what happened |
| Action-specific | e.g., `drift-report.json`, `move-plan.json`, `repo-map-diff.txt` |

The `.cursor/audits/` directory is gitignored. Bundles are for local audit and AI context only.

## Daily Workflow

| When | Command | Purpose |
|------|---------|---------|
| **Start of day** | `pwsh scripts/dev/repo-map.ps1 -Apply` | Update `REPO_MAP.md` with current repo state |
| **During day** | Code normally | Lint feedback appears automatically if hooks are enabled |
| **Before push** | `pwsh scripts/verify.ps1` | Full verification (lint + types + tests). Do not push until `VERIFY: PASS` |
| **End of day** | `/eod` (or manually: `eod-file-triage.ps1` then `doc-sync.ps1`) | Full wrap-up: file triage, doc drift, conditional doc/lesson updates, verify |
| **After fixing a bug or improving workflow** | `pwsh scripts/dev/add-lesson.ps1 -Category <category> -Title "..."` | Log the lesson in `Lessons_Learned/` for future reference |

Quick verification (lint + types only, no tests) is available via `pwsh scripts/verify-fast.ps1`.

---

### `add-lesson.ps1` — Lessons Learned Helper

Appends a formatted lesson entry to the appropriate `Lessons_Learned/<category>.md`
file. Non-interactive; all content is passed via parameters.

**Parameters:**

| Parameter | Required | Description |
|-----------|----------|-------------|
| `-Category` | Yes | `critical`, `notable`, or `quality-of-life` |
| `-Title` | Yes | Short descriptive title |
| `-Symptom` | No | What was observed |
| `-RootCause` | No | Why it happened |
| `-Fix` | No | What resolved it |
| `-Prevention` | No | What to do next time |
| `-Links` | No | PR, issue, commit SHA, or file path |

Creates `Lessons_Learned/` and the target file if they do not exist. Never reads or
outputs environment variable values or secrets.

**Usage:**

```powershell
# Minimal entry (title only)
pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "uv sync needs --frozen in CI"

# Full entry
pwsh scripts/dev/add-lesson.ps1 `
    -Category critical `
    -Title "Gitleaks 403 on org repo PRs" `
    -Symptom "CI secret-scan failed with HTTP 403 on every PR" `
    -RootCause "gitleaks-action posts PR comments by default, requires pull-requests:write" `
    -Fix "Set GITLEAKS_ENABLE_COMMENTS=false; add pull-requests:read to job permissions" `
    -Prevention "Always set GITLEAKS_ENABLE_COMMENTS=false when adding gitleaks to workflows" `
    -Links ".github/workflows/ci.yml"
```

**Categories:**

| Category | When to use |
|----------|-------------|
| `critical` | Security exposure, production risk, CI bypass, data loss, runaway cost |
| `notable` | Bugs >30 min to diagnose, surprising API behavior, config gotchas |
| `quality-of-life` | Workflow improvements, tooling tips, friction reductions |

**Lessons Learned files:** `Lessons_Learned/critical.md`,
`Lessons_Learned/notable.md`, `Lessons_Learned/quality-of-life.md`

---

## Integration with Claude Code and Cursor

These scripts are invoked by thin command wrappers:

| Script | Claude Code command | Cursor command |
|--------|-------------------|----------------|
| `repo-map.ps1` | `.claude/commands/repo-map.md` | `.cursor/commands/repo-map.md` |
| `eod-file-triage.ps1` | `.claude/commands/eod.md` (Step 1) | `.cursor/commands/eod.md` (Step 1) |
| `doc-sync.ps1` | `.claude/commands/eod.md` (Step 2) | `.cursor/commands/eod.md` (Step 2) |
| `add-lesson.ps1` | (invoke directly) | (invoke directly) |

Each wrapper calls `pwsh scripts/dev/<script> $ARGUMENTS`, passing through any user-provided flags. The script does all the work; the wrapper provides the AI tool integration surface.

## Troubleshooting

### "Not inside a git repository"
Scripts that use `git log` or `git diff` require a git repository. Initialize one with `git init` if needed.

### "No Python files changed in the last day"
`doc-sync.ps1` only checks files changed in the last 24 hours. If you need to check older changes, modify the `--since` parameter in the script or run a manual comparison.

### PowerShell version errors
All scripts require PowerShell 7+. Check with `$PSVersionTable.PSVersion`. Install from [PowerShell GitHub releases](https://github.com/PowerShell/PowerShell/releases) if needed.

### Proof bundle directory not created
Ensure the `.cursor/` directory exists at the repo root. The scripts create subdirectories automatically, but the parent must be writable.

### Empty drift report despite known changes
- Check that changes are committed (doc-sync checks `git log --since="1 day ago"`)
- Unstaged/staged changes are also checked, but only for files matching `*.py`
- Verify the docs directory (`docs/`) exists and contains `.md` files

### Scripts run but produce no output
Ensure you are running with PowerShell 7 (`pwsh`), not Windows PowerShell 5.1 (`powershell`). The `#Requires -Version 7.0` directive enforces this.
