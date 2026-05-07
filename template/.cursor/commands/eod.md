---
description: End-of-day wrap-up — file triage, doc drift check, conditional doc/lesson updates, and verify
---

# End-of-Day Wrap-Up

## Step 1 — File Triage

`pwsh scripts/dev/eod-file-triage.ps1 $ARGUMENTS`

Present the move-plan table for human review. Do not auto-apply moves.
Default: `--dry-run`. Protected files are never moved.

## Step 2 — Documentation Drift Check

`pwsh scripts/dev/doc-sync.ps1 $ARGUMENTS`

Present the drift report. Suggest patches but do not auto-apply.

## Step 3 — EOD Documentation & Lessons Update

Follow `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` verbatim.
Update planning docs and project docs only if material state changes occurred.
If nothing changed, report "No updates needed" for each doc group.
Track which files were modified (needed for Step 4).

## Step 4 — Conditional Verification

If Step 3 modified any files: `pwsh scripts/verify.ps1`
If no files were modified: report "No files changed — verify skipped."

## Step 5 — Summary

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

Consider whether today's work produced lessons worth capturing:

`pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..." -Prevention "..."`

See `AGENTS.md` — Lessons Learned for categories and the promotion protocol.
