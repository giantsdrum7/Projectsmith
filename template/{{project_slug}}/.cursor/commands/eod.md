---
description: End-of-day wrap-up — file triage, doc drift check, conditional doc/lesson updates, and verify
---

# End-of-Day Wrap-Up

Running full end-of-day sequence...

## Step 1 — File Triage

Scan for misplaced or untracked files.

`pwsh scripts/dev/eod-file-triage.ps1 $ARGUMENTS`

This scans for untracked or misplaced files and suggests moves:
- Python source → src/
- Tests → tests/
- Docs → docs/
- Scripts → scripts/
- Config → leave in root

Default: --dry-run (preview moves)
Use --apply to execute moves (with confirmation).
Protected files are never moved.

Present the move-plan table for human review. Do not auto-apply moves.

## Step 2 — Documentation Drift Check

Check for documentation that drifted from today's code changes.

`pwsh scripts/dev/doc-sync.ps1 $ARGUMENTS`

This checks for:
- Signature mismatches between code and docs
- New undocumented public functions
- Removed functions still referenced in docs

Default: propose-only (never auto-applies).
Present the drift report. Suggest patches but do not auto-apply.

## Step 3 — EOD Documentation & Lessons Update

Review today's changes and conditionally update project-tracking docs. Follow the instructions in `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` verbatim.

Scope of files to review and potentially update:

**Planning & Lessons:**
- `docs/planning/ACTIVE_SPRINT.md`
- `docs/planning/OpenQuestions_Risks.md`
- `Lessons_Learned/critical.md`
- `Lessons_Learned/notable.md`
- `Lessons_Learned/quality-of-life.md`

**Root-level project docs:**
- `README.md` — test counts, phase status, eval metrics, architecture diagram, roadmap
- `START_HERE.md` — setup steps, prerequisites, workflow summary
- `docs/architecture/ARCHITECTURE.md` — as-built component status, evidence inventory

**Rules:**
- Only update a file if there was a material state change today (milestone completed, blocker removed, risk resolved/discovered, non-trivial lesson, stale factual stat, new capability).
- For root-level docs: update only if a factual stat is stale (test count, phase status, eval metrics, new infra) or a capability was added/removed. Do not rewrite prose for style.
- If nothing changed, report "No updates needed" for each doc group.
- Preserve existing formatting, IDs, legend structure, and status values.
- Keep entries factual and grounded in evidence from the repo (cite file paths, diffs, errors).

Track which files were modified (needed for Step 4).

## Step 4 — Conditional Verification

Run verification **only if** Step 3 modified any files:

`pwsh scripts/verify.ps1`

If no files were modified, skip verification and report "No files changed — verify skipped."

## Step 5 — Summary

Report a concise summary in this format:

```
=== EOD Summary ===
File triage:          <N candidates / clean>
Doc drift:            <N items / clean>
ACTIVE_SPRINT:        updated / no update needed
OpenQuestions_Risks:   updated / no update needed
Lessons Learned:       updated / no update needed
README.md:            updated / no update needed
START_HERE.md:        updated / no update needed
Architecture Report:  updated / no update needed
Verify:               PASS / FAIL / skipped (no changes)

Edits made:
  <bullet list, or "None">

Evidence:
  <bullet list of diffs/observations used>
```

## Lessons Learned Reminder

After the wrap-up, consider whether today's work produced any lessons worth capturing
beyond what Step 3 already handled:

```
pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..." -Prevention "..."
```

Categories: `critical` (security/production risk), `notable` (non-trivial bug or surprise), `quality-of-life` (workflow improvement).
See `Lessons_Learned/` at repo root.
