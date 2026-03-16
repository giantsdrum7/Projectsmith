start_up_prompt.md — Scaffold Initialization Prompt (Cursor/Claude)

Copy/paste the text below into Cursor Agent or Claude Code after generating a new project from the Projectsmith Copier template. It directs the agent to read start_up_guide.md and complete post-generation initialization in phases, stopping at checkpoints to ask the human lead before continuing.

To Agent:

You are initializing a newly generated repository from the Projectsmith Copier template (AWS + Bedrock + GitHub).

Rules

Read start_up_guide.md in the repository root and follow it exactly.

No secrets (keys, tokens, credentials) may appear in any file. Use placeholders like REDACTED_ORG_SPECIFIC or {{TEMPLATE_VAR}} whenever a value is unknown or sensitive.

Do not run destructive git commands (no rebase/reset --hard). You may update emitted files, create any missing scaffold assets if generation drift is discovered, add changes to git, and commit locally. Do not push to remote.

If any step is ambiguous, STOP and ask the human lead for clarification.

If you encounter a problem, fix a mistake, or discover that a scaffold file is missing or incorrect, log it in Lessons_Learned/ in the correct category (critical, notable, or quality-of-life) before moving on. This keeps the template system honest.

If the lesson is critical or recurring, also update the appropriate living doc so the template improves for future projects: setup/structure issues go to start_up_guide.md; agent instructions or guardrails go to start_up_prompt.md (this file); daily-workflow issues go to continue.md. Apply only minimal additive changes and add a one-line back-link to the lesson entry: (see Lessons_Learned/<category>.md — YYYY-MM-DD, "Short title").

Task

Finalize the emitted full scaffold (not MVP) described in start_up_guide.md using the Phased Initialization Plan below.

Assume Copier already emitted the baseline scaffold from `template/{{project_slug}}/`. Do not re-create files or directories that are already present. Instead, verify the emitted structure, fill project-specific placeholders, and repair any generation drift you find. The emitted scaffold already includes the current governance baseline: Planner-Critic-Executor governance, the Skills vs Commands vs Rules framework, the Tier A/B/C command model, six Claude skills, and four non-destructive Claude hooks.

Phase 1: Structure & Governance Skeleton

Confirm that the folders and files specified in the "Full Scaffold Directory Tree" section of start_up_guide.md are present in the generated repository. If something expected is missing, create only the missing item and note it in your summary. If you intentionally omit optional modules (apps/, infra/, observability/, security/), make a note in your summary.

Populate governance documents with starter content:

AGENTS.md — Structure as Part 1 (Universal Governance) and Part 2 (Project-Specific Context). Part 1 covers non-negotiables, verification gates, allowed/forbidden operations, human-only file protocol, daily workflow, proof bundles, lessons learned, script interface, task handoff roles, generated artifact lifecycle, shared canonical asset conventions, and archive convention. Part 2 uses {{FILL}} placeholders for project identity, architecture, infrastructure, mode contract specifics, repo-specific conventions, and team collaboration model. This file serves as the cross‑tool instruction standard (compatible with Cursor, Codex, Gemini CLI, GitHub Copilot, and others under the Linux Foundation AAIF).

CLAUDE.md — Claude‑specific: commands (review, status, verify, repo‑map, eod, change‑summary), agent definitions, hook configuration, safety restrictions. Include a pointer to AGENTS.md for portable rules (e.g., "See @AGENTS.md for universal project instructions"). Keep under 150 lines — context budget is real.

CURSOR_RULES.md — Thin adapter/index pointing to .cursor/rules/*.mdc modules and summarizing their scopes (core/testing/executor/refactoring/llm‑routing/backend/frontend). Note: use only flat .mdc files; the RULE.md folder format has known reliability issues.

.cursor/rules/*.mdc — Confirm the emitted baseline rules from the template (core, testing, executor, refactoring). Include optional rule files (llm‑routing, backend, frontend) if appropriate for your organization. Each file uses YAML frontmatter with description, globs, and alwaysApply fields. Important: do not set both alwaysApply: true and globs: on the same rule (alwaysApply silently overrides globs). Rules targeting features not present at scaffold time (e.g., frontend.mdc targeting empty apps/web/, backend.mdc targeting empty src/**/api/) should include a `# FUTURE — This rule activates when [condition]. Not yet applicable.` banner after the frontmatter.

