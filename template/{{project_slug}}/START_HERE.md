# START_HERE.md — Welcome to {{ project_name }}

Welcome to the **{{ project_name }}** project. This document gets you oriented quickly.

{% raw %}{{FILL: project identity summary — 1-2 sentences describing what this project does, who it serves, and its core design constraint}}{% endraw %}

---

## Reading Order

1. **START_HERE.md** (you are here) — Overview and setup.
2. **README.md** — Full project description, architecture, deployed resources, and roadmap.
3. **AGENTS.md** — Universal agent instructions, non-negotiables, verification gates.
4. **CLAUDE.md** / **CURSOR_RULES.md** — Tool-specific configuration (Claude Code or Cursor).
5. **REPO_MAP.md** — Living map of the repository (updated via `/repo-map`).
6. **docs/architecture/ARCHITECTURE.md** — Detailed architecture and phased delivery plan.

---

## Setup Steps

### Prerequisites

- **Python 3.12+** — Required for all tooling.
- **uv** — Unified virtualenv / package manager. Install via `pipx install uv`.
- **pre-commit** — Git hook manager. Install via `pipx install pre-commit`.
- **PowerShell 7+** (`pwsh`) — Required for workflow scripts on all platforms.
- **AWS CLI + CDK CLI** — Only needed for `local-live` or `prod` modes.

### First-Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/{{ github_org }}/{{ project_slug }}.git
cd {{ project_slug }}

# 2. Install Python dependencies (including dev/test tools)
uv sync --dev

# 3. Install pre-commit hooks
pre-commit install

# 4. Enter offline mode (no external calls, stub LLM)
# Windows (dot-source to persist env vars):
. .\scripts\env\use-env.ps1 -Mode offline
# Unix:
. ./scripts/env/use-env.sh --mode offline

# 5. Run fast verification to confirm setup
pwsh scripts/verify-fast.ps1
```

If verification passes (`VERIFY: PASS`), your environment is ready.

---

## Daily Workflow

| Step | Command | When |
|---|---|---|
| 1. Update repo map | `pwsh scripts/dev/repo-map.ps1 -Apply` or `/repo-map` | Start of day |
| 2. Code | — | During the day |
| 3. Fast verify | `pwsh scripts/verify-fast.ps1` or `/verify --fast-only` | Before each commit (~5s) |
| 4. Full verify | `pwsh scripts/verify.ps1` or `/verify` | Before finishing a task (~15s) |
| 5. End-of-day wrap-up | `/eod` | End of day |

## 3-Mode Contract

| Mode | AWS Calls | Set via |
|------|-----------|---------|
| `offline` | None — stub LLM/retrieval | `. ./scripts/env/use-env.ps1 -Mode offline` |
| `local-live` | Real Bedrock + DynamoDB + OpenSearch | `. ./scripts/env/use-env.ps1 -Mode local-live` |
| `prod` | CI/CD only — never set locally | CI/CD pipeline |

> **Important:** Dot-source the env script (`. ./scripts/env/use-env.ps1`) — running it as a subprocess does not persist environment variables.

---

## Next Steps

Next, use the emitted project assets to finish setup:
- `docs/reference/ENV_VARS.md` — fill environment-variable placeholders and secret ownership notes
- `docs/ops/BRANCH_PROTECTION.md` — record branch protection and required checks
- `docs/architecture/ARCHITECTURE.md` — capture project-specific architecture decisions
- `AGENTS.md`, `CLAUDE.md`, and `CURSOR_RULES.md` — review governance, commands, skills, rules, and hooks
- `scripts/env/use-env.ps1` / `scripts/env/use-env.sh` plus `scripts/verify-fast.ps1` — enter `offline` mode and verify the local setup
{% if include_e2e_tests %}
- `docs/testing-e2e.md` — Playwright browser testing is included; run `pwsh scripts/e2e-install.ps1` (or `bash scripts/e2e-install.sh`) to download browsers, then `pwsh scripts/e2e-test.ps1` to confirm the setup
{% endif %}
