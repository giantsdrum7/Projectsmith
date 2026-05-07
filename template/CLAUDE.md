# CLAUDE.md — Claude Code Instructions for {{ project_name }}

> **@AGENTS.md** is the canonical source for all shared governance: non-negotiables, verification gates, allowed/forbidden operations, human-only file protocol, daily workflow, task handoff roles, lessons learned, and shared canonical assets.

---

## Model & Agent Teams

- **Claude Code model:** `{{ claude_code_model }}` (set in `.claude/settings.json`)
- **Bedrock runtime models:** Configure in `env_spec.py`. Bedrock inference profile IDs differ from Claude Code model IDs — do not change one to match the other.
- **Agent teams:** Enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Use for tasks benefiting from parallel specialists. Use regular subagents for quick focused tasks.

---

## Commands

| Command | Tier | Purpose |
|---|---|---|
| `/review` | A | Review staged changes against canonical checklist (`.agent-config/checklists/code-review.md`) |
| `/eod` | B | Orchestrate end-of-day: file triage → doc drift → conditional updates → verify |
| `/status` | B | Repository status summary (git diff, lint, type results) |
| `/change-summary` | B | Generate commit/PR summary from git diff |
| `/verify` | C | Run staged verification (`verify-fast` then `verify`) — script-first, no skill dependency |
| `/repo-map` | C | Update `REPO_MAP.md` via `scripts/dev/repo-map.ps1` |

Tiers: **A** = skill-backed thin command, **B** = bounded orchestration, **C** = script-first explicit.
Commands use `$ARGUMENTS` for parameters. Use explicit invocation for quality gates.

---

## Skills

| Skill | Purpose | Invocation |
|---|---|---|
| `repo-map` | Update REPO_MAP.md with current repo state | Manual (`/repo-map`) |
| `code-review` | Review changes against canonical checklist | Auto / `/review` |
| `doc-sync` | Check documentation drift against code changes | Auto / `/eod` |
| `quality-sweep` | Broad quality pass — smells, dead code, conventions | Auto |
| `eod` | End-of-day wrap-up workflow orchestration | Auto / `/eod` |
| `refactor-radar` | Identify refactoring opportunities and complexity | Auto |

Skill definitions live in `.claude/skills/`. See `AGENTS.md` for the Skills vs Commands vs Rules framework.

---

## Agents

| Agent | Role |
|---|---|
| `code-reviewer` | Reviews diffs; uses canonical checklist from `.agent-config/checklists/code-review.md` |
| `researcher` | Gathers context from docs, code, and external references |
| `architect` | Evaluates structural decisions, proposes module boundaries |
| `test-runner` | Executes test suites, reports coverage, triages failures |
| `implementer` | Executes tasks following the HANDOFF_TASK_PACKET template |
| `refactorer` | Safe refactoring via Mikado method |

Agent definitions live in `.claude/agents/`. Each uses YAML frontmatter (name, description, tools, model).

---

## Hooks

Configured in `.claude/settings.json`. All hooks are **non-destructive** — feedback and reminders only, never auto-fix or auto-format.

| Hook | Event | Purpose |
|---|---|---|
| `lint-python.ps1` | PostToolUse | Ruff lint feedback on `.py` files after Write/Edit |
| `guard-protected-files.ps1` | PreToolUse | Approval prompt before editing protected files |
| `verify-reminder.ps1` | Stop | Reminder to run `/verify` if code files changed |
| `stale-artifact-reminder.ps1` | SessionStart | Flags stale repo map, doc-check, or EOD artifacts |

---

## Safety

**Deny list** (never run): `git push`, `git reset --hard`, `git rebase`, `rm -rf`

**Allow list** (safe to run):
- Git: `git status`, `git diff`, `git log`, `git add`, `git commit`, `git branch`, `git checkout`, `git stash`
- Dev tools: `ruff`, `mypy`, `pytest`, `python`, `uv`
- Scripts: `pwsh scripts/*`
- Read utils: `cat`, `ls`, `tree`, `head`, `tail`, `wc`

All permissions use `Bash(command *)` format in `.claude/settings.json`.

---

## Verification

Before committing: `scripts/verify-fast.ps1` (or `.sh`).
Before finishing a task: `scripts/verify.ps1` (or `.sh`).
On failure: read `.cursor/last-verify-failure.txt`.

---

## Context Budget

Keep this file under **100 lines**. Detailed governance belongs in `AGENTS.md`, not here.
Skill descriptions consume ~2% of the context window. Monitor usage with `/context`.
