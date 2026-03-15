# Lessons Learned — Quality of Life

**Purpose:** Records small improvements, tooling tips, and workflow optimizations that
make day-to-day development faster or less frustrating. Low urgency, high future value.

**When to write here:**
- You found a faster or cleaner way to do something routine.
- A tool flag, alias, or script pattern saved significant time.
- A naming convention or structure decision reduced confusion.
- An IDE or AI agent behavior was surprising in a useful (or consistently annoying) way.
- A small change eliminated a class of recurring friction.

**Entry format:**

---

### YYYY-MM-DD — Short Title

**Symptom:** What friction or inefficiency existed.
**Root cause:** Why the friction existed.
**Fix:** What improved it.
**Prevention:** Recommended habit or convention going forward.
**Links:** (optional) file path, docs link.
**Promoted to:** `—` until promoted, then e.g. `CURSOR_RULES.md` — brief description (YYYY-MM-DD)

---

> **Never include secrets, tokens, API keys, passwords, or connection strings in this
> file. Redact all sensitive values (e.g., write `REDACTED` or `***`).**

---

## Entries

### 2026-02-01 — Example: alwaysApply vs. globs Conflict in Cursor Rules

**Symptom:** A `.cursor/rules/*.mdc` file with both `alwaysApply: true` and `globs:`
set was being applied to every file in every prompt, not just files matching the glob
pattern. The intended scope restriction was silently ignored.
**Root cause:** Undocumented Cursor behavior: `alwaysApply: true` overrides `globs:`
entirely. Any rule with `alwaysApply: true` fires on every prompt regardless of the
active file, making the `globs:` field irrelevant when both are present.
**Fix:** Removed `alwaysApply: true` from every rule that also had `globs:`. Rules
intended for specific file patterns use only `globs:`; rules intended for all files use
only `alwaysApply: true`. No rule uses both.
**Prevention:** Never set both `alwaysApply: true` and `globs:` on the same rule. Use
one or the other. This is noted in `CURSOR_RULES.md`.
**Links:** `.cursor/rules/`, `CURSOR_RULES.md`
**Promoted to:** `CURSOR_RULES.md` — added warning note about alwaysApply + globs conflict (2026-02-01)

<!-- Add project-specific lessons below. See continue.md §6.6 for the full workflow. -->
