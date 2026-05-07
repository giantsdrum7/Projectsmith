# Projectsmith — Product Design Packet

## 1. What Projectsmith Is

A Copier template that one-shot generates a production-ready AI project scaffold. After generation, a developer can immediately open the project in Cursor or Claude Code and start building with full agent support — governance, commands, verification gates, and daily workflow automation are all functional before any business logic is written.

A generated project includes:
- Full directory structure (src, tests, docs, scripts, evals, infra)
- Pre-configured Claude Code tooling (settings.json, agents, commands, hooks, skills)
- Pre-configured Cursor tooling (rules, roles, prompts, commands)
- Agent-agnostic governance layer (AGENTS.md as canonical source of truth)
- 3-mode environment contract (offline / local-live / prod)
- CI/CD workflows (lint, type-check, test, eval, security scan)
- Verification gates and daily workflow automation scripts
- Lessons Learned system with promotion protocol back to upstream

## 2. Non-Goals (V1)

Projectsmith does **not** aim to:
- Encode any specific project's domain architecture (HopeAI, ProposalAI, etc.)
- Force AWS, Bedrock, OpenSearch, or any provider by default
- Generate application business logic
- Guarantee zero-conflict `copier update` for heavily customized downstream files without human review
- Replace project-specific architectural decisions

## 3. Template vs. Generated Project Topology

**Projectsmith repo** (`giantsdrum7/Projectsmith`) = upstream template product
- Contains Copier template source, Jinja2-templated files, template CI, product docs
- Maintained as a living product with versioned releases

**Generated project** = downstream repo produced by `copier copy`
- Contains the materialized scaffold with project-specific values filled in
- Owned entirely by the downstream team
- Pulls upstream improvements via `copier update`

Some capabilities exist only in the upstream product (template CI, authoring docs, contribution guide). Runtime governance, commands, and scripts exist in every generated project.

## 4. File Ownership Model

**Scaffold-managed** (copier update may overwrite):
- `.claude/` (all files)
- `.cursor/rules/`, `.cursor/commands/`, `.cursor/roles/`, `.cursor/prompts/`
- `scripts/dev/`, `scripts/verify*`, `scripts/env/`
- `.github/workflows/`
- `.pre-commit-config.yaml`, `.gitignore`, `.cursorignore`
- `AGENTS.md`, `CLAUDE.md`, `CURSOR_RULES.md`
- `docs/scaffold/CAPABILITY_MATRIX.md`

**Project-owned** (copier update must never touch):
- `src/{{project_slug}}/` (all application code)
- `tests/` (all test code beyond contract tests)
- `docs/architecture/` content, `docs/planning/` content
- `Lessons_Learned/` entries (entry format is scaffold-managed; actual entries are project-owned)
- `REPO_MAP.md` HUMAN sections

**Merge-managed** (copier update surfaces diffs, human decides):
- `README.md`, `START_HERE.md`
- `pyproject.toml` — scaffold owns structure and tool config blocks; project owns dependencies and metadata
- `.copier-answers.yml`

## 5. Capability Parity Contract

**Required shared outcomes** (must exist in both Claude Code and Cursor):

| Capability | Description |
|---|---|
| review | Review staged changes |
| status | Repo state summary |
| verify | Run verification gates (fast + full) |
| repo-map | Update REPO_MAP.md AUTO sections |
| eod | End-of-day triage + doc drift + lessons reminder |
| change-summary | Generate commit/PR summary |
| Role: implementer | Task execution guidance |
| Role: reviewer | Code review guidance + checklist |
| Role: refactorer | Safe refactoring via Mikado method |
| Role: researcher | Investigation before implementation |
| Role: architect | System design and trade-off evaluation |
| Handoff support | Task packet and handoff note templates |

**Acceptable native asymmetries:**
- Claude Code: PostToolUse hooks, settings.json permission model, skills, `/init` bootstrap command
- Cursor: `.mdc` auto-attached rules (glob-scoped), IDE-managed permissions, skills (beta/unreliable)

**Optional domain modules** (conditionally included via Copier flags):
- `llm-routing.mdc` — LLM provider patterns, response parsing, sampling parameter rules
- `backend.mdc` — API/Lambda/ECS patterns
- `frontend.mdc` — React/Vite patterns
- Extended testing depth in `testing.mdc` — mode-pinning, singleton cache patterns

## 6. Copier Variable Contract

**Core variables:**

| Variable | Type | Default | Description |
|---|---|---|---|
| `project_name` | str | *(required)* | Human-readable project name |
| `project_slug` | str | *(derived)* | Python package name (auto from project_name) |
| `project_description` | str | `""` | One-line description |
| `aws_region` | str | `"us-east-1"` | AWS region |
| `github_org` | str | *(required)* | GitHub org or username |
| `github_team_slug` | str | `"core-team"` | For CODEOWNERS |
| `python_version` | str | `"3.12"` | Minimum Python version |
| `license` | choice | `"MIT"` | MIT / Apache-2.0 / proprietary |
| `claude_code_model` | str | `"claude-opus-4-7"` | Model in settings.json |

