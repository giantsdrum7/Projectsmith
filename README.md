# Projectsmith

A Copier template that one-shot generates production-ready AI project scaffolds with full IDE agent support.

## What You Get

After `copier copy`, your generated project includes:
- Full directory structure (src, tests, docs, scripts, evals)
- Pre-configured **Claude Code** tooling (agents, commands, hooks, skills)
- Pre-configured **Cursor** tooling (rules, roles, prompts, commands)
- Agent-agnostic governance layer (`AGENTS.md` as canonical source of truth)
- 3-mode environment contract (offline / local-live / prod)
- CI/CD workflows (lint, type-check, test, eval, security scan)
- Verification gates and daily workflow automation
- Lessons Learned system with upstream promotion protocol

## Quick Start
```powershell
pip install copier
copier copy gh:giantsdrum7/Projectsmith my-project
Set-Location my-project
uv venv
uv lock
uv sync --dev
# Open in Cursor or Claude Code — governance, commands, and verification are ready
```

## Design

See [docs/scaffold/PRODUCT_DESIGN.md](docs/scaffold/PRODUCT_DESIGN.md) for the full product design packet.

## Multi-IDE Support

| IDE | V1 (shipped) | V2 (planned) |
|-----|:---:|:---:|
| Claude Code | ✓ | ✓ |
| Cursor | ✓ | ✓ |
| GitHub Copilot | — | ✓ |
| Google Antigravity | — | ✓ |

## Contributing

Improvements to the scaffold are welcome. See the [lesson promotion workflow](docs/scaffold/PRODUCT_DESIGN.md#8-lesson-promotion-workflow) for how downstream project learnings feed back into this template.

## License

MIT
