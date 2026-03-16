# AGENTS.md — Universal Agent Instructions (Cross-Tool Standard)

> Compatible with: Cursor, Codex, Gemini CLI, GitHub Copilot, Linux Foundation AAIF.

---

# Part 1 — Universal Governance

*These rules apply to every project using this agent system. They are non-negotiable and tool-agnostic.*

---

## Non-Negotiables

1. **No secrets in code.** Use `REDACTED_ORG_SPECIFIC` or `{% raw %}{{TEMPLATE_VAR}}{% endraw %}` for sensitive values.
2. **All changes must pass verification** before being committed.
3. **Never push without green verify.** Run `scripts/verify.ps1` (or `.sh`) and confirm PASS.
4. **Never modify human-only files** after initial scaffold creation.
5. **Never run destructive git commands** (`git reset --hard`, `git rebase`, `rm -rf`).
6. **Evidence-first development.** When implementing retrieval or answer features, every claim must trace to a cited source span. If you cannot prove it, refuse it.

---

## Human-Only Files

These files are maintained exclusively by humans. Agents must **never** write to them after initialization:

- `AGENTS.md`
- `CLAUDE.md`
- `CURSOR_RULES.md`
- `pyproject.toml`
- `CODEOWNERS`
- `.pre-commit-config.yaml`

If a task requires changes to a human-only file:
1. **STOP** — do not attempt workarounds.
2. **Report** the exact change needed and which file it belongs in.
3. **Wait** for human response: `"changes made, continue"` or `"permission granted"`.
4. Do not proceed until a clear go-ahead is received.

---

## Allowed Operations

- Read any file in the repository.
- Create or edit files **outside** the human-only list.
- Run verification scripts (`scripts/verify.ps1`, `scripts/verify-fast.ps1`).
- Run workflow scripts in `scripts/dev/` in **dry-run mode** (default).
- Commit locally (`git add`, `git commit`). Do **not** push.

## Forbidden Operations

- `git push` to any remote.
- `rm -rf` on any path.
- `git reset --hard` or `git rebase`.
- Modify any file in the human-only list.
- Store secrets, tokens, or credentials in any file.
- Skip verification before committing.

---

## Verification Gates

| When | Command | Purpose |
|---|---|---|
| Before every commit | `scripts/verify-fast.ps1` (`.sh`) | Lint + type-check (fast) |
| Before finishing a task | `scripts/verify.ps1` (`.sh`) | Lint + type-check + tests (full) |
| On failure | Read `.cursor/last-verify-failure.txt` | Diagnose and fix before retrying |

Output format: `VERIFY: PASS` or `VERIFY: FAIL` with proof bundle path.

---

## Hook Guardrails

Hooks (configured in `.claude/settings.json`) provide deterministic automation at specific lifecycle points. All hooks in this scaffold are **non-destructive** — they provide feedback, reminders, and approval prompts but never auto-fix, auto-format, or mutate files.

| Hook | Event | Purpose |
|---|---|---|
| `lint-python.ps1` | PostToolUse | Ruff lint feedback on `.py` files after Write/Edit |
| `guard-protected-files.ps1` | PreToolUse | Approval prompt before editing human-only / governance files |
| `verify-reminder.ps1` | Stop | Reminder to run `/verify` if code-relevant files changed |
| `stale-artifact-reminder.ps1` | SessionStart | Flags stale repo map, doc-check, or EOD audit artifacts |

Hook scripts live in `.claude/hooks/` and always exit 0. If a hook encounters unexpected input or errors, it fails open (silent exit) rather than blocking work.

---

## Daily Workflow

1. **Start of day** → Run `/repo-map` to update `REPO_MAP.md`.
2. **During day** → Code as usual. Lint feedback appears automatically if hooks are enabled.
3. **Before push** → Run `/verify`. Do not push until `VERIFY: PASS`.
4. **End of day** → Run `/eod` for full wrap-up (file triage, doc drift check, conditional sprint/risk/lesson updates, verify).
5. **After resolving non-trivial issues** → Log in `Lessons_Learned/` via `scripts/dev/add-lesson.ps1` (or let `/eod` handle it automatically).

---

## Task Handoff & Roles

When receiving implementation tasks, agents should follow the structured handoff system:

**Roles** (defined in `.cursor/roles/`):
- **IMPLEMENTER** — writes production code, tests, and documentation
- **REVIEWER** — checks quality, security, and consistency
- **REFACTORER** — improves structure without changing behavior (Mikado method)
- **RESEARCHER** — investigates codebase, APIs, and docs before implementation decisions
- **ARCHITECT** — evaluates structural decisions, proposes module boundaries, reviews data flow

