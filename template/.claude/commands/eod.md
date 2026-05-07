---
description: End-of-day wrap-up — file triage, doc drift check, conditional doc/lesson updates, and verify
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

Run the full end-of-day wrap-up sequence.

## Step 1 — File Triage

Run: `pwsh scripts/dev/eod-file-triage.ps1 $ARGUMENTS`

Present the move-plan table for human review. Do not auto-apply (default is `--dry-run`).
Protected files are never moved. The script never creates new folders or deletes files.

## Step 2 — Documentation Drift Check

Run: `pwsh scripts/dev/doc-sync.ps1 $ARGUMENTS`

Present the drift report. Suggest patches but do not auto-apply.

## Step 3 — EOD Documentation & Lessons Update

Follow `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` verbatim.

Review today's changes against current sprint status, open questions, risks, and lessons.
Update planning docs, root-level project docs, and lessons only if material state changes occurred.
If nothing important changed, report "No updates needed" for each doc group.
Track which files were modified (needed for Step 4).

## Step 4 — Conditional Verification

If Step 3 modified any files, run: `pwsh scripts/verify.ps1`
If no files were modified, report "Verify skipped — no changes."

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

## Step 6 — Lessons Learned Reminder

Remind the human to log any additional lessons from today's work:

> `pwsh scripts/dev/add-lesson.ps1 -Category <critical|notable|quality-of-life> -Title "Short title" -Symptom "..." -Fix "..." -Prevention "..."`

If today's work resolved a critical or recurring issue, consider promoting the lesson into the appropriate living doc. See `AGENTS.md` — Lessons Learned for categories and the promotion protocol.
