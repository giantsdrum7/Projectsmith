# Refactoring Guide — {{ project_name }}

## The 6-Phase Mikado Method

This project uses the **Mikado method** for safe, incremental refactoring. This prevents large, risky changes by breaking refactors into small, independently verifiable steps.

### Phases

1. **Set a goal** — Define the desired end state clearly. Write it down in a refactoring task packet (see `.cursor/prompts/refactor-task-packet.md`).

2. **Try to achieve the goal** — Attempt the change directly. This is an experiment, not a commitment.

3. **If it fails, note the error** — When the direct approach breaks something (tests fail, types don't align, dependencies conflict), record exactly what failed and why.

4. **Find the root cause** — Trace the failure back to its origin. The thing you need to fix first is usually deeper in the dependency chain than where the error surfaces.

5. **Fix the root cause first** — Make the smallest change that resolves the root blocker. Commit this fix independently. Run `scripts/verify-fast.ps1` to confirm it passes.

6. **Retry the goal** — Return to step 2 with the root cause resolved. Repeat until the goal succeeds cleanly.

### Key Principles

- **Never skip verification between steps.** Each micro-commit must pass `verify-fast`.
- **Revert freely.** If a step creates more problems than it solves, revert it and try a different decomposition.
- **Draw the Mikado graph.** For complex refactors, sketch the dependency tree of changes. Work from the leaves inward.
- **One concern per commit.** Each commit should address exactly one sub-goal in the Mikado graph.

---

## Using the Refactoring Task Packet

For non-trivial refactors, fill out the refactoring task packet template at `.cursor/prompts/refactor-task-packet.md`. This ensures:

- The goal is clearly stated with acceptance criteria.
- The current state and desired state are documented.
- Known dependencies and risks are identified upfront.
- The Mikado decomposition is planned before coding begins.

---

## Refactoring Checklist

- [ ] Goal documented in task packet.
- [ ] Mikado graph sketched (if complex).
- [ ] Each step passes `verify-fast` before moving on.
- [ ] No unrelated changes mixed in.
- [ ] Final result passes full `verify`.
- [ ] PR description references the task packet and Mikado graph.
