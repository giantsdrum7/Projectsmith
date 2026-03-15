# Bootstrap Provenance Report

**Generated:** 2026-03-15
**Source:** `c:\Projects\HopeAI`
**Target:** `c:\Projects\Projectsmith`

---

## 1. Bootstrap Location

Projectsmith was created as a **sibling directory** to the HopeAI repository at `c:\Projects\Projectsmith`. The workspace environment permitted writing outside the HopeAI repo root.

No HopeAI files were modified, moved, renamed, or deleted.

---

## 2. Files Copied

### 3A — Root governance files (9 files)

| Source Path | Destination Path |
|---|---|
| `AGENTS.md` | `template/{{project_slug}}/AGENTS.md` |
| `CLAUDE.md` | `template/{{project_slug}}/CLAUDE.md` |
| `CURSOR_RULES.md` | `template/{{project_slug}}/CURSOR_RULES.md` |
| `START_HERE.md` | `template/{{project_slug}}/START_HERE.md` |
| `CODEOWNERS` | `template/{{project_slug}}/CODEOWNERS` |
| `.pre-commit-config.yaml` | `template/{{project_slug}}/.pre-commit-config.yaml` |
| `.gitignore` | `template/{{project_slug}}/.gitignore` |
| `.cursorignore` | `template/{{project_slug}}/.cursorignore` |
| `pyproject.toml` | `template/{{project_slug}}/pyproject.toml` |

### 3B — Claude tooling (14 files)

| Source Path | Destination Path |
|---|---|
| `.claude/settings.json` | `template/{{project_slug}}/.claude/settings.json` |
| `.claude/agents/test-runner.md` | `template/{{project_slug}}/.claude/agents/test-runner.md` |
| `.claude/agents/architect.md` | `template/{{project_slug}}/.claude/agents/architect.md` |
| `.claude/agents/researcher.md` | `template/{{project_slug}}/.claude/agents/researcher.md` |
| `.claude/agents/code-reviewer.md` | `template/{{project_slug}}/.claude/agents/code-reviewer.md` |
| `.claude/commands/eod.md` | `template/{{project_slug}}/.claude/commands/eod.md` |
| `.claude/commands/init.md` | `template/{{project_slug}}/.claude/commands/init.md` |
| `.claude/commands/change-summary.md` | `template/{{project_slug}}/.claude/commands/change-summary.md` |
| `.claude/commands/repo-map.md` | `template/{{project_slug}}/.claude/commands/repo-map.md` |
| `.claude/commands/verify.md` | `template/{{project_slug}}/.claude/commands/verify.md` |
| `.claude/commands/status.md` | `template/{{project_slug}}/.claude/commands/status.md` |
| `.claude/commands/review.md` | `template/{{project_slug}}/.claude/commands/review.md` |
| `.claude/hooks/lint-python.ps1` | `template/{{project_slug}}/.claude/hooks/lint-python.ps1` |
| `.claude/skills/repo-map/SKILL.md` | `template/{{project_slug}}/.claude/skills/repo-map/SKILL.md` |

### 3C — Cursor tooling (25 files)