**Task templates** (in `.cursor/prompts/`):
Use `HANDOFF_TASK_PACKET.md` for general tasks, `REFACTOR_TASK_PACKET.md` for refactoring, and the appropriate `TEMPLATE_*.md` for bug fixes, env var additions, incident debugging, or PR summaries.

**Handoff notes:** Use `.cursor/roles/HANDOFF_NOTE_TEMPLATE.md` for session handoff documentation. Every task ends with `/verify` passing.

---

## Planner-Critic-Executor Collaboration Contract

For non-trivial tasks, agents collaborate using four roles. This contract governs the handoff between planning, review, and execution.

**Roles:**

| Role | Responsibility |
|---|---|
| **Planner** | Proposes approach, identifies scope, drafts a plan packet (objective, approach, scope boundaries, risk assessment, verification criteria, proof bundle expectations) |
| **Critic** | Reviews the plan for gaps, risks, overlooked alternatives, and scope creep. States **APPROVE**, **REQUEST CHANGES**, or **REJECT** with reasoning |
| **Executor** | Implements only what was approved. Reports completion with verification results and scope safety confirmation |
| **Human** | Final authority. Can override any decision. Acts as relay/approver between advisors and executor |

**Workflow:**

1. **Planner** proposes with a plan packet
2. **Critic** reviews → APPROVE / REQUEST CHANGES / REJECT
3. If REQUEST CHANGES → Planner revises, Critic re-reviews
4. If APPROVE → Human reviews and gives final go / no-go
5. **Executor** implements the approved plan
6. Executor reports completion with verification results
7. Planner or Critic may review the result afterward

**Rules:**

1. No implementation task is dispatched to the Executor until both Planner and Critic have explicitly agreed on the approach.
2. Information-gathering, read-only reconnaissance, and exploratory analysis may proceed without full deliberation.
3. Disagreements between Planner and Critic must be resolved through discussion before any implementation work begins.
4. The Human may override consensus, redirect who leads a given task, or escalate/de-escalate the deliberation level at any time.

Role definitions in `.cursor/roles/` govern within-role execution behavior. This contract governs the collaboration between roles.

---

## Skills vs Commands vs Rules

The agent governance system uses three complementary mechanisms. Choose the right one for each need:

**Skills** (`.claude/skills/`) encapsulate reusable workflow knowledge, judgment, and multi-step reasoning. They use progressive disclosure — the model sees a short description and activates the full skill only when relevant. Skills are appropriate for tasks that require contextual judgment (e.g., reviewing code quality, identifying refactoring opportunities, checking documentation drift).

**Commands** (`.claude/commands/`, `.cursor/commands/`) are explicit entry points invoked by the user or by other commands. They come in three tiers:
- **Tier A** — skill-backed thin commands that delegate to a skill or canonical asset
- **Tier B** — bounded orchestration that sequences multiple scripts/steps with human checkpoints
- **Tier C** — script-first explicit commands that invoke a deterministic script and report results

**Rules** (`.cursor/rules/*.mdc`) provide always-on or file-scoped context injected into the model's prompt. Rules should stay thin — coding standards, naming conventions, and architectural constraints. Do not embed workflow logic in rules; that belongs in commands and scripts.

**Mandatory quality gates** such as `/verify` must remain explicit commands (Tier C), not skills. Skill auto-invocation is unreliable for mandatory steps — the model decides when to invoke skills, and the trigger rate is insufficient for workflow gates that must always execute.

---

## Proof Bundles

All workflow scripts write audit logs to `.cursor/audits/<action>/<date>/<timestamp>/`. This directory is gitignored. Proof bundles include `meta.json`, `summary.md`, and action-specific artifacts.

---

## Lessons Learned

When you fix a bug that took significant effort, discover surprising behavior, or resolve a workflow issue, log it:

```powershell
pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..."
```

Categories: `critical` (production/security), `notable` (non-trivial bugs, API surprises), `quality-of-life` (workflow tips). Files live in `Lessons_Learned/` at repo root.

Promote recurring lessons to living template docs. See the promotion protocol for thresholds and backlink conventions.

---

## Script Interface Standard

All workflow scripts in `scripts/dev/` support:
- `--dry-run` (default) — preview changes without applying.
- `--apply` — execute changes with explicit opt-in.
- `--out <dir>` — specify proof bundle output directory.
- `--format json|text` — output format (`json` for tooling, `text` for humans).

---

## Living Docs Maintenance

