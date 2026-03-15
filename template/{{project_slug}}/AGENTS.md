# AGENTS.md — Universal Agent Instructions (Cross-Tool Standard)

> Compatible with: Cursor, Codex, Gemini CLI, GitHub Copilot, Linux Foundation AAIF.
> Project: **{{ project_name }}** | Slug: `{{ project_slug }}`

---

## Project Identity

{% raw %}{{FILL: project identity summary — 1-2 sentences describing what this project does, who it serves, and its core design constraint}}{% endraw %}

**Key architecture facts agents should know:**
- **Metadata store:** {% raw %}{{FILL: e.g. DynamoDB, PostgreSQL, Supabase}}{% endraw %}
- **Retrieval:** {% raw %}{{FILL: retrieval strategy, e.g. OpenSearch hybrid BM25 + vector}}{% endraw %}
- **LLM runtime:** AWS Bedrock — configure model IDs in `env_spec.py`. Bedrock inference profile IDs differ from Claude Code model IDs.
- **Agent tooling model:** `claude-opus-4-6` (used in `.claude/settings.json` for Claude Code itself)
- **Region:** {% raw %}{{FILL: AWS region, e.g. us-east-1}}{% endraw %}
- **Core philosophy:** {% raw %}{{FILL: project design philosophy, e.g. "LLM as orchestrator, tools as truth"}}{% endraw %}

Full architecture: `docs/architecture/ARCHITECTURE.md`.

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

## 3-Mode Contract

| Mode | Description | Set via |
|---|---|---|
| `offline` | No external calls. Stub LLM responses. Safe for air-gapped dev. | `scripts/env/use-env.ps1 -Mode offline` |
| `local-live` | Real Bedrock calls against dev resources. | `scripts/env/use-env.ps1 -Mode local-live` |
| `prod` | CI/CD only. Never set locally. | CI/CD pipeline only |

Switch modes using `scripts/env/use-env.ps1` (Windows) or `scripts/env/use-env.sh` (Unix).

---

## Task Handoff & Roles

When receiving implementation tasks, agents should follow the structured handoff system:

**Roles** (defined in `.cursor/roles/`):
- **IMPLEMENTER** — writes production code, tests, and documentation
- **REVIEWER** — checks quality, security, and consistency
- **REFACTORER** — improves structure without changing behavior (Mikado method)

**Task templates** (in `.cursor/prompts/`):
Use `HANDOFF_TASK_PACKET.md` for general tasks, `REFACTOR_TASK_PACKET.md` for refactoring, and the appropriate `TEMPLATE_*.md` for bug fixes, env var additions, incident debugging, or PR summaries.

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

## Daily Workflow

1. **Start of day** → Run `/repo-map` to update `REPO_MAP.md`.
2. **During day** → Code as usual. Lint feedback appears automatically if hooks are enabled.
3. **Before push** → Run `/verify`. Do not push until `VERIFY: PASS`.
4. **End of day** → Run `/eod` for full wrap-up (file triage, doc drift check, conditional sprint/risk/lesson updates, verify).
5. **After resolving non-trivial issues** → Log in `Lessons_Learned/` via `scripts/dev/add-lesson.ps1` (or let `/eod` handle it automatically).

---

## Lessons Learned

When you fix a bug that took significant effort, discover surprising behavior, or resolve a workflow issue, log it:

```powershell
pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..."
```

Categories: `critical` (production/security), `notable` (non-trivial bugs, API surprises), `quality-of-life` (workflow tips). Files live in `Lessons_Learned/` at repo root.

---

## Proof Bundles

All workflow scripts write audit logs to `.cursor/audits/<action>/<date>/<timestamp>/`. This directory is gitignored. Proof bundles include `meta.json`, `summary.md`, and action-specific artifacts.

---

## Script Interface Standard

All workflow scripts in `scripts/dev/` support:
- `--dry-run` (default) — preview changes without applying.
- `--apply` — execute changes with explicit opt-in.
- `--out <dir>` — specify proof bundle output directory.
- `--format json|text` — output format (`json` for tooling, `text` for humans).