.agent-config/README.md — Confirm that it documents the canonical-asset-vs-tool-native principle and the "reference, never duplicate" convention. This is universal content applicable to any project.

.agent-config/checklists/code-review.md — Confirm that the single canonical review checklist (~28 items across 6 categories: Security, Tests, Code Quality, Documentation, Architecture, Commit Hygiene) is present. Tool-specific files reference this instead of maintaining separate copies.

.cursor/roles/* — Confirm the emitted role definitions (Implementer, Reviewer, Refactorer, Researcher, Architect) and the handoff checklist (redirect to canonical) and note template.

.cursor/prompts/* — Confirm the emitted templates: handoff task packet, refactor task packet, PR summary, bug fix, add env var, incident debug, LLM routing debug.

.cursor/commands/* — Confirm the emitted Cursor command wrappers that mirror the Claude Code workflow commands. Each wrapper invokes the corresponding scripts/dev/ script and presents results:
  repo‑map.md — invokes scripts/dev/repo‑map.ps1
  verify.md — invokes scripts/verify.ps1 or scripts/verify-fast.ps1
  eod.md — full end‑of‑day sequence: invokes eod‑file‑triage.ps1 (Step 1), doc‑sync.ps1 (Step 2), conditional doc/lesson updates (Step 3), and verify (Step 4)
  review.md — review staged/unstaged changes for quality and conventions
  status.md — repository status summary
  change‑summary.md — generate commit/PR summary from git diff

.claude/settings.json — Set allowed and denied commands; configure the model; enable experimental agent teams if needed. Optionally include a PostToolUse lint hook (non‑blocking only — run ruff check on .py files after edits, always exit 0). Hooks should only be used for logging and feedback, never auto‑apply behavior. Include a deny list for destructive operations (git push, git reset --hard, rm -rf).

  Required format details:
  - Set `"$schema": "https://json.schemastore.org/claude-code-settings.json"` for IDE validation.
  - Set model to `claude-opus-4-6`.
  - permissions.allow/deny entries use `Bash(subcommand *)` pattern — e.g., `"Bash(git status *)"`, `"Bash(ruff check *)"`.
  - hooks[].matcher is a regex string (e.g., `"Edit|Write"`) — not an object `{"tools": [...]}`.
  - Hooks receive JSON on stdin; write a wrapper script to parse `tool_input.file_path` rather than using `$TOOL_INPUT_PATH` (not set by Claude Code).
  - env block: `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` enables agent teams (TeammateIdle hook event available).
  - See `.claude/hooks/` for the wrapper script pattern.

.claude/agents/ — Confirm the emitted baseline agent definitions (code‑reviewer, researcher, architect, test‑runner, implementer, refactorer). Each agent file uses YAML frontmatter (name, description, tools, model) and specifies the agent's role, invocation trigger, and checklist.

.claude/commands/ — Confirm the emitted slash command handlers. These are the primary interface for workflow automation:
  review.md — diff checks on staged changes
  status.md — repository status summary
  verify.md — run staged verification (invokes scripts/verify.ps1)
  repo‑map.md — update Repo_Map.md (invokes scripts/dev/repo‑map.ps1)
  eod.md — full end‑of‑day sequence: file triage, doc drift check, conditional doc/lesson updates, verify
  change‑summary.md — generate commit/PR summary from git diff
Commands use $ARGUMENTS for parameters and !`backtick` syntax for preprocessing context. Include allowed-tools in YAML frontmatter. For quality gates like /verify, use explicit invocation (do not rely on skill auto‑invocation).

.claude/skills/repo‑map/SKILL.md — Confirm the emitted skill definition for the repo map generator. Use disable‑model‑invocation: true (manual invocation only) for safety. Include allowed‑tools and argument‑hint in YAML frontmatter. Optionally include a scripts/generate.sh helper.

Confirm living docs have the expected headings and placeholders:

REPO_MAP.md — Create headings with AUTO/HUMAN markers. AUTO sections use <!-- AUTO:START:section_name --> and <!-- AUTO:END:section_name --> delimiters and contain {{FILL: description}} placeholders. HUMAN sections are hand‑maintained and agents must not overwrite them. Include these headings:
  Purpose & invariants (HUMAN)
  Repo tree (AUTO)
  Entry points (AUTO)
  How to run locally (AUTO)
  Environments & modes (AUTO)
  Verification (AUTO)
  Key constraints (HUMAN)
  Notes & decisions (HUMAN)

docs/architecture/ARCHITECTURE.md — Insert sections for Entry Points, Data Flow, Key Modules, Invariants; include <!-- FILL: description --> comments.

docs/planning/OpenQuestions_Risks.md — Insert a legend for statuses (Open/Closed/Mitigated) and create empty sections for Architecture, Infrastructure, Security, Data, Business, etc.

docs/reference/ENV_VARS.md — Insert description of the "Generated vs Hand‑Edited Contract" pattern and create placeholder lists for each category.

docs/ops/BRANCH_PROTECTION.md — Add recommended sections: Protected branches, Required checks, Required reviews, Merge strategy, Emergency policy.

docs/refactoring/README.md — Add a short description of the 6‑phase Mikado refactoring method.

Confirm hygiene and config files are present and correct:

.gitignore (include: .cursor/audits/, .cursor/last‑verify‑failure.txt, .copier‑answers.yml, .claude/settings.local.json, __pycache__/, .venv/, .mypy_cache/, .env), .cursorignore, .pre‑commit‑config.yaml (include secret scanning hooks), CODEOWNERS, .github/pull_request_template.md, .github/dependabot.yml.

Confirm `pyproject.toml` (skeleton) is present. Do NOT create `uv.lock` — it is generated by the human after all three phases are complete by running: `uv venv`, then `uv lock`, then `uv sync`.

Stop after Phase 1 and ask: "Phase 1 complete. Ready for Phase 2?" Do not begin Phase 2 until the human agrees.

Phase 2: Environment & Modes + CI Tiers + Eval Harness + Workflow Scripts

Confirm `src/{{project_slug}}/config/env_spec.py` contains skeleton environment variable definitions (~60 variables). Define categories (mode, AWS, database, S3, logging, timeouts, features) and include placeholder values. Do not include real secrets. The database category should reflect the project's chosen metadata store (e.g., DynamoDB). Do not add Supabase variables unless the project explicitly uses Supabase.

Coding requirements for env_spec.py (enforced by ruff):
- Use enum.StrEnum for string enums: class Category(enum.StrEnum) and class Mode(enum.StrEnum). Do NOT write class X(str, enum.Enum) — ruff UP042 flags this.
- Break defaults dicts onto multiple lines when three mode keys + values would exceed 120 chars (ruff E501). Example:
  defaults={
      Mode.OFFLINE: "value-a",
      Mode.LOCAL_LIVE: "value-b",
      Mode.PROD: "value-c",
  },

Confirm `scripts/env/use‑env.ps1` (authoritative) and `scripts/env/use‑env.sh` are present and implement offline/local‑live/prod modes; include placeholder bucket names, secret prefixes and region (us‑east‑1). Include safety checks (prod mode requires explicit flag; region lock). Confirm `scripts/env/generate_env_templates.py` contains a stub that will generate `mode_defaults.json` and `.env.example` from `env_spec.py`.

Populate verification scripts:

scripts/verify.ps1, verify-fast.ps1 (Windows) and scripts/verify.sh, verify-fast.sh (Unix) with ruff check + ruff format --check + mypy + pytest commands. Use uv for Python execution. Write failures to .cursor/last-verify-failure.txt.

Confirm the workflow automation scripts (scripts-first pattern). Each script supports --dry-run (default), --apply, --out <dir>, and --format json|text:

scripts/dev/repo‑map.ps1 — Generates/updates Repo_Map.md. Runs tree (excluding __pycache__, .git, node_modules, .venv, .mypy_cache), extracts entry points from pyproject.toml [project.scripts], captures recent git activity (git log --oneline -20, git diff --stat HEAD~5..HEAD). Updates only content inside <!-- AUTO:START --> / <!-- AUTO:END --> markers; never overwrites HUMAN sections. Writes proof bundle to .cursor/audits/repo-map/.

scripts/dev/eod‑file‑triage.ps1 — End-of-day file organizer. Scans git status --porcelain for untracked files and find for recently created files. Classifies files against an allowlist (Python source → src/, tests → tests/, docs → docs/, scripts → scripts/, config → leave in root). Produces a move-plan table. Dry-run by default; only moves on --apply with explicit confirmation. Uses git mv for tracked files. Protected files: CLAUDE.md, AGENTS.md, README.md, pyproject.toml, *.toml, *.cfg, *.ini in root, human-only files. Never creates new folders. Never deletes. Writes proof bundle to .cursor/audits/eod-triage/. Invoked as Step 1 of the /eod command.

scripts/dev/doc‑sync.ps1 — End-of-day doc drift check. Gets today's changed .py files via git log --since="1 day ago" --name-only. For each changed file, checks if corresponding docs exist in docs/. Compares function signatures and module references. Flags: signature mismatches, new undocumented public functions, removed functions still referenced in docs. Outputs prioritized drift report with file:line proof pointers and suggested patches. Propose-only by default (never auto-applies). Writes proof bundle to .cursor/audits/doc-check/. Invoked as Step 2 of the /eod command.

scripts/dev/README.md — Describes the workflow scripts, their standard interface, the proof bundle convention, and the daily workflow (start of day → during day → before push → end of day).

Confirm the evaluation harness is present:

evals/promptfoo/promptfooconfig.yaml — Minimal config with stub provider and simple assertions.

evals/datasets/smoke.jsonl — Minimal dataset sample.

evals/rubrics/default.md — Basic rubric description.

Confirm the GitHub workflows are present:

.github/workflows/ci.yml — Lint (ruff check + ruff format --check), type check, unit tests, secret scanning on every push/PR. Use placeholder secret names matching the project's actual services (e.g., BEDROCK_INFERENCE_PROFILE_ARN, DATABASE_SECRET_ARN). Do not scaffold Supabase secret names unless the project specifically uses Supabase.

.github/workflows/evals.yml — Run promptfoo evaluations on changes to prompt or config files. Define threshold and treat failure as blocking or non‑blocking (use placeholders).

.github/workflows/security.yml — Weekly deep secret scan (e.g., trufflehog/gitleaks). Use placeholders for scanning parameters.

Optionally add placeholders for deployment workflows: deploy‑backend.yml, deploy‑workers.yml, deploy‑frontend.yml, sbom.yml.

CI correctness checklist (verify before finishing Phase 2):
- [ ] Dev tools (ruff, mypy, pytest, pytest-cov) are in [dependency-groups].dev in pyproject.toml — NOT in [project.optional-dependencies].
- [ ] CI install step uses: uv sync --dev --frozen (not uv sync --dev).
- [ ] workflows use astral-sh/setup-uv@v4 with python-version: input; no separate "uv python install" step needed.
- [ ] permissions: contents: read is set at workflow level in ci.yml and security.yml.
- [ ] Every gitleaks step sets GITLEAKS_ENABLE_COMMENTS: "false" to prevent 403 errors from PR comment API calls.
- [ ] The gitleaks job declares pull-requests: read in its permissions block (gitleaks-action reads PR commit list even with commenting disabled; without this the action returns 403 on org repos).
- [ ] gitleaks checkout uses fetch-depth: 0.
- [ ] CI passes on first PR without AWS credentials (all LLM calls skipped in offline mode).

Optionally add `preflight_check.py` (recommended) if the generated project needs it to check environment variables, region lock, and tool contracts at runtime.

Stop after Phase 2 and ask: "Phase 2 complete. Ready for Phase 3?" Do not begin Phase 3 until the human agrees.

Phase 3: Full Modules + Runbooks + Optional Infrastructure

If requested, add any missing skeleton directories for optional modules: apps/, infra/, observability/, security/. Include README.md explaining when and how to use each module.

Populate scripts/deploy/ with stub scripts:

setup_s3_bucket.ps1 — Placeholder instructions for bucket creation with versioning, encryption and lifecycle rules.

seed_runtime_config_secret.ps1 — Placeholder script to upload a JSON file of environment variables into Secrets Manager.

post_deploy_verification.ps1 — Placeholder script to perform smoke tests after deployment (health check, Bedrock connectivity).

README.md — Describe how to use these deploy scripts.

Confirm the runbooks are present:

docs/ops/RUNBOOK_DEPLOY.md — Step‑by‑step instructions for deployments.

docs/ops/RUNBOOK_INCIDENTS.md — Triage guidelines for incidents (check logs, isolate region, revert code, contact human ops).

Finish Phase 3. Provide:

A short "What I validated or updated" summary.

Any exceptions (missing modules, differences from the scaffold).

Next steps from continue.md (credentials, secrets, environment setup, and the daily workflow described in section 6.5).

End of prompt.
