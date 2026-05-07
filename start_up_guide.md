start_up_guide.md — Full AI Project Scaffold Initialization Guide (AWS + Python + GitHub)
Purpose

This guide is the repo-root maintenance reference for the Projectsmith Copier template and the scaffold it emits. It is designed so that a Cursor Agent or Claude Code agent can:

Understand the authoritative emitted scaffold source under `template/{{project_slug}}/`.

Update key governance and operational files with high‑quality starter content when the template evolves.

Maintain a standardized workflow: layered governance, 3‑mode contract, staged verification, CI tiers, evaluation harness, daily workflow automation, and security defaults.

Leave "fill‑me" placeholders where repo‑specific details must be added later (architecture, environment variables, run paths, etc.).

This scaffold is AWS‑first (Bedrock for LLMs) and GitHub‑first (CI/CD), but it is structured so that other languages and cloud providers can be added later without breaking the governance system.

How to Use (Human)

New project bootstrap flow (recommended):

Run Copier against this repository to generate a new project from the scaffold source in `template/{{project_slug}}/`.

Copier emits the starter governance and workflow assets automatically. The generated scaffold already includes the current governance model: Planner-Critic-Executor collaboration, the Skills vs Commands vs Rules framework, the Tier A/B/C command model, six Claude skills, and four non-destructive Claude hooks.

After generation, use the emitted project files as the canonical source of truth for day-to-day work: `START_HERE.md`, `AGENTS.md`, `CLAUDE.md`, `CURSOR_RULES.md`, and the docs/scripts shipped in the generated repository.

Use `start_up_prompt.md` from this template repo only as a maintenance prompt for post-generation initialization and template-alignment work. Use `continue.md` from this template repo to maintain the repo-root guidance for credentials, environment setup, and workflow expectations.

Once the generated project's purpose is known, streamline the scaffold (remove unneeded modules) or extend it using the Full modules listed below.

How to Use (Agent)
Required rules for agents

Never paste secrets. Keys, tokens and credentials must not appear in any file. Use placeholders such as REDACTED_ORG_SPECIFIC or {{TEMPLATE_VAR}}.

Treat the files listed in Human‑Only Files (see governance docs) as immutable after initialization—populate them with baseline content only when maintaining or extending the template.

Follow the Phased Initialization Plan below; the default assumption is that Copier has already emitted the baseline scaffold. Stop at the end of each phase to ask the human for approval before proceeding.

Activation methods

Prompt (recommended) – Use start_up_prompt.md. It instructs the agent to follow this guide and complete post-generation initialization in phases.

Skill/Command (optional) – If your toolchain needs an initialization wrapper, keep it emitted-project-native and point it only at assets that exist in generated repositories. Do not depend on these repo-root maintenance docs from emitted project commands.

Applicable When

Use this scaffold when starting any AI‑related project (agentic workflows, RAG, copilots, internal tools, AI‑enabled apps) on AWS with Bedrock LLMs and GitHub for version control & CI/CD. It is appropriate whenever you need standardized governance, safety rules, deterministic verification, and evaluation harness support from day one.

This scaffold is overkill for tiny one‑file prototypes or throwaway scripts; use a much lighter MVP template for those.

Full Scaffold Directory Tree (Target State)

Contract: The agent must create the following tree (or a documented superset). If any item is intentionally skipped, the agent must list it in an Exceptions section at the end of its report.

