# Lessons Learned — Critical

**Purpose:** Records issues that caused (or could have caused) a production incident,
security exposure, data loss, CI bypass, or runaway cost. Entries here are **mandatory**
when a fix prevents recurrence of a high-severity problem.

**When to write here:**
- A bug, misconfiguration, or oversight reached (or nearly reached) production.
- A secret, credential, or sensitive value was accidentally exposed or nearly committed.
- A CI gate was bypassed or silently skipped.
- An action caused data loss or corruption, or had the potential to.
- An LLM call ran unthrottled or consumed unexpectedly high cost.
- A security control was disabled or circumvented — even temporarily.

**Entry format:**

---

### YYYY-MM-DD — Short Title

**Symptom:** What was observed (error message, alert, unexpected behavior).
**Root cause:** Why it happened.
**Fix:** What was changed to resolve it.
**Prevention:** What to do next time to avoid this entirely.
**Links:** (optional) PR number, issue, commit SHA, or file path.
**Promoted to:** `—` until promoted, then e.g. `start_up_prompt.md §Phase 2 CI checklist` — brief description (YYYY-MM-DD)

---

> **Never include secrets, tokens, API keys, passwords, or connection strings in this
> file. Redact all sensitive values (e.g., write `REDACTED` or `***`).**

---

## Entries

### 2026-01-15 — Gitleaks 403 on Org Repo PRs

**Symptom:** CI `secret-scan` job failed with HTTP 403 on every pull request in an
organization-owned repository. The `gitleaks-action` step exited non-zero, blocking
merges.
**Root cause:** `gitleaks-action` v2 defaults to posting PR review comments, which
requires `pull-requests: write`. The workflow only granted `contents: read` at the
workflow level, causing a 403 from the GitHub API on comment creation.
**Fix:** Added `GITLEAKS_ENABLE_COMMENTS: "false"` to the gitleaks step env block, and
added `pull-requests: read` to the job-level permissions block. The action still needs
`pull-requests: read` to enumerate PR commits even when commenting is disabled.
**Prevention:** When adding gitleaks to any new workflow always set
`GITLEAKS_ENABLE_COMMENTS: "false"` and add `pull-requests: read` to job permissions.
Never assume the default workflow token has write permissions on org repos.
**Links:** `.github/workflows/ci.yml`, `.github/workflows/security.yml`
**Promoted to:** —

<!-- Add project-specific lessons below. See continue.md §6.6 for the full workflow. -->
