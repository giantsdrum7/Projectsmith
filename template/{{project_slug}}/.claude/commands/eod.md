---
description: End-of-day wrap-up — file triage, doc drift check, conditional doc/lesson updates, and verify
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

Run the full end-of-day wrap-up sequence.

## Instructions

### Step 1 — File Triage

1. Run: `pwsh scripts/dev/eod-file-triage.ps1 $ARGUMENTS`
2. Present the move-plan table for human review.
3. Do not auto-apply moves (default is `--dry-run`).

Protected files (CLAUDE.md, AGENTS.md, README.md, pyproject.toml, root config files) are never moved.
The script never creates new folders and never deletes files.
Proof bundle is written to `.cursor/audits/eod-triage/`.

### Step 2 — Documentation Drift Check

1. Run: `pwsh scripts/dev/doc-sync.ps1 $ARGUMENTS`
2. Present the drift report (signature mismatches, undocumented functions, stale references).
3. Suggest patches but do not auto-apply.

Proof bundle is written to `.cursor/audits/doc-check/`.

### Step 3 — EOD Documentation & Lessons Update

Follow `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` verbatim.

1. Review today's changes (`git diff --stat HEAD~5` or similar) against current sprint status, open questions, risks, and lessons.
2. Conditionally update planning & lessons docs:
   - `docs/planning/ACTIVE_SPRINT.md` — only if a milestone completed, blocker removed, new work started, or phase status changed.
   - `docs/planning/OpenQuestions_Risks.md` — only if a question resolved, risk changed state, or new risk appeared.
   - `Lessons_Learned/{critical,notable,quality-of-life}.md` — only for non-trivial issues or workflow discoveries.
3. Conditionally update root-level project docs:
   - `README.md` — only if a factual stat is stale (test count, phase status, eval metrics, new infra) or a capability was added/removed.
   - `START_HERE.md` — only if setup prerequisites changed, a new workflow step was added, or the reading order needs a new entry.
   - `docs/architecture/ARCHITECTURE.md` — only if a component's implementation status changed (new component wired, stub replaced, architecture decision made). Update the "AS OF" table when making changes.
4. If nothing important changed, report "No updates needed" for each doc group.
5. Preserve formatting, IDs, legend structure. Do not invent status values.
6. Keep entries factual; cite file paths, diffs, or error messages as evidence.

Track which files were modified.

### Step 4 — Conditional Verification

If Step 3 modified any files, run: `pwsh scripts/verify.ps1`
If no files were modified, report "Verify skipped — no changes."

### Step 5 — Summary

Report in this format:

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

### Step 6 — Lessons Learned Reminder

After the wrap-up, remind the human to log any lessons from today's work beyond
what Step 3 already handled:

> Did you fix a bug, resolve a workflow issue, or discover a non-obvious behavior today?
> If yes, log it:
>
> `pwsh scripts/dev/add-lesson.ps1 -Category <critical|notable|quality-of-life> -Title "Short title" -Symptom "..." -Fix "..." -Prevention "..."`
>
> See `Lessons_Learned/` for the three category files and their entry templates.

If today's work resolved a critical or recurring issue, also consider promoting the lesson into the appropriate living doc (start_up_guide.md / start_up_prompt.md / continue.md). See continue.md section 6.7 for the promotion protocol.