{{repo}}/
  README.md
  AGENTS.md
  CLAUDE.md
  CURSOR_RULES.md
  START_HERE.md
  REPO_MAP.md

  CODEOWNERS
  .pre‑commit‑config.yaml
  .gitignore
  .cursorignore

  copier.yaml
  .copier‑answers.yml               (generated; gitignored)

  .claude/
    settings.json
    agents/
      code‑reviewer.md
      researcher.md
      architect.md
      test‑runner.md
      implementer.md
      refactorer.md
    commands/
      review.md
      status.md
      verify.md
      repo‑map.md
      eod.md
      change‑summary.md
      init.md                         (optional)
    skills/
      repo‑map/
        SKILL.md
        scripts/
          generate.sh                 (optional helper)

  .agent-config/
    README.md                          (canonical asset convention docs)
    checklists/
      code-review.md                   (single canonical review checklist)

  .cursor/
    rules/
      core.mdc
      testing.mdc
      executor.mdc
      refactoring.mdc
      llm‑routing.mdc             (optional in full scaffold)
      backend.mdc                 (optional in full scaffold; FUTURE banner)
      frontend.mdc                (optional in full scaffold; FUTURE banner)
    roles/
      IMPLEMENTER.md
      REVIEWER.md
      REVIEW_CHECKLIST.md          (redirects to .agent-config/checklists/code-review.md)
      REFACTORER.md
      HANDOFF_NOTE_TEMPLATE.md
      RESEARCHER.md
      ARCHITECT.md
    prompts/
      HANDOFF_TASK_PACKET.md
      REFACTOR_TASK_PACKET.md
      TEMPLATE_PR_SUMMARY.md
      TEMPLATE_BUGFIX.md
      TEMPLATE_ADD_ENV_VAR.md
      TEMPLATE_INCIDENT_DEBUG.md
      TEMPLATE_LLM_ROUTING_DEBUG.md   (optional)
    commands/
      repo‑map.md
      verify.md
      eod.md
      review.md
      status.md
      change‑summary.md
    skills/
      scaffold‑init/SKILL.md         (optional)
      docs‑cleanup/SKILL.md          (optional)
    archive/                          (historical artifacts; .gitkeep)
    audits/                           (gitignored; proof bundle output)
    baseline_test_out/                (empty, for outputs)
    last‑verify‑failure.txt           (gitignored)

  docs/
    architecture/
      ARCHITECTURE.md
      DEPLOYMENT_FLOW.md            (starter)
      INTER_AGENT_DATA_FLOW.md      (starter)
    planning/
      OpenQuestions_Risks.md
      ACTIVE_SPRINT.md              (starter)
    ops/
      BRANCH_PROTECTION.md
      RUNBOOK_DEPLOY.md             (starter)
      RUNBOOK_INCIDENTS.md          (starter)
    reference/
      ENV_VARS.md
      SECURITY.md                   (starter)
      EVALS.md                      (starter)
    refactoring/
      README.md

  src/
    {{project_slug}}/
      __init__.py
      config/
        env_spec.py
        mode.py
        secrets_manager.py
        runtime_config.py
        paths.py                       (optional)
      llm/
        llm_factory.py
        bedrock_client.py
      tools/
        __init__.py
      api/
        __init__.py                    (optional)
        server.py                      (optional)
      workers/
        __init__.py                    (optional)

  apps/
    api/                              (optional)
    workers/                          (optional)
    web/                              (optional)

  infra/
    README.md
    cdk/ or terraform/                (optional)
    params/

  observability/
    README.md
    otel/
    dashboards/

  security/
    README.md
    owasp‑llm‑controls.md
    secrets‑policy.md
    redaction‑config.yaml

  tests/
    conftest.py
    contract/
      test_env_parity.py
      test_env_spec_drift.py
      test_dev_prod_guardrails.py
      test_human_only_files.py
    unit/
    integration/                      (optional)

  evals/
    promptfoo/
      promptfooconfig.yaml
      README.md
    datasets/
      smoke.jsonl
      README.md
    rubrics/
      default.md

  scripts/
    verify.ps1
    verify-fast.ps1
    verify.sh
    verify-fast.sh
    preflight_check.py                (recommended)
    env/
      use-env.ps1                    (authoritative)
      use-env.sh
      mode_defaults.json             (generated)
      generate_env_templates.py
      validate_env_hygiene.ps1        (starter)
      verify-env-complete.ps1         (starter)
    deploy/
      README.md
      setup_s3_bucket.ps1             (starter)
      seed_runtime_config_secret.ps1  (starter)
      post_deploy_verification.ps1    (starter)
    dev/
      README.md
      repo‑map.ps1                    (workflow: update Repo_Map.md)
      eod‑file‑triage.ps1             (workflow: end‑of‑day file organizer)
      doc‑sync.ps1                    (workflow: end‑of‑day doc drift check)
      add‑lesson.ps1                  (workflow: append lesson to Lessons_Learned/)

  .github/
    workflows/
      ci.yml
      evals.yml
      security.yml
      deploy-backend.yml            (starter)
      deploy-workers.yml            (starter)
      deploy-frontend.yml           (starter)
      sbom.yml                      (starter)
    dependabot.yml
    pull_request_template.md

  Lessons_Learned/
    critical.md                       (required: production/security/CI incidents)
    notable.md                        (recommended: non-trivial bugs, API surprises)
    quality-of-life.md                (optional: workflow improvements, tooling tips)

  pyproject.toml
  uv.lock                            (generated by human after all phases complete — do NOT create during scaffolding)
  .env.example                       (generated)
  .env.local.example

