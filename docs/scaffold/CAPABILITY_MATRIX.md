# Projectsmith — Capability Matrix

> This matrix maps every scaffold capability to its implementation in each supported IDE.
> AGENTS.md is the canonical source of truth for capability intent.
> Each IDE gets a native translation layer — outcome parity, not file parity.

## Commands

| Capability | AGENTS.md § | Claude Code | Cursor | Copilot (V2) | Antigravity (V2) |
|---|---|---|---|---|---|
| review | Verification | `.claude/commands/review.md` | `.cursor/commands/review.md` | Planned | Planned |
| status | Verification | `.claude/commands/status.md` | `.cursor/commands/status.md` | Planned | Planned |
| verify | Verification | `.claude/commands/verify.md` | `.cursor/commands/verify.md` | Planned | Planned |
| repo-map | Daily Workflow | `.claude/commands/repo-map.md` | `.cursor/commands/repo-map.md` | Planned | Planned |
| eod | Daily Workflow | `.claude/commands/eod.md` | `.cursor/commands/eod.md` | Planned | Planned |
| change-summary | Verification | `.claude/commands/change-summary.md` | `.cursor/commands/change-summary.md` | Planned | Planned |
| init | Bootstrap | `.claude/commands/init.md` | N/A (native asymmetry) | N/A | N/A |

## Roles / Agents

| Capability | AGENTS.md § | Claude Code | Cursor | Copilot (V2) | Antigravity (V2) |
|---|---|---|---|---|---|
| implementer | Task Execution | `.claude/agents/implementer.md` | `.cursor/roles/IMPLEMENTER.md` | Planned | Planned |
| reviewer | Verification | `.claude/agents/code-reviewer.md` | `.cursor/roles/REVIEWER.md` + `REVIEW_CHECKLIST.md` | Planned | Planned |
| refactorer | Refactoring | `.claude/agents/refactorer.md` | `.cursor/roles/REFACTORER.md` | Planned | Planned |
| researcher | Investigation | `.claude/agents/researcher.md` | `.cursor/roles/RESEARCHER.md` | Planned | Planned |
| architect | Design | `.claude/agents/architect.md` | `.cursor/roles/ARCHITECT.md` | Planned | Planned |
| test-runner | Testing | `.claude/agents/test-runner.md` | N/A (native asymmetry) | N/A | N/A |

## Rules / Standards

| Capability | AGENTS.md § | Claude Code | Cursor | Copilot (V2) | Antigravity (V2) |
|---|---|---|---|---|---|
| Coding standards | Non-negotiables | Via AGENTS.md + CLAUDE.md | `.cursor/rules/core.mdc` | Via AGENTS.md | Via AGENTS.md |
| Executor workflow | Task Execution | Via AGENTS.md + CLAUDE.md | `.cursor/rules/executor.mdc` | Via AGENTS.md | Via AGENTS.md |
| Testing conventions | Testing | Via AGENTS.md | `.cursor/rules/testing.mdc` | Via AGENTS.md | Via AGENTS.md |
| Refactoring method | Refactoring | Via AGENTS.md | `.cursor/rules/refactoring.mdc` | Via AGENTS.md | Via AGENTS.md |
| Backend patterns | API Development | Via AGENTS.md | `.cursor/rules/backend.mdc` (optional) | Via AGENTS.md | Via AGENTS.md |
| Frontend patterns | Frontend | Via AGENTS.md | `.cursor/rules/frontend.mdc` (optional) | Via AGENTS.md | Via AGENTS.md |
| LLM routing | LLM Integration | Via AGENTS.md | `.cursor/rules/llm-routing.mdc` (optional) | Via AGENTS.md | Via AGENTS.md |

## Shared Resources (accessible to all tools)

| Resource | Location | Purpose |
|---|---|---|
| Prompt templates | `.cursor/prompts/*.md` | Task packets, PR summaries, bug reports, env var additions |
| Handoff template | `.cursor/roles/HANDOFF_NOTE_TEMPLATE.md` | Session handoff notes |
| Review checklist | `.cursor/roles/REVIEW_CHECKLIST.md` | Comprehensive review criteria |
| Workflow scripts | `scripts/dev/*.ps1` | Underlying automation (repo-map, eod-triage, doc-sync, add-lesson) |
| Verify scripts | `scripts/verify*.ps1`, `scripts/verify*.sh` | Lint + typecheck + test gates |

## Native Asymmetries (tool-specific, not portability gaps)

| Capability | Tool | Location | Why Not Portable |
|---|---|---|---|
| PostToolUse lint hook | Claude Code | `.claude/hooks/lint-python.ps1` | Cursor has no hook system |
| Permission model | Claude Code | `.claude/settings.json` | Cursor uses IDE-managed permissions |
| Auto-attached rules | Cursor | `.cursor/rules/*.mdc` | Claude uses AGENTS.md + CLAUDE.md for equivalent guidance |
| Repo-map skill | Claude Code | `.claude/skills/repo-map/SKILL.md` | Cursor skills are beta/unreliable |

## V2 Integration Points (Planned)

| IDE | Instructions File | Agents | Skills | Commands/Workflows |
|---|---|---|---|---|
| GitHub Copilot | `.github/copilot-instructions.md` | `.github/agents/*.agent.md` | `.github/skills/*/SKILL.md` | Via agent definitions |
| Google Antigravity | `GEMINI.md` + `.agent/rules/*.md` | Via skills | Skills (progressive disclosure) | `.agent/workflows/*.md` |

---
*This matrix is the audit artifact for parity. If AGENTS.md defines a capability, it must appear in this matrix with implementations for all V1 IDEs.*