`REPO_MAP.md` uses AUTO/HUMAN section markers to separate generated and hand-maintained content.

**AUTO sections** are delimited by:
```
<!-- AUTO:START:section_name -->
...generated content...
<!-- AUTO:END:section_name -->
```

**Rules:**
- Agents may **only** update content inside `AUTO:START` / `AUTO:END` markers.
- **Never** overwrite content in `<!-- HUMAN -->` sections.
- Run `/repo-map` (or `scripts/dev/repo-map.ps1`) to regenerate AUTO sections.

---

## Generated Artifact Lifecycle

Generated artifacts (repo maps, drift reports, proof bundles, coverage reports) should carry provenance metadata:
- **`generated_at`** — timestamp of generation
- **`covered_scope`** — which files, modules, or commits are reflected
- **`staleness`** — expected refresh interval or conditions under which regeneration is needed

Agents should treat generated artifacts as potentially stale. When in doubt, regenerate before relying on a generated artifact for decisions.

Stale reconnaissance reports and outdated generated docs should be archived to `.cursor/archive/` with a historical banner (e.g., `> **ARCHIVED** — This report was generated on YYYY-MM-DD and may not reflect current state.`) rather than left in active locations where agents might trust them as current truth.

---

## Shared Canonical Assets

Shared canonical assets live in `.agent-config/` and follow the **"reference, never duplicate"** principle:

- `.agent-config/checklists/code-review.md` — the single canonical review checklist
- `.agent-config/README.md` — documents the canonical asset convention

Tool-specific files (`.claude/agents/code-reviewer.md`, `.cursor/roles/REVIEW_CHECKLIST.md`, etc.) **reference** the canonical asset rather than maintaining separate copies. When the canonical asset is updated, all tools automatically use the latest version.

See `.agent-config/README.md` for details on the canonical vs tool-native distinction.

---

## Archive Convention

`.cursor/archive/` stores historical artifacts that are no longer current but should be retained for reference:
- Outdated reconnaissance reports
- Superseded generated docs
- Historical verification snapshots

Every archived file should have a banner at the top indicating when it was archived and what superseded it. Agents must never trust archived files as current state.

---

# Part 2 — Project-Specific Context

*This section is unique to each project. Fill in the placeholders below with your project's details.*

---

## Project Identity

> Project: **{{ project_name }}** | Slug: `{{ project_slug }}`

{% raw %}{{FILL: project identity summary — 1-2 sentences describing what this project does, who it serves, and its core design constraint}}{% endraw %}

---

## Architecture Overview

**Key architecture facts agents should know:**
- **Metadata store:** {% raw %}{{FILL: e.g. DynamoDB, PostgreSQL, Supabase}}{% endraw %}
- **Retrieval:** {% raw %}{{FILL: retrieval strategy, e.g. OpenSearch hybrid BM25 + vector}}{% endraw %}
- **LLM runtime:** AWS Bedrock — configure model IDs in `env_spec.py`. Bedrock inference profile IDs differ from Claude Code model IDs.
- **Agent tooling model:** `{{ claude_code_model }}` (used in `.claude/settings.json` for Claude Code itself)
- **Region:** {% raw %}{{FILL: AWS region, e.g. us-east-1}}{% endraw %}
- **Core philosophy:** {% raw %}{{FILL: project design philosophy, e.g. "LLM as orchestrator, tools as truth"}}{% endraw %}

Full architecture: `docs/architecture/ARCHITECTURE.md`.

---

## 3-Mode Contract

| Mode | Description | Set via |
|---|---|---|
| `offline` | No external calls. Stub LLM responses. Safe for air-gapped dev. | `scripts/env/use-env.ps1 -Mode offline` |
| `local-live` | Real Bedrock calls against dev resources. | `scripts/env/use-env.ps1 -Mode local-live` |
| `prod` | CI/CD only. Never set locally. | CI/CD pipeline only |

Switch modes using `scripts/env/use-env.ps1` (Windows) or `scripts/env/use-env.sh` (Unix).

---

## Infrastructure Identifiers

{% raw %}{{FILL: AWS account IDs, resource ARNs, bucket names, secret prefixes — or remove this section if not yet configured}}{% endraw %}

---

## Repo-Specific Conventions

{% raw %}{{FILL: Any conventions unique to this project — naming patterns, module boundaries, import conventions beyond what .cursor/rules/ enforces, or "None beyond the universal rules above."}}{% endraw %}

---

## Team Collaboration Model

{% raw %}{{FILL: How your team works — PR review process, branch strategy, who approves what, communication channels — or "Solo developer, standard PR workflow."}}{% endraw %}
