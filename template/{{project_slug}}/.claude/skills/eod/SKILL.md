---
description: >
  USE WHEN performing end-of-day wrap-up, running file triage,
  checking doc drift, updating planning docs, or closing out a work session.
  Activates on: end of day, EOD, wrap-up, session close, daily workflow, file triage, doc drift.
allowed-tools: [Bash, Read, Write, Edit, Grep, Glob]
---

# End-of-Day Wrap-Up Skill

## Purpose
Orchestrate the end-of-day workflow: file triage, documentation drift check, conditional planning/lesson updates, and verification. Ensures nothing is left in an inconsistent state before ending a work session.

## When to Use
- At the end of a development session
- Before handing off work to another contributor
- When the `/eod` command is invoked
- After completing a significant body of work

## Workflow

### Step 1 — File Triage
Run: `pwsh scripts/dev/eod-file-triage.ps1 --dry-run`
- Scans for untracked or misplaced files
- Produces a move-plan table for human review
- Protected files are never moved; no folders created; no files deleted
- Present results and wait for human decision before applying

### Step 2 — Documentation Drift Check
Run: `pwsh scripts/dev/doc-sync.ps1 --dry-run`
- Compares today's code changes against existing documentation
- Flags signature mismatches, undocumented functions, stale references
- Propose-only — never auto-applies patches

### Step 3 — Conditional Documentation & Lessons Update
Follow `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` verbatim.
- Review today's changes against sprint status, open questions, risks, and lessons
- Update planning docs and project docs only if material state changes occurred
- If nothing changed, report "No updates needed" for each doc group
- Track which files were modified (needed for Step 4)

### Step 4 — Conditional Verification
- If Step 3 modified any files: run `pwsh scripts/verify.ps1`
- If no files were modified: report "Verify skipped — no changes"

### Step 5 — Summary
Report using the standard EOD summary format (see `/eod` command).

### Step 6 — Lessons Learned Reminder
Remind about `scripts/dev/add-lesson.ps1` for any notable findings.
See `AGENTS.md` — Lessons Learned for the promotion protocol.

## References
- File triage script: `scripts/dev/eod-file-triage.ps1`
- Doc sync script: `scripts/dev/doc-sync.ps1`
- EOD doc update template: `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md`
- Lessons system: `Lessons_Learned/` and `AGENTS.md`
