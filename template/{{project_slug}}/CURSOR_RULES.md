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
| `backend.mdc` | `globs: src/**/api/**` | API patterns, Lambda/ECS conventions, request/response schemas |
| `frontend.mdc` | `globs: apps/web/**` | React/Vite patterns, component structure, state management |

> **Important:** Do not set both `alwaysApply: true` and `globs:` on the same rule. `alwaysApply` silently overrides `globs` (undocumented behavior).

---

## Related Directories

| Path | Purpose |
|---|---|
| `.cursor/roles/` | Agent role definitions (Implementer, Reviewer, Refactorer) |
| `.cursor/prompts/` | Task packet templates (handoff, refactor, PR summary, bug fix) |
| `.cursor/commands/` | Cursor command wrappers (`/repo-map`, `/verify`, `/eod`) |

Each `.mdc` file uses YAML frontmatter with `description`, `globs`, and `alwaysApply` fields. Cursor supports four rule types: Always, Auto, Agent-requested, and Manual.