| Source Path | Destination Path |
|---|---|
| `.cursor/rules/backend.mdc` | `template/{{project_slug}}/.cursor/rules/backend.mdc` |
| `.cursor/rules/core.mdc` | `template/{{project_slug}}/.cursor/rules/core.mdc` |
| `.cursor/rules/executor.mdc` | `template/{{project_slug}}/.cursor/rules/executor.mdc` |
| `.cursor/rules/frontend.mdc` | `template/{{project_slug}}/.cursor/rules/frontend.mdc` |
| `.cursor/rules/llm-routing.mdc` | `template/{{project_slug}}/.cursor/rules/llm-routing.mdc` |
| `.cursor/rules/refactoring.mdc` | `template/{{project_slug}}/.cursor/rules/refactoring.mdc` |
| `.cursor/rules/testing.mdc` | `template/{{project_slug}}/.cursor/rules/testing.mdc` |
| `.cursor/roles/IMPLEMENTER.md` | `template/{{project_slug}}/.cursor/roles/IMPLEMENTER.md` |
| `.cursor/roles/REVIEW_CHECKLIST.md` | `template/{{project_slug}}/.cursor/roles/REVIEW_CHECKLIST.md` |
| `.cursor/roles/REVIEWER.md` | `template/{{project_slug}}/.cursor/roles/REVIEWER.md` |
| `.cursor/roles/REFACTORER.md` | `template/{{project_slug}}/.cursor/roles/REFACTORER.md` |
| `.cursor/roles/HANDOFF_NOTE_TEMPLATE.md` | `template/{{project_slug}}/.cursor/roles/HANDOFF_NOTE_TEMPLATE.md` |
| `.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_EOD_DOC_UPDATE.md` |
| `.cursor/prompts/HANDOFF_TASK_PACKET.md` | `template/{{project_slug}}/.cursor/prompts/HANDOFF_TASK_PACKET.md` |
| `.cursor/prompts/TEMPLATE_ADD_ENV_VAR.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_ADD_ENV_VAR.md` |
| `.cursor/prompts/TEMPLATE_PR_SUMMARY.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_PR_SUMMARY.md` |
| `.cursor/prompts/TEMPLATE_LLM_ROUTING_DEBUG.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_LLM_ROUTING_DEBUG.md` |
| `.cursor/prompts/TEMPLATE_INCIDENT_DEBUG.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_INCIDENT_DEBUG.md` |
| `.cursor/prompts/TEMPLATE_BUGFIX.md` | `template/{{project_slug}}/.cursor/prompts/TEMPLATE_BUGFIX.md` |
| `.cursor/prompts/REFACTOR_TASK_PACKET.md` | `template/{{project_slug}}/.cursor/prompts/REFACTOR_TASK_PACKET.md` |
| `.cursor/commands/eod.md` | `template/{{project_slug}}/.cursor/commands/eod.md` |
| `.cursor/commands/review.md` | `template/{{project_slug}}/.cursor/commands/review.md` |
| `.cursor/commands/status.md` | `template/{{project_slug}}/.cursor/commands/status.md` |
| `.cursor/commands/verify.md` | `template/{{project_slug}}/.cursor/commands/verify.md` |
| `.cursor/commands/repo-map.md` | `template/{{project_slug}}/.cursor/commands/repo-map.md` |

### 3D — Scripts (17 files)

| Source Path | Destination Path |
|---|---|
| `scripts/verify.ps1` | `template/{{project_slug}}/scripts/verify.ps1` |
| `scripts/verify-fast.ps1` | `template/{{project_slug}}/scripts/verify-fast.ps1` |
| `scripts/verify.sh` | `template/{{project_slug}}/scripts/verify.sh` |
| `scripts/verify-fast.sh` | `template/{{project_slug}}/scripts/verify-fast.sh` |
| `scripts/dev/prepare_phase2b_corpus.py` | `template/{{project_slug}}/scripts/dev/prepare_phase2b_corpus.py` |
| `scripts/dev/doc-sync.ps1` | `template/{{project_slug}}/scripts/dev/doc-sync.ps1` |
| `scripts/dev/eod-file-triage.ps1` | `template/{{project_slug}}/scripts/dev/eod-file-triage.ps1` |
| `scripts/dev/index-dev-corpus.ps1` | `template/{{project_slug}}/scripts/dev/index-dev-corpus.ps1` |
| `scripts/dev/add-lesson.ps1` | `template/{{project_slug}}/scripts/dev/add-lesson.ps1` |
| `scripts/dev/repo-map.ps1` | `template/{{project_slug}}/scripts/dev/repo-map.ps1` |
| `scripts/dev/README.md` | `template/{{project_slug}}/scripts/dev/README.md` |
| `scripts/env/mode_defaults.json` | `template/{{project_slug}}/scripts/env/mode_defaults.json` |
| `scripts/env/use-env.ps1` | `template/{{project_slug}}/scripts/env/use-env.ps1` |
| `scripts/env/use-env.sh` | `template/{{project_slug}}/scripts/env/use-env.sh` |
| `scripts/env/verify-env-complete.ps1` | `template/{{project_slug}}/scripts/env/verify-env-complete.ps1` |
| `scripts/env/validate_env_hygiene.ps1` | `template/{{project_slug}}/scripts/env/validate_env_hygiene.ps1` |
| `scripts/env/generate_env_templates.py` | `template/{{project_slug}}/scripts/env/generate_env_templates.py` |

### 3E — Docs (5 files)

