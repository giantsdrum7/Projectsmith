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
**Promoted to:** `—` until promoted, then e.g. `docs/reference/ENV_VARS.md` — brief description (YYYY-MM-DD)

---

> **Never include secrets, tokens, API keys, passwords, or connection strings in this
> file. Redact all sensitive values (e.g., write `REDACTED` or `***`).**

---

## Entries

### YYYY-MM-DD — Example: verify gate caught a risky production-facing change

**Symptom:** A full verification run failed before release because a high-impact change
did not meet the required safety or regression checks.
**Root cause:** The change was larger than expected and one critical guardrail was not
re-checked before handoff.
**Fix:** Updated the affected code or configuration, re-ran the required verification
steps, and documented the missing guardrail in the project docs.
**Prevention:** Treat every production-facing or security-sensitive change as a full
verify candidate, even when the edit looks small at first.
**Links:** `scripts/verify.ps1`, `scripts/verify.sh`

<!-- Replace the example above with real project-specific lessons as they occur. -->
