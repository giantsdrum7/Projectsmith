# .agent-config/ — Shared Canonical Assets

This directory holds canonical assets shared across all IDE agent tools (Claude Code, Cursor, Codex, GitHub Copilot, etc.).

## Principle: Reference, Never Duplicate

Each asset in `.agent-config/` is the **single source of truth** for its domain. Tool-specific files reference these assets instead of maintaining separate copies.

| Canonical Asset | Referenced By |
|---|---|
| `.agent-config/checklists/code-review.md` | `.claude/agents/code-reviewer.md`, `.cursor/roles/REVIEW_CHECKLIST.md` |

When an asset is updated here, every tool that references it automatically uses the latest version. This eliminates drift between tools.

## What Belongs Here vs Tool-Native Locations

**Belongs in `.agent-config/`:**
- Checklists shared by multiple tools (review checklists, security checklists)
- Canonical reference documents that agents from any tool should follow
- Shared configuration that is tool-agnostic

**Belongs in tool-native locations (`.claude/`, `.cursor/`):**
- Tool-specific configuration (`.claude/settings.json`, `.cursor/rules/*.mdc`)
- Tool-specific command wrappers and agent definitions
- Tool-specific hooks, skills, and prompts

## Relationship to AGENTS.md

`AGENTS.md` Part 1 (Universal Governance) defines the **rules and policies**. Assets in `.agent-config/` provide the **reference materials** that those rules point to.

For example, AGENTS.md says "use the canonical review checklist" and `.agent-config/checklists/code-review.md` is that checklist.

## Adding New Assets

When adding a new canonical asset:
1. Create the file in the appropriate `.agent-config/` subdirectory
2. Update the table above
3. Update all tool-specific files to reference the new asset (instead of inlining content)
4. Add a note in `AGENTS.md` Part 1 under "Shared Canonical Assets" if the asset supports a governance rule