| Source Path | Destination Path |
|---|---|
| `docs/architecture/ARCHITECTURE.md` | `template/{{project_slug}}/docs/architecture/ARCHITECTURE.md` |
| `docs/planning/OpenQuestions_Risks.md` | `template/{{project_slug}}/docs/planning/OpenQuestions_Risks.md` |
| `docs/reference/ENV_VARS.md` | `template/{{project_slug}}/docs/reference/ENV_VARS.md` |
| `docs/ops/BRANCH_PROTECTION.md` | `template/{{project_slug}}/docs/ops/BRANCH_PROTECTION.md` |
| `docs/refactoring/README.md` | `template/{{project_slug}}/docs/refactoring/README.md` |

### 3F — Config (1 file copied, path transformed)

| Source Path | Destination Path |
|---|---|
| `src/hopeai/config/env_spec.py` | `template/{{project_slug}}/src/{{project_slug}}/config/env_spec.py` |

### 3G — CI workflows (3 files)

| Source Path | Destination Path |
|---|---|
| `.github/workflows/ci.yml` | `template/{{project_slug}}/.github/workflows/ci.yml` |
| `.github/workflows/evals.yml` | `template/{{project_slug}}/.github/workflows/evals.yml` |
| `.github/workflows/security.yml` | `template/{{project_slug}}/.github/workflows/security.yml` |

### 3H — Lessons Learned (3 files)

| Source Path | Destination Path |
|---|---|
| `Lessons_Learned/critical.md` | `template/{{project_slug}}/Lessons_Learned/critical.md` |
| `Lessons_Learned/notable.md` | `template/{{project_slug}}/Lessons_Learned/notable.md` |
| `Lessons_Learned/quality-of-life.md` | `template/{{project_slug}}/Lessons_Learned/quality-of-life.md` |

### 3I — Eval scaffold (3 files)

| Source Path | Destination Path |
|---|---|
| `evals/promptfoo/promptfooconfig.yaml` | `template/{{project_slug}}/evals/promptfoo/promptfooconfig.yaml` |
| `evals/datasets/smoke.jsonl` | `template/{{project_slug}}/evals/datasets/smoke.jsonl` |
| `evals/rubrics/default.md` | `template/{{project_slug}}/evals/rubrics/default.md` |

### 3J — Living template docs (3 files, copied to Projectsmith root)

| Source Path | Destination Path |
|---|---|
| `start_up_guide.md` | `start_up_guide.md` (Projectsmith root) |
| `start_up_prompt.md` | `start_up_prompt.md` (Projectsmith root) |
| `continue.md` | `continue.md` (Projectsmith root) |

**Total files copied from HopeAI: 83**

---

## 3. Files Omitted Intentionally

### HopeAI copier.yaml

| Path | Reason |
|---|---|
| `copier.yaml` | Upstream product config; not part of template tree. A separate placeholder exists at the Projectsmith root. |

### Claude tooling omissions

| Path | Reason |
|---|---|
| `.claude/settings.local.json` | Local override file, not scaffold material |
| `.claude/skills/repo-map/scripts/generate.sh` | Not explicitly listed in copy specification |

### Cursor tooling omissions

| Path | Reason |
|---|---|
| `.cursor/audits/` (~162 files) | Generated audit artifacts, not scaffold material |
| `.cursor/HOPEAI_REPO_MENTAL_MAP_REPORT.md` | Generated project-specific report |
| `.cursor/REVIEWER_REPO_MAP_REPORT.md` | Generated project-specific report |

### Script omissions

| Path | Reason |
|---|---|
| `scripts/preflight_check.py` | Not listed in copy specification |
| `scripts/deploy/create_opensearch_indexes.py` | Project-specific deployment (OpenSearch) |
| `scripts/deploy/generate_runtime_config.py` | Project-specific deployment (runtime config) |
| `scripts/deploy/seed_test_corpus_metadata.py` | Project-specific deployment (test data seeding) |
| `scripts/deploy/setup_s3_bucket.ps1` | Project-specific deployment (S3 infra) |
| `scripts/deploy/seed_runtime_config_secret.ps1` | Project-specific deployment (secrets) |
| `scripts/deploy/post_deploy_verification.ps1` | Project-specific deployment (verification) |
| `scripts/deploy/README.md` | Project-specific deployment documentation |

### Doc omissions

