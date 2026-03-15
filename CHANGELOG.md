# Changelog

All notable changes to Projectsmith will be documented in this file.

## [v0.1.0] — 2026-03-15

### Initial Release

Projectsmith is a Copier template that one-shot generates production-ready AI project scaffolds with full IDE agent support.

**What's included:**

- **Copier template** with 16 configurable variables (project identity, providers, optional modules)
- **Three validated presets:** minimal (provider-agnostic), AI-core (Bedrock + DynamoDB + evals), full-stack (all modules)
- **Claude Code tooling:** 8 commands, 6 agents, PostToolUse lint hook, repo-map skill
- **Cursor tooling:** 7 rules, 7 roles, 8 prompt templates, 6 commands
- **Full capability parity** between Claude Code and Cursor (documented in CAPABILITY_MATRIX.md)
- **Agent-agnostic governance:** AGENTS.md as canonical source of truth, with IDE-native translation layers
- **3-mode environment contract:** offline / local-live / prod with verification gates
- **CI/CD workflows:** lint, type-check, test, eval, security scan (GitHub Actions)
- **Contract tests:** governance file existence, env spec validity, mode defaults, dev/prod guardrails
- **Lessons Learned system** with upstream promotion protocol
- **Template CI:** automated validation of all three presets on every template change
- **Multi-IDE roadmap:** V2 planned for GitHub Copilot and Google Antigravity

**Scaffold derived from:** Battle-tested patterns from the HopeAI project (IDI Consulting), generalized and stripped of all project-specific content.

[v0.1.0]: https://github.com/giantsdrum7/Projectsmith/releases/tag/v0.1.0
