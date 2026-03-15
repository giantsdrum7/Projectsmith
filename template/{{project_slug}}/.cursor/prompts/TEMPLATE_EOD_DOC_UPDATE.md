# EOD Documentation & Lessons Update

Review today's changes and update project-tracking docs only if there was a material state change.

## Scope

### Planning & Lessons (update for milestone/risk/lesson changes)

- `docs/planning/ACTIVE_SPRINT.md`
- `docs/planning/OpenQuestions_Risks.md`
- `Lessons_Learned/critical.md`
- `Lessons_Learned/notable.md`
- `Lessons_Learned/quality-of-life.md`

### Root-Level Project Docs (update for stale facts or new capabilities)

- `README.md` — test counts, phase status, eval metrics, architecture diagram, roadmap
- `START_HERE.md` — setup steps, prerequisites, workflow summary
- `docs/architecture/ARCHITECTURE.md` — as-built component status table, evidence inventory

## Instructions

### Planning & Lessons

1. Compare today's code/doc changes (via `git diff --stat HEAD~5` or similar) against current sprint status, open questions, risks, and lessons learned.
2. Update `ACTIVE_SPRINT.md` only if something materially changed: milestone completed, blocker removed, new in-progress work, or phase status changed.
3. Update `OpenQuestions_Risks.md` only if a question was resolved or newly discovered, a risk changed state, or a new meaningful risk appeared.
4. Add a `Lessons_Learned/` entry only for non-trivial issues, workflow pitfalls, or repeatable fixes discovered today. Use the standard entry format (see existing entries for reference).

### Root-Level Project Docs

5. Update `README.md` only if a factual stat is stale (test count changed, phase status changed, eval metrics changed, new infrastructure deployed) or a capability was added/removed. Do not rewrite prose for style.
6. Update `START_HERE.md` only if setup prerequisites changed, a new workflow step was added, or the reading order needs a new entry.
7. Update `docs/architecture/ARCHITECTURE.md` only if a component's implementation status changed (new component wired, stub replaced with real implementation, architecture decision made). Update the "AS OF" table when making changes.

### General Rules

8. If nothing important changed, explicitly report "No updates needed" for each doc group.
9. Preserve formatting, IDs, legend structure, and status values. Do not invent new status labels.
10. Keep entries factual and grounded in repo evidence — cite file paths, commit SHAs, or error messages.
11. If you update files, include a short summary: what changed, why, and what evidence justified it.

## Output Format

```
ACTIVE_SPRINT:        updated / no update needed
OpenQuestions_Risks:   updated / no update needed
Lessons Learned:       updated / no update needed
README.md:            updated / no update needed
START_HERE.md:        updated / no update needed
Architecture Report:  updated / no update needed

Summary of edits:
  <bullet list of what changed and why>

Evidence used:
  <bullet list of git diffs, file paths, or observations>
```

## Post-Completion

Run `pwsh scripts/verify.ps1` only if any files were modified.