| Path | Reason |
|---|---|
| `docs/planning/ACTIVE_SPRINT.md` | Project-specific sprint tracker |
| `docs/planning/PHASE_1B_PLAN.md` | Project-specific phase plan |
| `docs/planning/EMBEDDING_MODEL_DECISION.md` | Project-specific decision record |
| `docs/ops/LOCAL_LIVE_SETUP.md` | Project-specific local setup guide |
| `docs/ops/RUNBOOK_INCIDENTS.md` | Project-specific ops runbook |
| `docs/ops/RUNBOOK_DEPLOY.md` | Project-specific deployment runbook |
| `docs/reference/EVALS.md` | Not listed in copy specification |
| `docs/reference/SECURITY.md` | Not listed in copy specification |
| `docs/architecture/INTER_AGENT_DATA_FLOW.md` | Project-specific architecture |
| `docs/architecture/DEPLOYMENT_FLOW.md` | Project-specific architecture |
| `docs/architecture/OPENSEARCH_PHASE2_SPEC.md` | Project-specific architecture |

### CI/GitHub omissions

| Path | Reason |
|---|---|
| `.github/workflows/sbom.yml` | Not listed in copy specification |
| `.github/workflows/deploy-workers.yml` | Deployment workflow, not scaffold |
| `.github/workflows/deploy-backend.yml` | Deployment workflow, not scaffold |
| `.github/workflows/deploy-frontend.yml` | Deployment workflow, not scaffold |
| `.github/pull_request_template.md` | Not listed in copy specification |
| `.github/dependabot.yml` | Not listed in copy specification |

### Source code omissions (all project-specific runtime code)

| Path | Reason |
|---|---|
| `src/hopeai/__init__.py` | Project-specific (only __init__.py stubs created for template path) |
| `src/hopeai/config/__init__.py` | Project-specific |
| `src/hopeai/config/mode.py` | Project-specific runtime config |
| `src/hopeai/config/paths.py` | Project-specific runtime config |
| `src/hopeai/config/runtime_config.py` | Project-specific runtime config |
| `src/hopeai/config/secrets_manager.py` | Project-specific secrets handling |
| `src/hopeai/api/` (6 files) | Project-specific API implementation |
| `src/hopeai/contracts/` (4 files) | Project-specific data contracts |
| `src/hopeai/llm/` (6 files) | Project-specific LLM integration |
| `src/hopeai/tools/` (14 files) | Project-specific tool implementations |
| `src/hopeai/workers/` (6 files) | Project-specific worker implementations |

### Eval omissions

| Path | Reason |
|---|---|
| `evals/retrieval_eval.py` | Project-specific eval runner |
| `evals/datasets/retrieval_goldens.jsonl` | Project-specific golden dataset |
| `evals/datasets/retrieval_goldens_phase2b.jsonl` | Project-specific golden dataset |
| `evals/datasets/offline_corpus.jsonl` | Project-specific corpus data |
| `evals/datasets/README.md` | Not listed in copy specification |
| `evals/results/` (4 files) | Generated eval results |
| `evals/promptfoo/README.md` | Not listed in copy specification |
| `evals/promptfoo/providers/offline_provider.py` | Project-specific eval provider |

### Other root-level omissions

| Path | Reason |
|---|---|
| `README.md` | Project-specific; Projectsmith has its own README |
| `REPO_MAP.md` | Generated status artifact |
| `HopeAI_Architecture_Report_Final.md` | Project-specific architecture report |
| `HopeAI_Architecture_Report_Updated.md` | Project-specific architecture report |
| `HopeAI_chatbot_architecture_audit.md` | Project-specific audit |
| `.aws-profile` | Project-specific AWS config |
| `.aws-region` | Project-specific AWS config |
| `.env.example` | Project-specific env template |
| `.env.local.example` | Project-specific env template |
| `uv.lock` | Dependency lock file, not scaffold |
| `.hopeai/` | Project-specific config directory |
| `tests/` (entire directory) | Project-specific test implementations |
| `apps/` (entire directory) | Project-specific frontend application |
| `infra/` (entire directory) | Project-specific infrastructure code |
| `observability/` (entire directory) | Project-specific observability config |
| `security/` (entire directory) | Project-specific security config |

---

## 4. Files Not Found

All files listed in the copy specification were found in HopeAI. No requested files were missing.

---

## 5. Placeholder Files Created

