# Lessons Learned — Notable

**Purpose:** Records bugs, integration surprises, and workflow friction that were
non-trivial to diagnose or that would benefit the next developer. Not production-critical,
but worth documenting to save repeated debugging time.

**When to write here:**
- A bug took more than 30 minutes to diagnose.
- An API, library, or tool behaved differently than the documentation described.
- A configuration detail caused unexpected behavior that wasn't obvious from the docs.
- A workflow step was consistently tripping people up.
- An assumption turned out to be wrong in a way others are likely to repeat.

**Entry format:**

---

### YYYY-MM-DD — Short Title

**Symptom:** What was observed (error, incorrect output, confusing behavior).
**Root cause:** Why it happened.
**Fix:** What resolved it.
**Prevention:** What to do next time; recommended habit or convention.
**Links:** (optional) PR, issue, commit SHA, or file path.
**Promoted to:** `—` until promoted, then e.g. `AGENTS.md` — brief description (YYYY-MM-DD)

---

> **Never include secrets, tokens, API keys, passwords, or connection strings in this
> file. Redact all sensitive values (e.g., write `REDACTED` or `***`).**

---

## Entries

### YYYY-MM-DD — Example: a generated command referenced the wrong project asset

**Symptom:** A command or workflow note pointed to a file that did not exist in the
generated project, causing confusion during routine development.
**Root cause:** The instruction was copied forward without checking whether the referenced
asset was actually emitted by the scaffold.
**Fix:** Updated the command or document to reference the correct emitted asset and
removed the stale cross-reference.
**Prevention:** When editing scaffold docs or commands, confirm that every referenced
path exists in generated projects and is the canonical place for that guidance.
**Links:** `START_HERE.md`, `.claude/commands/`, `.cursor/commands/`

<!-- Replace the example above with real project-specific lessons as they occur. -->
