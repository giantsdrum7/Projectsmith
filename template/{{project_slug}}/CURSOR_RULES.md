# CURSOR_RULES.md — Rule Index for {{ project_name }}

This file indexes `.cursor/rules/*.mdc` modules. See **AGENTS.md** for universal project instructions.

> **Note:** Use only flat `.mdc` files in `.cursor/rules/`. The `RULE.md` folder format has known reliability issues as of early 2026. Do not use it.

---

## Rule Modules

| File | Scope | Description |
|---|---|---|
| `core.mdc` | `alwaysApply: true` | Universal coding standards, naming conventions, error handling |
| `testing.mdc` | `globs: tests/**` | Test conventions, coverage thresholds, fixture patterns |
| `executor.mdc` | `alwaysApply: true` | Task execution workflow, verification gates, commit discipline |
| `refactoring.mdc` | `globs: src/**` | Mikado method, safe refactoring patterns, incremental commits |
| `llm-routing.mdc` | `globs: src/**/llm/**` | LLM provider selection, fallback logic, model configuration |
| `backend.mdc` | `globs: src/**/api/**` | FastAPI Lambda patterns, Mangum adapter, Pydantic validation, auth, Powertools |
| `cdk.mdc` | `globs: infra/**` | CDK conventions: stack naming, construct patterns, IAM least-privilege, alarms |
| `data-access.mdc` | `globs: src/**/tools/**, src/**/api/**, src/**/orchestration/**` | DynamoDB access patterns, tenant isolation, atomic operations, GSI usage |
| `api-contract.mdc` | `globs: src/**/api/**, apps/web/src/lib/**, packages/**` | Shared contract discipline, type generation, API shape ownership |
| `frontend.mdc` | `globs: apps/web/**` | **FUTURE** — React/Vite patterns, component structure, state management |

> **Important:** Do not set both `alwaysApply: true` and `globs:` on the same rule. `alwaysApply` silently overrides `globs` (undocumented behavior).

> **FUTURE rules:** Rules marked FUTURE target features not present at scaffold time. They activate when matching files are added. Rules without the FUTURE tag are active now.

---

## Related Directories

| Path | Purpose |
|---|---|
| `.cursor/roles/` | Agent role definitions (Implementer, Reviewer, Refactorer, Researcher, Architect) |
| `.cursor/prompts/` | Task packet templates (handoff, refactor, PR summary, bug fix) |
| `.cursor/commands/` | Cursor command wrappers (`/repo-map`, `/verify`, `/eod`) |
| `.cursor/archive/` | Historical artifacts — outdated reports, superseded generated docs |
| `.agent-config/` | Shared canonical assets (review checklist, etc.) — see `.agent-config/README.md` |

Each `.mdc` file uses YAML frontmatter with `description`, `globs`, and `alwaysApply` fields. Cursor supports four rule types: Always, Auto, Agent-requested, and Manual.