| File | Purpose |
|---|---|
| `Projectsmith/README.md` | Product-level README |
| `Projectsmith/LICENSE` | MIT license |
| `Projectsmith/.gitignore` | Product-repo gitignore |
| `Projectsmith/copier.yaml` | Copier config placeholder (Workstream 3) |
| `Projectsmith/docs/scaffold/PRODUCT_DESIGN.md` | Product design placeholder |
| `Projectsmith/docs/scaffold/CAPABILITY_MATRIX.md` | Capability matrix placeholder |
| `Projectsmith/docs/scaffold/BOOTSTRAP_PROVENANCE.md` | This provenance report |
| `template/{{project_slug}}/src/{{project_slug}}/__init__.py` | Empty package init |
| `template/{{project_slug}}/src/{{project_slug}}/config/__init__.py` | Empty package init |

### .gitkeep files (13 empty directory placeholders)

| Directory |
|---|
| `template/{{project_slug}}/docs/scaffold/` |
| `template/{{project_slug}}/src/{{project_slug}}/llm/` |
| `template/{{project_slug}}/src/{{project_slug}}/tools/` |
| `template/{{project_slug}}/src/{{project_slug}}/api/` |
| `template/{{project_slug}}/src/{{project_slug}}/workers/` |
| `template/{{project_slug}}/tests/contract/` |
| `template/{{project_slug}}/tests/unit/` |
| `template/{{project_slug}}/tests/integration/` |
| `template/{{project_slug}}/infra/` |
| `template/{{project_slug}}/apps/web/` |
| `template/{{project_slug}}/observability/` |
| `template/{{project_slug}}/security/` |
| `template/{{project_slug}}/scripts/deploy/` |

---

## 6. Structural Observations for Workstream 2

1. **HopeAI-specific references throughout:** AGENTS.md, CLAUDE.md, and CURSOR_RULES.md contain extensive HopeAI project name references, AWS service names (Bedrock, OpenSearch, DynamoDB), and HopeAI-specific architecture descriptions that will need Jinja templating or replacement.

2. **pyproject.toml is HopeAI-specific:** Package name `hopeai`, project-specific dependencies (boto3, opensearch-py, etc.), and HopeAI-specific tool configs. Will need full templating.

3. **env_spec.py references hopeai imports and HopeAI-specific env vars:** The file content was copied exactly but contains `hopeai`-specific variable names and import paths that need templating.

4. **CI workflows reference HopeAI paths and secrets:** `ci.yml`, `evals.yml`, and `security.yml` likely reference `src/hopeai/`, HopeAI-specific secrets, and project-specific deployment targets.

5. **scripts/dev/prepare_phase2b_corpus.py is HopeAI-specific:** This is a project-specific corpus preparation script, not generic scaffold material. Consider removing or replacing in Workstream 2.

6. **scripts/env/mode_defaults.json references HopeAI-specific modes:** Three-mode environment system (offline, local-live, prod) is generic in pattern but may contain HopeAI-specific values.

7. **.cursor/rules/*.mdc contain HopeAI-specific paths:** Rule modules reference `src/hopeai/`, HopeAI-specific API patterns, and project-specific conventions.

8. **CODEOWNERS references HopeAI team:** Will need templating for generated project team.

9. **Lessons_Learned files contain HopeAI-specific lessons:** Content is project-specific and will need to be generalized into template starter content.

10. **evals/promptfoo/promptfooconfig.yaml likely references HopeAI-specific eval targets:** Provider and test configurations are project-specific.

11. **docs/ files are HopeAI-specific:** ARCHITECTURE.md describes the HopeAI system, OpenQuestions_Risks.md contains HopeAI risks, ENV_VARS.md lists HopeAI env vars. All will need generalization.

12. **Missing parity:** No test scaffold templates exist -- only empty placeholder directories. A starter test layout (conftest.py, sample test files) may be needed.

13. **Optional module directories are empty placeholders:** `apps/web/`, `infra/`, `observability/`, `security/` will need Copier conditional inclusion patterns in Workstream 3.

14. **`.github/pull_request_template.md` and `.github/dependabot.yml` were not copied:** These are potentially useful generic scaffold files that could be added in Workstream 2.

15. **`.claude/skills/repo-map/scripts/generate.sh` was not copied:** This companion script to the repo-map SKILL.md may be needed for the skill to function. Consider adding in Workstream 2.

16. **No `.env.example` template was copied:** HopeAI has `.env.example` and `.env.local.example` which are project-specific, but a generic env example template may be needed for scaffold completeness.
