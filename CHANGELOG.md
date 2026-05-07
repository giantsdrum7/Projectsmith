# Changelog

All notable changes to Projectsmith will be documented in this file.

## v1.1.0 — 2026-05-07

### Fixed

- Collapsed the redundant outer `template/{{project_slug}}/` layer; emitted projects are now single-level instead of double-nested (`<project>/<project>/<files>` → `<project>/<files>`).
- Wrapped every multi-mode `defaults` dict in `template/.../config/env_spec.py` to prevent ruff E501 line-length violations when `project_slug` is long enough to push a single-line literal past 120 chars after substitution.

### Added

- `Long-slug` template-CI preset (35-char `project_slug`, AI-core configuration) — locks in the regression net so future single-line dict literals cannot silently break long-slug projects.
- `scripts/dev/test-no-double-nest.ps1` and `.sh` — copier smoke that asserts rendered output never reintroduces the double-nesting layer; wired into `validate-template.yml` as a dedicated `no-double-nest` job.
- `docs/migration/v1.0-to-v1.1.md` — flatten-an-existing-project guide for downstream projects bootstrapped from the nested layout.

### Breaking

- Downstream projects generated from earlier versions have the nested `<project>/<project>/<files>` structure on disk. Running `copier update --vcs-ref=v1.1.0` against such a repo will not auto-collapse the layout. Downstream users must manually flatten per `docs/migration/v1.0-to-v1.1.md` before (or after) updating; otherwise a second `<project_slug>/` directory will appear inside the existing one.

## [Unreleased]

### Changed

- Renamed the `metadata_store` Copier option from `rds-postgres` to `postgres` for clarity.
- Clarified `metadata_store` help text: RDS Data API is Aurora-only; standard RDS PostgreSQL requires connection pooling and cannot use Data API.

### Fixed

- Fixed `metadata_store` propagation into generated scaffold files. Previously, generated projects emitted DynamoDB/OpenSearch env vars, docs, and IaC unconditionally regardless of the selected `metadata_store` value.
- Generated `env_spec.py`, `.env.example`, `mode_defaults.json`, `ENV_VARS.md`, `START_HERE.md`, `AGENTS.md`, Cursor rules, `deps.py`, `Dockerfile`, `docker-compose.yml`, integration tests, `pyproject.toml` extras, CDK stacks, deploy verification, and security/contract docs now branch on `metadata_store`.

### Added

- Added a `postgres` preset to `scripts/dev/validate-template.ps1`.

### Deferred

- First-class Aurora CDK provisioning remains intentionally deferred; the scaffold documents the recommended posture but does not add VPC/RDS/migration resources.
- `postgres` validation in other harnesses beyond `scripts/dev/validate-template.ps1` remains deferred.

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
