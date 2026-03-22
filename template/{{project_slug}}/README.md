# {{ project_name }}

{{ project_description }}

## Quick Start

```powershell
uv venv
uv lock
uv sync --dev
```

Open in Cursor or Claude Code — governance, commands, and verification are ready.

## Project Structure

See `START_HERE.md` for detailed onboarding and `REPO_MAP.md` for the current project map.

## Verification

```powershell
# Fast check (lint + typecheck)
pwsh scripts/verify-fast.ps1

# Full check (lint + typecheck + tests)
pwsh scripts/verify.ps1
```

## Documentation

- `AGENTS.md` — Agent-agnostic governance rules
- `CLAUDE.md` — Claude Code specifics
- `CURSOR_RULES.md` — Cursor rule index
- `docs/architecture/ARCHITECTURE.md` — System architecture
- `docs/reference/ENV_VARS.md` — Environment variable reference
{% if include_e2e_tests %}
- `docs/testing-e2e.md` — Playwright browser testing guide
{% endif %}

## License

{{ license }}