**Provider choices:**

| Variable | Type | Default | Choices |
|---|---|---|---|
| `metadata_store` | choice | `"none"` | none / dynamodb / postgres |
| `llm_provider` | choice | `"none"` | none / bedrock / openai |

**Optional module flags:**

| Variable | Type | Default |
|---|---|---|
| `include_frontend` | bool | `false` |
| `include_infra` | bool | `false` |
| `include_observability` | bool | `false` |
| `include_security` | bool | `false` |
| `include_evals` | bool | `true` |
| `include_e2e_tests` | bool | `false` |

`include_e2e_tests` is gated by `when: "{{ include_frontend }}"` (hidden when frontend is off) and enforced by a cross-variable validator that aborts generation if the combination `include_e2e_tests=true` + `include_frontend=false` is forced via `--data`.

## 7. Template CI Contract

Projectsmith's own CI validates five representative presets:

| Preset | Config | What it proves |
|---|---|---|
| **Minimal** | All optional modules off, provider=none, metadata_store=none | Base scaffold is truly agnostic and functional |
| **AI-core** | llm_provider=bedrock, include_evals=true, metadata_store=dynamodb | Typical AI project works end-to-end |
| **Full-stack** | All non-e2e modules on: frontend + infra + observability + security + evals | Maximum complexity still passes (e2e intentionally off to keep full-stack independent) |
| **E2E** | include_frontend=true + include_e2e_tests=true | Playwright scaffold generates correctly; files appear where expected, e2e/frontend dependency enforced |
| **Long-slug** | AI-core configuration with `project_slug=very_long_project_slug_for_testing` (35 chars) | Validates that emitted projects with long slugs (≥ 25 chars) do not violate the 120-char line-length limit in scaffold-managed Python files |

For each preset, CI runs:
1. `copier copy` with preset answers
2. `uv venv && uv lock && uv sync --dev`
3. `ruff check && ruff format --check && mypy`
4. `pytest` (contract tests)

A separate `no-double-nest` job in the same workflow runs
`scripts/dev/test-no-double-nest.sh` with both a short and a 35-char slug
to lock in the v1.1.0 fix that flattened `template/{{project_slug}}/` into
`template/`. It fails if the rendered output ever regains the redundant
extra `<slug>/` layer at the destination root.

## 8. Lesson Promotion Workflow (Downstream → Upstream)

1. Developer encounters issue in downstream project
2. Logs in local `Lessons_Learned/` with category (critical / notable / quality-of-life)
3. Triages into one of three buckets:
   - **Project-only** — stays in downstream repo
   - **Generic scaffold improvement** — PR against `giantsdrum7/Projectsmith`
   - **Optional module improvement** — PR against Projectsmith, scoped to the module
4. Projectsmith maintainer reviews and merges
5. Downstream projects pull via `copier update`

## 9. Versioning and Update Policy

- Projectsmith uses tagged releases (semver-ish: `v1.0.0`, `v1.1.0`, etc.)
- Downstream projects pin to a release and update deliberately via `copier update`
- Scaffold-managed files are safe to accept automatically
- Merge-managed files require human review of the diff
- Project-owned files are excluded from update

## 10. Generated Project Acceptance Criterion

A freshly generated project must be openable in Cursor and Claude Code immediately, with governance, commands, and verification gates usable before any business logic is added. `verify-fast` must pass on a fresh generation with zero manual intervention.

## 11. Multi-IDE Support Strategy

**Design Principles:**
1. **Canonical layer:** AGENTS.md defines behavior and capability intent for all IDEs
2. **Translation layers:** Each IDE gets native config that translates AGENTS.md into its format (`.claude/`, `.cursor/`, future `.github/`, future `.agent/`)
3. **Outcome parity over file parity:** Each IDE only needs native artifacts sufficient to achieve the same operational outcomes — identical file counts are not required

**V1 ships with:** Claude Code (`.claude/`) + Cursor (`.cursor/`)

**V2 targets:** GitHub Copilot (`.github/`) + Google Antigravity (`.agent/`)

**V2 success criterion:** A generated project should be usable in any supported AI IDE without changing AGENTS.md or core scripts; only the IDE-native translation layer should vary.

**V2 known integration points:**
- GitHub Copilot: `.github/copilot-instructions.md`, `.github/agents/*.agent.md`, `.github/skills/*/SKILL.md`
- Antigravity: `.agent/rules/*.md`, `.agent/workflows/*.md`, `GEMINI.md` (global pointer to AGENTS.md)

**Copier integration:** `include_copilot_config` and `include_antigravity_config` are reserved as planned V2 variables. They are not active in V1 but are documented here so the architecture accommodates them. The capability matrix (`docs/scaffold/CAPABILITY_MATRIX.md`) includes planned columns for Copilot and Antigravity from day one.
