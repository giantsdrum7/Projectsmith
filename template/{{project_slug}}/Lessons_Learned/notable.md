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
**Promoted to:** `—` until promoted, then e.g. `continue.md §6.5` — brief description (YYYY-MM-DD)

---

> **Never include secrets, tokens, API keys, passwords, or connection strings in this
> file. Redact all sensitive values (e.g., write `REDACTED` or `***`).**

---

## Entries

### 2026-02-28 — Claude Code Settings: Three Silent Schema Errors in settings.json

**Symptom:** VS Code reported a JSON schema error at `.claude/settings.json` line 47 col 20
("Incorrect type. Expected string"). On closer audit, two additional silent errors were also
present: all `permissions` entries used an invalid format ("Git status", "Ruff check", etc.
instead of the required `Bash(...)` pattern), and the hook command used `$TOOL_INPUT_PATH`
which is not a valid Claude Code environment variable.
**Root cause:** Three independent issues: (1) `matcher` was an object (`{"tools": [...]}`) — the
current schema requires a regex string like `"Edit|Write"`; (2) permission rules must match the
pattern `Bash(subcommand *)` or a tool name alone — bare strings like "Git status" silently fail
validation; (3) hooks receive context via stdin as JSON (`.tool_input.file_path`), not via
environment variables — `$TOOL_INPUT_PATH` is never set.
**Fix:** (1) Changed matcher to string `"Edit|Write"`. (2) Rewrote all allow/deny entries to
`Bash(git status *)`, `Bash(ruff check *)` etc. (3) Extracted hook logic to a wrapper script
`.claude/hooks/lint-python.ps1` that reads stdin JSON and invokes `uv run ruff check`.
**Prevention:** Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` to
`.claude/settings.json` to get inline validation in any JSON-schema-aware editor. Always test
hooks with a simulated payload pipe (`echo '{"tool_input":{"file_path":"..."}}' | pwsh hook.ps1`)
before committing.
**Links:** `.claude/settings.json`, `.claude/hooks/lint-python.ps1`
**Promoted to:** `start_up_guide.md §Phase 1` — .claude/settings.json format details (2026-03-15)

### 2026-02-28 — Claude Code Agent Tool Names: "Shell" Is Not Valid

**Symptom:** All four project subagents (`code-reviewer`, `researcher`, `architect`,
`test-runner`) referenced `Shell` in their `tools:` frontmatter. Claude Code does not have a
`Shell` tool — the correct name is `Bash`.
**Root cause:** The original scaffold used "Shell" which is a generic term but not the actual
Claude Code tool identifier. The valid tool names are listed in the official JSON schema at
`$defs.permissionRule.pattern`: Bash, Edit, Glob, Grep, Read, Write, WebFetch, WebSearch, etc.
**Fix:** Replaced `Shell` with `Bash` in all four agent files.
**Prevention:** When writing agent/skill tool lists, cross-reference the permission schema at
`https://json.schemastore.org/claude-code-settings.json` (`$defs.permissionRule.pattern`) for
the authoritative list of valid tool names. Also ensure `$schema` is set in settings.json so
the editor catches unknown tool names inline.
**Links:** `.claude/agents/*.md`
**Promoted to:** `start_up_guide.md §Phase 1` — .claude/agents valid tool names (2026-03-15)

<!-- Add project-specific lessons below. See continue.md §6.6 for the full workflow. -->
