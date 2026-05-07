# Branch Protection — {{ project_name }}

## Protected Branches

| Branch | Protection Level | Notes |
|---|---|---|
| `main` | Strict | Production-ready code. No direct pushes. |
| `develop` | Standard | <!-- FILL: If using a develop branch, describe its protection level --> |

---

## Required Checks

All of the following must pass before a PR can merge to `main`:

- [ ] **CI Deterministic** (`ci.yml`) — Lint (`ruff`), type check (`mypy`), unit tests (`pytest`)
- [ ] **Secret Scanning** — No leaked credentials detected
- [ ] **Evaluations** (`evals.yml`) — <!-- FILL: Blocking or non-blocking? Define threshold -->

<!-- FILL: Add any additional required checks (e.g., integration tests, SBOM) -->

---

## Required Reviews

| Rule | Value |
|---|---|
| Minimum approvals | <!-- FILL: e.g., 1 for dev, 2 for main --> |
| Dismiss stale reviews on new push | Yes |
| Require review from CODEOWNERS | <!-- FILL: Yes / No --> |
| Restrict who can dismiss reviews | <!-- FILL: e.g., Team leads only --> |

---

## Merge Strategy

| Setting | Value |
|---|---|
| Allowed merge methods | <!-- FILL: e.g., Squash merge only / Merge commit / Rebase --> |
| Delete branch after merge | Yes |
| Require linear history | <!-- FILL: Yes / No --> |
| Require branches to be up to date | Yes |

---

## Emergency Policy

For critical production fixes when normal review is impractical:

1. <!-- FILL: e.g., Create hotfix branch from main -->
2. <!-- FILL: e.g., Implement minimal fix with tests -->
3. <!-- FILL: e.g., Get verbal approval from tech lead (document in PR) -->
4. <!-- FILL: e.g., Merge with admin override, immediately open follow-up PR for proper review -->
5. <!-- FILL: e.g., Post-mortem within 24 hours -->

> **Warning:** Emergency merges bypass normal protections. Use sparingly and always follow up with a proper review.