Workflow Automation Architecture (Scripts‑First, Wrappers‑Second)

The scaffold includes a daily workflow automation system based on the principle: deterministic PowerShell scripts are the source of truth; Claude Code commands and Cursor commands are thin wrappers that invoke them.

The scripts live in scripts/dev/ and support a standard interface:

--dry-run (default for anything that modifies files)

--apply (explicit opt-in to execute changes)

--out <dir> (proof bundle output directory; default: .cursor/audits/<action>/<date>/<timestamp>/)

--format json|text (json for tooling, text for humans)

Proof bundles are written to .cursor/audits/ (gitignored) and include: meta.json (git SHA, branch, timestamp, args), stdout.txt, stderr.txt, summary.md, and action-specific files (plan.json, proposed.patch).

Each Claude Code command in .claude/commands/ and each Cursor command in .cursor/commands/ invokes the corresponding script and formats the output. This makes the system testable, debuggable, and portable across tooling changes.

Phased Initialization Plan
Phase 1 — Governance + Structure Skeleton

Goal: Create directories and top‑level governance documents without requiring cloud credentials.

Steps:

Create every folder and file in the Full Scaffold tree above. If you choose to omit optional modules (apps/, infra/, observability/, security/), leave a note in your exceptions report.

Populate governance documents with high‑quality starter content:

AGENTS.md — portable rules (Part 1: Universal Governance) and project-specific context (Part 2: Project-Specific). Part 1 covers non-negotiables, verification gates, allowed/forbidden operations, human-only file protocol, daily workflow, proof bundles, lessons learned, script interface, task handoff roles, artifact lifecycle, shared canonical asset conventions, and archive convention. Part 2 uses {{FILL}} placeholders for project identity, architecture, infrastructure, and team model. This file serves as the cross‑tool instruction standard (compatible with Cursor, Codex, Gemini CLI, GitHub Copilot, and others under the Linux Foundation AAIF).

CLAUDE.md — Claude Code specifics: commands (review, status, verify, repo‑map, eod‑triage, doc‑check, change‑summary), agent definitions, hook configuration, safety restrictions. Include a pointer to AGENTS.md for portable rules (e.g., "See @AGENTS.md for universal project instructions").

CURSOR_RULES.md — thin index that references .cursor/rules/ modules and lists high‑level patterns. Note: use only flat .mdc files in .cursor/rules/ (the RULE.md folder format has known reliability issues).

