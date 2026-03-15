# CLAUDE.md — Claude Code Instructions for {{ project_name }}

> See **@AGENTS.md** for universal project instructions (non-negotiables, verification gates, 3-mode contract, living docs, task handoff roles).

---

## Model & Agent Teams

- **Claude Code model:** `claude-opus-4-6` (set in `.claude/settings.json`)
- **Bedrock runtime models:** Configure in `env_spec.py`. Bedrock inference profile IDs differ from Claude Code model IDs — do not change one to match the other.
- **Agent teams:** Enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). Use for tasks benefiting from parallel specialists (e.g., frontend + backend + tests). Use regular subagents for quick focused tasks that report back.

---

## Commands

| Command | Purpose |
|---|---|
| `/review` | Diff checks on staged changes; golden-rule violation scan |
| `/status` | Repository status summary (git diff, lint, type results) |
| `/verify` | Run staged verification (`verify-fast` then `verify`) |
| `/repo-map` | Update `REPO_MAP.md` via `scripts/dev/repo-map.ps1` |
| `/eod` | Full end-of-day wrap-up: file triage + doc drift check + conditional doc/lesson updates + verify |
| `/change-summary` | Generate commit/PR summary from git diff |

Commands use `$ARGUMENTS` for parameters. Use explicit invocation for quality gates — do not rely on auto-invocation.

---

## Agent Definitions

| Agent | Role |
|---|---|
| `code-reviewer` | Reviews diffs for correctness, style, security, and golden-rule violations |
| `researcher` | Gathers context from docs, code, and external references before implementation |
| `architect` | Evaluates structural decisions, proposes module boundaries, reviews data flow |
| `test-runner` | Executes test suites, reports coverage, triages failures |
| `implementer` | Executes development tasks following the HANDOFF_TASK_PACKET template |
| `refactorer` | Safe refactoring via Mikado method; restructures without changing behavior |

Agent definitions live in `.claude/agents/`. Each uses YAML frontmatter (name, description, tools, model).

---

## Task Structure

When executing implementation tasks, follow the structured handoff system:
- **Roles:** IMPLEMENTER, REVIEWER, REFACTORER (see `.cursor/roles/`)
- **Templates:** Prompt templates live in `.cursor/prompts/` and are shared across both Claude Code and Cursor (HANDOFF_TASK_PACKET, REFACTOR_TASK_PACKET, TEMPLATE_BUGFIX, etc.)
- **Handoff notes:** Use `.cursor/roles/HANDOFF_NOTE_TEMPLATE.md` for session handoff documentation
- **Every task ends with:** `/verify` passing

---

## Hooks

Optional `PostToolUse` lint hook (configured in `.claude/settings.json`):

- **Trigger:** After any Write/Edit to a `.py` file (matcher: `"Edit|Write"`).
- **Action:** Wrapper script `.claude/hooks/lint-python.ps1` reads stdin JSON, runs `ruff check`.
- **Non-blocking:** Always exits 0. Feedback only — never auto-applies fixes.

Hooks are for logging and feedback. Never use hooks to auto-apply changes.

---

## Safety

**Deny list** (never run):
- `git push`, `git reset --hard`, `git rebase`, `rm -rf`

**Allow list** (safe to run):
- Git read/write: `git status`, `git diff`, `git log`, `git add`, `git commit`, `git branch`, `git checkout`, `git stash`
- Dev tools: `ruff`, `mypy`, `pytest`, `python`, `uv` (and `uv run` variants)
- Scripts: `pwsh scripts/*`
- Read utils: `cat`, `ls`, `tree`, `head`, `tail`, `wc`

All permissions use `Bash(command *)` format in `.claude/settings.json`.

---

## Verification

Before committing: `scripts/verify-fast.ps1` (or `.sh`).
Before finishing a task: `scripts/verify.ps1` (or `.sh`).
On failure: read `.cursor/last-verify-failure.txt`.

---

## Lessons Learned

After resolving non-trivial issues, log them:
```
pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..."
```
See `Lessons_Learned/` at repo root. Promote recurring lessons to living template docs.

---

## Context Budget

Keep this file under **150 lines**. Skill descriptions consume ~2% of the context window. Use `/context` to monitor usage. Detailed instructions belong in `AGENTS.md`, not here.