.cursor/rules/*.mdc — copy core.mdc, testing.mdc, executor.mdc, refactoring.mdc; optionally include llm‑routing.mdc, backend.mdc, frontend.mdc. Each rule file uses YAML frontmatter with description, globs, and alwaysApply fields. Important: do not set both alwaysApply: true and globs: on the same rule (alwaysApply silently overrides globs).

.agent-config/README.md — documents the canonical-asset-vs-tool-native principle and the "reference, never duplicate" convention.

.agent-config/checklists/code-review.md — the single canonical review checklist (~28 items across 6 categories). Tool-specific files (.claude/agents/code-reviewer.md, .cursor/roles/REVIEW_CHECKLIST.md) reference this file instead of maintaining separate copies.

.cursor/roles/*.md — implementer, reviewer, refactorer, checklist (redirects to canonical), handoff template.

.cursor/prompts/* — handoff packet, refactor packet, PR summary, bug fix, add env var, incident debug. Include placeholders for repo‑specific details.

.cursor/commands/* — Cursor command wrappers that mirror the Claude Code commands: repo‑map.md, verify.md, eod.md. Each wrapper invokes the corresponding scripts/dev/ script and presents results.

.claude/settings.json — allow/deny command lists; default model; agent‑team flag. Optionally include a PostToolUse lint hook (non‑blocking) that runs ruff check on Python files after edits. Hooks should only be used for logging and feedback, never auto‑apply behavior.

  Required format details:
  - permissions.allow/deny entries must use the pattern `Bash(subcommand *)` (e.g., `"Bash(git status *)"`, `"Bash(ruff check *)"`) — bare verb strings are silently invalid.
  - hooks[].matcher must be a regex string (e.g., `"Edit|Write"`) — not an object. Hooks receive JSON context via stdin; use a wrapper script to parse `tool_input.file_path`.
  - env block values must be strings (`"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` to enable agent teams).
  - Add `"$schema": "https://json.schemastore.org/claude-code-settings.json"` to enable IDE validation.
  - Set model to `claude-opus-4-7` for consistent agent reasoning quality.

.claude/agents/* — baseline definitions for code reviewer, researcher, architect, test runner. Each agent file uses YAML frontmatter (name, description, tools, model) and specifies the agent's role, invocation trigger, and checklist. Valid tool names: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebSearch`, `WebFetch` — do not use `Shell` (not a valid tool name).

.claude/commands/* — slash commands for /review, /status, /verify, /repo‑map, /eod, /change‑summary. The workflow commands (/repo‑map, /eod) should invoke the corresponding scripts/dev/ scripts. The /eod command consolidates file triage (eod‑file‑triage.ps1) and doc drift checking (doc‑sync.ps1) into a single end‑of‑day sequence. Commands use $ARGUMENTS for parameters and !`backtick` syntax for preprocessing context.

.claude/skills/repo‑map/SKILL.md — skill definition for the repo map generator. Use disable‑model‑invocation: true (manual invocation only) for safety. Define allowed‑tools and argument‑hint in YAML frontmatter.

Seed living docs:

REPO_MAP.md — create headings with AUTO markers for agent‑updatable sections and HUMAN markers for hand‑maintained sections. Use <!-- AUTO:START:section_name --> and <!-- AUTO:END:section_name --> delimiters around sections that the /repo‑map command will update. Use <!-- HUMAN --> markers for sections that agents must not overwrite. Include placeholder tokens ({{FILL: description}}) inside AUTO sections. Headings should include: Purpose & invariants (HUMAN), Repo tree (AUTO), Entry points (AUTO), How to run locally (AUTO), Environments & modes (AUTO), Verification (AUTO), Key constraints (HUMAN), Notes & decisions (HUMAN).

docs/architecture/ARCHITECTURE.md — headings: Entry Points, Data Flow, Key Modules, Invariants. Include placeholders to fill later.

docs/planning/OpenQuestions_Risks.md — include legend and create empty sections for each area (e.g., Architecture, Data, Infrastructure, Security).

docs/reference/ENV_VARS.md — include "Generated vs Hand‑Edited Contract" description and placeholders for categories.

docs/ops/BRANCH_PROTECTION.md — include recommended sections (protected branches, required checks, required reviews, merge strategy, emergency policy).

docs/refactoring/README.md — short introduction to the 6‑phase Mikado refactoring method.

Create hygiene files:

.gitignore (include .cursor/audits/, .cursor/last‑verify‑failure.txt, .copier‑answers.yml, .claude/settings.local.json), .cursorignore, .pre‑commit‑config.yaml (with secret scanning hooks), CODEOWNERS, .github/pull_request_template.md, .github/dependabot.yml.

Provide empty pyproject.toml or skeleton with comments (human‑only file but included at template stage). Do NOT create uv.lock — it must be generated by the human after all three phases are complete by running: uv venv, then uv lock, then uv sync.

Stop after Phase 1. Provide a summary of what was created and ask the human if Phase 2 should proceed.

Phase 2 — Environment & Modes + CI Tiers + Eval Harness + Workflow Scripts

Goal: Add environment configuration skeleton, verification scripts, workflow automation scripts, evaluation harness, and CI definitions.

Steps:

Implement src/{{project_slug}}/config/env_spec.py skeleton (~60 variables). Include categories (mode, AWS, database, S3, logging, timeouts, features), with placeholder values and descriptions. Do not include real secrets. The database category should describe the project's chosen metadata store (e.g., DynamoDB); do not scaffold Supabase env vars unless the project specifically uses Supabase.

  Coding requirements for env_spec.py (enforced by ruff):
  - Use enum.StrEnum for string enums: class Category(enum.StrEnum) and class Mode(enum.StrEnum). Do NOT use class X(str, enum.Enum) — ruff UP042 flags this pattern.
  - Keep defaults dict arguments within the line-length limit (120 chars). When three mode keys plus values would exceed the limit, break the dict onto multiple lines (ruff E501).

Add scripts/env/use‑env.ps1 (authoritative) and use‑env.sh with offline/local‑live/prod parameters. Use placeholders for bucket names, secrets prefixes and mode defaults. Create scripts/env/generate_env_templates.py as a placeholder script that will generate mode_defaults.json and .env.example from env_spec.py.

Add verification scripts:

scripts/verify.ps1 & verify-fast.ps1 for Windows

scripts/verify.sh & verify-fast.sh for Unix/Linux/WSL
Each script runs ruff check + ruff format --check + mypy + (for full verify) pytest; each writes failure logs to .cursor/last-verify-failure.txt.
Include empty tests/conftest.py, tests/contract/, tests/unit/ and tests/integration/ directories as placeholders.

Add workflow automation scripts (scripts-first pattern):

scripts/dev/repo‑map.ps1 — generates/updates Repo_Map.md. Runs tree (excluding noise directories), extracts entry points from pyproject.toml, captures recent git activity. Updates only content inside AUTO markers in Repo_Map.md; never overwrites HUMAN sections. Supports --dry-run (default) and --apply. Writes proof bundle to .cursor/audits/repo‑map/.

scripts/dev/eod‑file‑triage.ps1 — end-of-day file organizer. Scans git status and find for untracked/misplaced files. Produces a move-plan table. Dry-run by default; only moves on --apply with explicit confirmation. Uses git mv for tracked files. Never moves protected files (CLAUDE.md, README.md, pyproject.toml, *.toml, *.cfg, *.ini in root, human-only files). Never creates new folders. Never deletes. Writes proof bundle to .cursor/audits/eod-triage/. Invoked as Step 1 of the /eod command.

scripts/dev/doc‑sync.ps1 — end-of-day doc drift check. Builds candidate doc list from today's changed .py files (via git log --since). Compares function signatures and module references against existing docs. Outputs a prioritized drift report with patch suggestions. Propose-only by default (never auto-applies changes). Writes proof bundle to .cursor/audits/doc-check/. Invoked as Step 2 of the /eod command.

scripts/dev/README.md — describes the workflow scripts, their standard interface (--dry-run, --apply, --out, --format), and the proof bundle convention.

scripts/dev/add-lesson.ps1 — non-interactive helper that appends a dated, structured entry to the appropriate Lessons_Learned/<category>.md file. Parameters: -Category (critical|notable|quality-of-life), -Title (required), plus optional -Symptom, -RootCause, -Fix, -Prevention, -Links. Creates the folder and file if missing. Never reads or outputs secrets.

Lessons_Learned/ — three Markdown files (critical.md, notable.md, quality-of-life.md) with entry templates and one example entry each. Populated by add-lesson.ps1 or by hand. The EOD triage script (eod-file-triage.ps1) prints a reminder and example add-lesson.ps1 usage line after every run. See continue.md section 6.6 for the full workflow.

Create evaluation harness scaffold:

evals/promptfoo/promptfooconfig.yaml — minimal sample with stub provider and simple assertions.

evals/datasets/smoke.jsonl — minimal dataset sample.

evals/rubrics/default.md — description of rubric (e.g., "response must contain greeting").

Add GitHub workflows:

.github/workflows/ci.yml — run ruff check + ruff format --check + mypy + pytest + secret scan on push/PR; allow placeholders for secret names.

  CI correctness requirements (enforced from Phase 2):
  - Dev deps must be in [dependency-groups].dev in pyproject.toml (ruff, mypy, pytest, pytest-cov). Do NOT use [project.optional-dependencies] for dev tools — uv sync --dev installs dependency-groups, not extras.
  - Install step must be: uv sync --dev --frozen — this installs exactly the locked versions and fails loudly if pyproject.toml and uv.lock are out of sync.
  - Use astral-sh/setup-uv@v4 with python-version: input instead of a separate "uv python install" step.
  - Set permissions: contents: read at the workflow level.

.github/workflows/evals.yml — run promptfoo on changes to prompt or config files; set thresholds and treat failures as warnings or blockers (use placeholders).

.github/workflows/security.yml — weekly deep secret scan using trufflehog or gitleaks with placeholder parameters.

  Gitleaks requirements (enforced from Phase 2):
  - Set permissions: contents: read at the workflow level (no write access needed).
  - On the gitleaks job specifically, also declare pull-requests: read. gitleaks-action enumerates PR commits to scope its scan even when PR commenting is disabled; without this permission the action returns 403 on org repos.
  - Set GITLEAKS_ENABLE_COMMENTS: "false" in the env block of every gitleaks step. The default (true) posts PR review comments via pulls.createReviewComment, which requires pull-requests: write. Without this flag, gitleaks fails with 403 on repos where the default workflow token is read-only.
  - For organisation-owned repos a free license key is required (obtain at gitleaks.io and store as GITLEAKS_LICENSE secret). Personal account repos do not need a license.
  - Always set fetch-depth: 0 on the checkout step so gitleaks can inspect commit history.

Optionally include placeholders for deploy-backend.yml, deploy-workers.yml, deploy-frontend.yml, sbom.yml.

Optionally create preflight_check.py (recommended) to validate environment variables, region lock, and tool contracts before running the application.

Stop after Phase 2. Provide a summary and ask the human if Phase 3 should proceed.

Phase 3 — Full Modules & Runbooks & Optional Infrastructure

Goal: Add stubs for advanced modules that may not be needed by all projects but should be available to expand later.

Steps:

Create empty or skeleton directories for apps/, infra/, observability/, and security/ along with README.md files explaining when to use them.

Populate scripts/deploy/ with stub scripts:

setup_s3_bucket.ps1 — placeholder instructions for bucket creation with versioning, encryption and lifecycle rules.

seed_runtime_config_secret.ps1 — placeholder script that uploads a JSON file of env vars to Secrets Manager.

post_deploy_verification.ps1 — placeholder script to perform smoke tests after deployment (e.g., /healthz, Bedrock connectivity).

README.md — describe how to use these deploy scripts.

Add runbooks:

docs/ops/RUNBOOK_DEPLOY.md — instructions for performing deployments, referencing scripts.

docs/ops/RUNBOOK_INCIDENTS.md — instructions for triaging incidents, referencing log locations and escalation contacts.

Stop after Phase 3. Provide a final summary and "What to fill next." Ready for project‑specific work.

"Fill‑Me" Sections (To Be Completed Later)

The following files must include placeholders that a future agent can fill based on the actual repository contents:

REPO_MAP.md — create headings with AUTO/HUMAN markers. AUTO sections use <!-- AUTO:START:section_name --> and <!-- AUTO:END:section_name --> delimiters and contain {{FILL: description}} placeholders that the /repo‑map command will populate. HUMAN sections are hand‑maintained. Sections: Purpose & invariants (HUMAN), Repo tree (AUTO), Entry points (AUTO), How to run locally (AUTO), Environments & modes (AUTO), Verification (AUTO), Key constraints (HUMAN), Notes & decisions (HUMAN).

docs/architecture/ARCHITECTURE.md — include sections (Entry Points, Data Flow, Key Modules, Invariants). Use <!-- FILL: description --> for multi‑paragraph sections.

docs/reference/ENV_VARS.md — include a "Generated vs Hand‑Edited Contract" pattern and placeholders for each environment variable category.

docs/reference/EVALS.md — describe how promptfoo is run and how thresholds work; leave placeholders for dataset names, rubrics and thresholds.

docs/planning/OpenQuestions_Risks.md — include a legend for statuses (Open, Closed, Mitigated) and create empty numbered sections for Architecture, Infrastructure, Security, Data, Business, etc.

Use this placeholder syntax consistently: {{FILL: description}} for short placeholders and <!-- FILL: description --> for longer sections.

Acceptance Criteria

The agent is successful if:

The full directory tree exists (or exceptions are documented).

Governance layers are created and cross‑link properly (AGENTS.md → CLAUDE.md → CURSOR_RULES.md → .cursor/rules/*.mdc).

3‑mode contract presence is evident across documentation and mode scripts.

Verification scripts and evaluation harness exist with meaningful starter content.

Workflow automation scripts exist in scripts/dev/ with the standard interface (--dry-run, --apply, --out, --format) and corresponding Claude Code and Cursor command wrappers.

REPO_MAP.md uses AUTO/HUMAN markers so the /repo‑map command can update it safely.

Git hygiene files (.gitignore, CODEOWNERS, pre‑commit) are present. .gitignore includes .cursor/audits/ and other ephemeral outputs.

GitHub workflows are created with placeholders for secrets and deploy names.

A summary is provided after each phase.

No secrets or sensitive information is accidentally committed; placeholders are used instead.

Living Template System

The three root template docs work as a coordinated system and are intended to evolve over time. Lessons_Learned/ (populated as issues are resolved) is the input stream; promotions from that stream are how the template improves for future projects and contributors.

Tandem roles:

start_up_guide.md (this file) — Human-facing blueprint. Governs: directory tree, phased initialization, prerequisites, acceptance criteria. Update here when a lesson reveals a better project setup or structure.

start_up_prompt.md — Agent activation prompt. Governs: the exact instructions given to an IDE agent to build the scaffold. Update here when a lesson reveals a missing guardrail, a wrong agent assumption, or a clearer initialization instruction. Must stay in sync with this guide in substance.

continue.md — Daily operations. Governs: connecting to real infrastructure, local dev workflow, verification gates, EOD routine, team onboarding. Update here when a lesson affects ongoing project execution.

These docs must stay coordinated. If you add or remove a file from the directory tree above, also update start_up_prompt.md to mention it during Phase 1 scaffolding. If you add a workflow script to scripts/dev/, also update continue.md section 6 and scripts/dev/README.md.

How to contribute improvements:

1. Log the lesson in the correct Lessons_Learned/ file. See continue.md section 6.7 for the full promotion protocol.

2. Decide the promotion target (see tandem roles above).

3. Apply the minimal additive change to the target doc and add a one-line back-link near the change:
   (see Lessons_Learned/<category>.md — YYYY-MM-DD, "Short title")

Safety rule: never include secrets, tokens, API keys, passwords, or connection strings in lessons or template docs. Redact all sensitive values.

Current Template Reality (Copier & Template Repo)

Projectsmith already is a Copier template repo. In the current setup:

copier.yaml is the authoritative list of variables (project_name, project_slug, aws_region, etc.).

.copier-answers.yml is generated per project, not checked in.

Teams run copier update to pull improvements from the central scaffold repository.

The authoritative scaffold source for emitted projects lives under `template/{{project_slug}}/`. Keep repo-root maintenance docs aligned with that emitted source rather than describing a separate manual copy/bootstrap flow.
