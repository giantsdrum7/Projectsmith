continue.md — How to Begin (Credentials, Cloud Setup, Env, Tools)

This guide is used after the scaffold exists (created via start_up_guide.md and start_up_prompt.md). It explains how to connect your repository to GitHub and AWS, configure environment variables and secrets, and leverage the built‑in agent tooling. The scaffolding is AWS‑first and Python‑centric but leaves room for other clouds or languages by adjusting parameters later.

1) GitHub Setup
1.1 Create & Connect Repository

Initialize git in the project directory:

git init
git add .
git commit -m "Initialize scaffold"
# Add remote (replace with your organization/repo)
git remote add origin https://github.com/<ORG>/<REPO>.git
git branch -M main
git push -u origin main


Configure branch protection (GitHub UI):

Protect the main branch (no direct pushes).

Require pull requests with at least one approval.

Require status checks (CI deterministic, evals, secret scanning) before merge.

Enforce CODEOWNERS for sensitive paths.

Write down your branch protection rules in docs/ops/BRANCH_PROTECTION.md.

1.2 GitHub Actions Credentials

For AWS deployments, prefer OIDC with an IAM Role instead of static keys. Configure a GitHub OIDC provider in AWS, create a role with necessary permissions, and map it to your GitHub repository via workflow configuration. If you cannot set up OIDC immediately, you can temporarily use AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets, but plan to migrate to OIDC.

You may also need other secrets:

Database secrets for your chosen metadata store (e.g., DynamoDB table name and endpoint if not using IAM role discovery; a connection string secret ARN if using RDS). Do not add SUPABASE_URL or SUPABASE_SECRET_KEY unless your project specifically uses Supabase.

BEDROCK_INFERENCE_PROFILE_ARN if using Bedrock inference profiles.

COGNITO_USER_POOL_ID, COGNITO_CLIENT_ID, COGNITO_DOMAIN if enabling a frontend with Cognito authentication.

Additional API keys (e.g., SERPER_API_KEY) as needed.

Store these secrets in GitHub Secrets and reference them in your workflows.

2) AWS Setup
2.1 Region

Default region is us‑east‑1. All resources (Bedrock, Lambda/ECS, S3, Secrets Manager) should use the same region to avoid cross‑region calls and simplify permissions.

2.2 Create Dev & Prod Namespaces

Recommended naming patterns (substitute {{project_slug}}):

Secrets prefixes:

{{project_slug}}/dev/*

{{project_slug}}/prod/*

Buckets:

{{project_slug}}-artifacts-dev

{{project_slug}}-artifacts-prod

ECR repositories:

{{project_slug}}-api

{{project_slug}}-workers

2.3 Bedrock Setup

Ensure your AWS account has Bedrock access enabled in the selected region.

Choose your models (Claude 4.6, etc.) and optionally create inference profiles. Record the profile ARNs in your environment configuration.

Map these ARNs to modes in src/{{project_slug}}/config/env_spec.py and/or Secrets Manager.

Note: Anthropic models on Bedrock require a one-time use case form submission per AWS account before the model is accessible.

3) Secrets Manager + Pointer Config Pattern
3.1 Why Pointer Config Exists

Lambda and other serverless services restrict environment variables (size & number). To avoid storing dozens of variables directly in the Lambda environment, we store them in Secrets Manager and use a small set of "pointer" variables to fetch them at runtime. This reduces cold start times and centralizes configuration management.

3.2 Create Secrets

Create JSON secrets in Secrets Manager with your environment configuration:

{{project_slug}}/dev/all — All variables for local‑live/dev mode.

{{project_slug}}/prod/all — All variables for prod mode.

Optionally {{project_slug}}/prod/runtime_config — Only if splitting runtime config and full environment.

Avoid putting AWS credentials inside these secrets. Use IAM roles and OIDC instead.

When storing service endpoints in secrets or env vars, prefer bare hostnames (e.g., `search-dev.us-east-1.aoss.amazonaws.com`) rather than full URLs with protocol prefix (e.g., `https://search-dev.us-east-1.aoss.amazonaws.com`). Mixing the two often causes malformed double-prefix URLs at runtime.

4) Local Dev Setup
4.1 Python Tools

Install Python 3.12+ and uv (Unified Virtualenv) to manage dependencies. Then initialize the Python environment — this is the first time uv.lock is generated (the agent does not create it during scaffolding):

pipx install uv pre-commit
uv venv
uv lock
uv sync
pre-commit install

4.2 Entering Modes

Use scripts/env/use-env.ps1 (Windows) or use-env.sh (Unix) to set environment variables for the current session. Example:

.\scripts\env\use-env.ps1 -Mode offline


or

./scripts/env/use-env.sh --mode offline


Important: On Windows PowerShell, dot-source the script (`. .\scripts\env\use-env.ps1 -Mode offline`) — running it as a child process does not persist environment variables in your shell session.

Modes:

offline — Stub LLM; no external calls.

local-live — Real Bedrock calls and dev resources.

prod — Use only via CI/CD; never set locally unless strictly necessary.

4.3 Verification Gates

Run verify-fast frequently while developing:

.\scripts\verify-fast.ps1


or

./scripts/verify-fast.sh


Before finishing a task, run the full verification gate:

.\scripts\verify.ps1


or

./scripts/verify.sh


If a verification script fails, read .cursor/last-verify-failure.txt to see what went wrong and fix it before proceeding.

5) CI/CD Workflows
5.1 Setting Secrets for Workflows

Add required secrets in GitHub Settings → Secrets → Actions. Names should match those referenced in your workflows (e.g., BEDROCK_INFERENCE_PROFILE_ARN, DATABASE_SECRET_ARN, COGNITO_USER_POOL_ID, etc.). Use your project's actual secret names — do not add SUPABASE_URL or SUPABASE_SECRET_KEY unless the project explicitly uses Supabase.

5.2 Deterministic CI (Tier 1)

ci.yml runs on every push and pull request to check:

Linting (ruff check + ruff format --check), type checking (mypy), and unit tests (pytest).

Pre‑commit hooks (where configured), including fast secret scans.

Should not run expensive LLM calls.

Note — GitHub default token permissions: New repositories created under an organisation often have the default workflow token set to read-only. The scaffold workflows declare permissions: contents: read explicitly so they work with both read-only and read-write defaults. If you add a job that needs to write (e.g., push a badge), you must add permissions: write explicitly on that job only.

Note — gitleaks 403: The gitleaks-action v2 default behaviour posts PR review comments via the GitHub API, which requires pull-requests: write. Our workflows set GITLEAKS_ENABLE_COMMENTS: "false" to disable this. The gitleaks job also declares pull-requests: read (not write) because the action enumerates PR commits to scope its scan even when commenting is disabled; without this read permission the action returns 403 on org repos. Organisation repos additionally require a free GITLEAKS_LICENSE secret (obtain at gitleaks.io); personal account repos do not.

5.3 Evaluations (Tier 2)

evals.yml runs on changes to prompts or config files. It uses promptfoo to evaluate the impact of changes on a small dataset. You define a success threshold and decide whether to block merges on failing evaluations. Use environment variables or secrets to configure the LLM provider for local‑live or prod modes.

5.4 Security Scanning (Tier 3)

security.yml runs weekly (or on demand) to run deep secret scanning with tools like trufflehog or gitleaks. It generates reports and prevents accidental credential leaks from entering the repository.

5.5 Deployment Workflows (Optional)

If using the Full scaffold, fill in the placeholder workflows:

deploy-backend.yml — build Docker image, push to ECR, update Lambda, store pointer config in Secrets Manager, perform smoke tests.

deploy-workers.yml — similar to backend; updates extract and summarise workers.

deploy-frontend.yml — build and deploy the frontend (React/Vite) to S3/CloudFront. Insert environment variables from GitHub Secrets.

sbom.yml — generate SBOM using tools like syft/grype to track dependencies and vulnerabilities.

Fill in the appropriate names (repository, functions, buckets) and secrets. Consider adopting OIDC for AWS deployment roles.

6) Using Cursor & Claude Tools

6.0 Architecture: Scripts‑First, Wrappers‑Second

The scaffold follows a scripts‑first architecture for all workflow automation. Deterministic PowerShell scripts in scripts/dev/ are the single source of truth for each workflow action. Claude Code commands (.claude/commands/*.md) and Cursor commands (.cursor/commands/*.md) are thin wrappers that invoke these scripts and format their output.

This means the workflow is testable in CI, runnable from any terminal, version‑controlled, and debuggable. If Claude Code or Cursor change their APIs, only the thin wrappers need updating — the scripts remain stable.

All workflow scripts support a standard interface:

--dry-run (default for anything that modifies files)
--apply (explicit opt-in to execute changes)
--out <dir> (proof bundle output directory)
--format json|text (json for tooling, text for humans)

Proof bundles (audit logs for each action) are written to .cursor/audits/<action>/<date>/<timestamp>/ and include meta.json, summary.md, stdout.txt, stderr.txt, and action‑specific files. This directory is gitignored.

6.1 Cursor

Cursor reads .cursor/rules/*.mdc and uses them to enforce coding standards and conventions during active development. Important notes:

Use only flat .mdc files in .cursor/rules/. The RULE.md folder format has known reliability issues as of early 2026. Do not use it.

Each .mdc file uses YAML frontmatter with description, globs, and alwaysApply fields. Cursor supports four rule types: Always (injected into every prompt), Auto (attached when glob patterns match active files), Agent-requested (agents see the description and request if needed), and Manual (user explicitly includes via @rulename).

Important: do not set both alwaysApply: true and globs: on the same rule — alwaysApply silently overrides globs (undocumented behavior).

Keep rules minimal and convention‑focused; do not embed workflow logic in rules. Workflow logic belongs in commands and scripts.

.cursor/commands/*.md stores Cursor command wrappers. These mirror the Claude Code commands and invoke the same underlying scripts:

/repo-map — runs scripts/dev/repo‑map.ps1 to update Repo_Map.md
/verify — runs scripts/verify.ps1 (full) or scripts/verify-fast.ps1
/eod — full end-of-day wrap-up: runs eod‑file‑triage.ps1, doc‑sync.ps1, conditional doc/lesson updates, and verify
/review — review staged/unstaged changes for quality and conventions
/status — repository status summary
/change-summary — generate commit/PR summary from git diff

.cursor/roles/ defines agent roles (Implementer, Reviewer, Refactorer, Researcher, Architect). These roles should be used in multi‑agent workflows and referenced in task packet templates.

.cursor/prompts/ stores task packet templates, making it easy to hand off tasks to agents. Use these templates to maintain consistency across handoffs.

.cursor/skills/*.mdc exists as a beta feature since Cursor v2.4 (January 2026). It is not yet reliable. If you want skills-style behavior in Cursor, use .cursor/commands/ instead.

The closed‑loop failure log .cursor/last-verify-failure.txt is updated by verification scripts; agents can read this file to understand why a check failed.

6.2 Claude Code

.claude/settings.json defines what Claude Code is allowed to run (safe commands) and denies potentially harmful operations (git push, rm -rf, etc.). It also configures hooks (see below).

.claude/agents/ holds agent definitions. Each markdown file describes a specific agent's role, capabilities, and invocation instructions using YAML frontmatter (name, description, tools, model). Baseline agents include code‑reviewer, researcher, architect, test‑runner, implementer, and refactorer.

.claude/commands/ stores slash commands. These are the primary interface for workflow automation:

/review — diff checks on staged changes, golden rule violation scan
/status — repository status summary (git diff, lint/type results)
/verify — run the staged verification pattern (verify-fast then verify)
/repo-map — update Repo_Map.md (invokes scripts/dev/repo‑map.ps1)
/eod — full end-of-day wrap-up (invokes eod‑file‑triage.ps1 + doc‑sync.ps1 + conditional doc/lesson updates + verify)
/change-summary — generate commit/PR summary from git diff and proof bundles
/init — (optional) bootstrap scaffold using start_up_prompt.md

Commands use $ARGUMENTS for parameters (e.g., /verify --fix) and !`backtick` syntax for preprocessing context (e.g., !`git branch --show-current`). Commands support allowed-tools restrictions in their YAML frontmatter to limit what tools they can use.

Important: for quality gates like /verify, always use explicit command invocation. Do not rely on skill auto‑invocation — Claude's LLM decides when to invoke skills automatically, and the trigger rate is approximately 50% baseline (80% with optimized descriptions), which is insufficient for mandatory workflow steps.

.claude/skills/ holds skill definitions. Skills are capabilities that Claude can invoke automatically based on context, or manually via slash command. The primary skill is:

repo-map/ — SKILL.md with disable-model-invocation: true (manual only) and an optional scripts/generate.sh helper. Skills support YAML frontmatter fields: description, allowed-tools, argument-hint, disable-model-invocation, model, and context.

Note: some SKILL.md frontmatter fields (context: fork, agent:) may be silently ignored in current Claude Code versions. Test before relying on skill isolation.

Claude Code reads CLAUDE.md at the start of every session and treats it as authoritative. Keep CLAUDE.md concise (under 150 lines). Context budget is real — skills descriptions consume approximately 2% of the context window. Monitor usage with /context.

Note on AGENTS.md: Claude Code does not natively read AGENTS.md (open issue). Include a pointer in CLAUDE.md (e.g., "See @AGENTS.md for universal project instructions") so Claude loads it when needed. Cursor, Codex, Gemini CLI, and GitHub Copilot do read AGENTS.md natively.

6.3 Hooks (Claude Code)

Hooks are configured in .claude/settings.json and provide deterministic automation — they are guaranteed to execute at specific lifecycle points, unlike CLAUDE.md instructions which can be deprioritized by the model.

Available hook events include PreToolUse, PostToolUse, PostToolUseFailure, Stop, and others (14 total). The scaffold optionally includes one hook:

PostToolUse lint hook — after any Write/Edit to a .py file, runs ruff check on that file. Non‑blocking (exit 0 always; feedback only, never auto-fixes).

Required settings.json format for hooks:
- hooks[].matcher is a regex string (e.g., `"Edit|Write"`) — not an object `{"tools": [...]}` (older format, now invalid per the JSON schema).
- hooks[].hooks[].type must be `"command"`.
- hooks[].hooks[].command invokes a wrapper script, not inline shell: `pwsh "$CLAUDE_PROJECT_DIR/.claude/hooks/lint-python.ps1"`.
- Claude Code passes JSON context on stdin (not via `$TOOL_INPUT_PATH`). The wrapper script reads `.tool_input.file_path` from stdin JSON to get the edited file path.
- permissions.allow/deny entries must use `Bash(subcommand *)` format — e.g., `"Bash(git status *)"`. Bare verb strings like `"Git status"` are silently rejected by the schema.

Safety guidance for hooks:

Use hooks only for non‑destructive feedback, logging, and nudges. Never use hooks to auto‑apply fixes or auto‑move files.

Hooks run with full user permissions outside Claude's Bash tool sandbox. A malicious hook in a cloned repo's .claude/settings.json can exfiltrate data or run arbitrary code. Always review hooks before accepting them.

After editing settings.json directly, restart Claude Code or run /hooks to reload. Direct edits require review in the /hooks menu before activation.

If your team is uncomfortable with hooks running arbitrary shell commands, skip them entirely. The deterministic scripts and explicit commands provide the same functionality via manual invocation.

6.4 MCP (Model Context Protocol)

MCP support is optional but recommended for reproducibility and audit. MCP servers are configured in .claude/settings.json (or .mcp.json) and use a portable JSON format that works across Claude Code, Cursor, and VS Code.

If you integrate MCP servers, ensure you:

Do not store credentials or private context in MCP modules.

Use allow lists to restrict which tools/commands an agent can call.

Follow best practices in your .cursor/rules/ and .cursor/prompts/ to implement strong guardrails.

Audit all third‑party MCP servers before installation — treat them like npm packages (supply‑chain risk).

6.5 Daily Workflow

The scaffold supports a 5‑step daily development workflow:

Start of day — Run /repo-map to update Repo_Map.md with current repo state. This captures the directory tree, entry points, recent git activity, and verification commands. Only AUTO-marked sections are updated; hand‑edited HUMAN sections are preserved.

During day — Code using Cursor or Claude Code as usual. If the optional PostToolUse lint hook is enabled, ruff feedback appears automatically after Python file edits.

Before every push — Run /verify (or /verify-fast for quick checks). This runs lint + typecheck + tests and produces a proof-friendly summary (VERIFY: PASS or VERIFY: FAIL) with a proof bundle path. Do not push until verification passes.

End of day — Run /eod for full wrap-up. This runs file triage (dry‑run move plan), doc drift check, conditional updates to ACTIVE_SPRINT.md / OpenQuestions_Risks.md / Lessons_Learned/, and verify (only if docs changed). Review each step's output before proceeding.

All workflow commands can also be run directly from the terminal via the underlying PowerShell scripts (e.g., pwsh scripts/dev/repo-map.ps1 --apply).

6.6 Lessons Learned

The scaffold includes a lightweight lessons system to capture recurring mistakes, surprising behaviors, and workflow improvements as they happen — rather than losing them in chat history.

Where it lives: Lessons_Learned/ at the repo root contains three files:

Lessons_Learned/critical.md — mandatory for fixes that prevent recurrence of a production risk, security/secrets exposure, CI bypass, data loss, or runaway cost.

Lessons_Learned/notable.md — recommended for bugs that took >30 minutes to diagnose, surprising API/tool/library behavior, or configuration gotchas others are likely to repeat.

Lessons_Learned/quality-of-life.md — optional for workflow improvements, tooling tips, and small friction reductions.

When to add an entry: Whenever you fix a bug, resolve a workflow issue, or discover non-obvious behavior, ask yourself: "Would future-me (or a teammate) benefit from knowing this?" If yes, log it.

Recommended habit: Run this at the end of any session where you resolved a non-trivial problem:

pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "Short title" -Symptom "..." -Fix "..." -Prevention "..."

All parameters except -Category and -Title are optional. The helper creates the file and folder if they are missing, appends a dated entry, and prints the path it wrote to. It never reads or outputs secrets or environment variable values.

The EOD triage script (eod-file-triage.ps1) prints a reminder and example usage line at the end of every run, so you never need to remember to check.

6.7 Template Improvement Loop (Living Docs)

The three root template docs work as a coordinated, evolving system. Lessons_Learned/ is the input stream; promotions from that stream are how the template improves over time.

Tandem roles — what each doc governs:

start_up_guide.md — Human-facing blueprint: directory tree, phased initialization plan, prerequisites, acceptance criteria. Improve here when a lesson reveals a better way to set up or structure a new project.

start_up_prompt.md — Agent activation prompt: the exact instructions pasted into Cursor or Claude Code to initialize a new project. Improve here when a lesson reveals a missing guardrail, a wrong assumption about agent behavior, or a clearer initialization instruction.

continue.md (this file) — Daily operations: connecting to AWS and GitHub, local dev workflow, verification gates, EOD routine, team onboarding. Improve here when a lesson affects how to work inside a running project.

These docs must stay coordinated: if the directory tree changes in start_up_guide.md, the corresponding Phase 1 task in start_up_prompt.md must also reflect it. If a workflow step changes here, it should align with what start_up_guide.md describes as Phase 2 output.

Step 1 — Log the lesson first

Write to Lessons_Learned/ as soon as a problem is resolved, before promoting anything:

critical.md — production/security/CI/data-loss incidents: mandatory

notable.md — non-trivial bugs, API surprises, config gotchas: recommended

quality-of-life.md — workflow improvements, tooling tips: optional

Helper (optional): pwsh scripts/dev/add-lesson.ps1 -Category <category> -Title "Short title" ...

Step 2 — Decide whether to promote (Promotion thresholds)

| Category | Promote when |
|---|---|
| `critical` | Always — immediately after resolution. No threshold; every entry is a mandatory promotion candidate. |
| `notable` | Repeated 2+ times, OR affects onboarding, CI, or security for current or future contributors. |
| `quality-of-life` | Referenced or useful repeatedly (e.g., weekly) OR directly benefits multiple contributors. |

A lesson that does not yet meet its threshold stays in Lessons_Learned/ as a record. It does not need to become a template change — the log itself has value.

Step 3 — Apply the promotion

Choose the right target doc using the tandem-role mapping above, make the minimal additive change, and fill in the backlink on both sides.

Target mapping at a glance:

Lesson about project setup, prerequisites, or directory structure → start_up_guide.md

Lesson about agent behavior, missing guardrail, or initial instructions → start_up_prompt.md

Lesson about daily workflow, debugging protocol, or handoff → continue.md

Lesson requiring cross-cutting enforcement in all future code → .cursor/rules/*.mdc or .claude/agents/*.md

How to backlink

A promotion is only complete when it is traceable in both directions — from the lesson to the template change, and from the template change back to the lesson.

In the lesson entry — fill in the "Promoted to:" field with the target file, section, and a brief description:

Promoted to: `continue.md §6.7` — added promotion thresholds table (2026-02-27)

Use `—` if the lesson has not yet been promoted.

In the target doc — add a one-line reference near the change you made:

(see Lessons_Learned/notable.md — 2026-02-27, "Short title")

Together these two links make the loop auditable: you can trace any template change back to its origin lesson, and trace any lesson forward to where it was applied.

Safety rule: never include secrets, tokens, API keys, passwords, or connection strings in lessons or template docs. Redact all sensitive values (e.g., write REDACTED or ***).

7) Tailor the Scaffold for Your Project

Once the scaffold exists and basic setup is complete:

Decide whether you need the optional modules (apps/, infra/, observability/, security/). Remove or leave them empty based on the project scope.

Fill in docs/architecture/ARCHITECTURE.md, REPO_MAP.md, docs/reference/ENV_VARS.md, evals/* thresholds/datasets, and docs/planning/OpenQuestions_Risks.md with project‑specific content.

Extend env_spec.py with real environment variables for your project. Regenerate mode_defaults.json and .env.example via the generator script or manual editing. Upload production values to Secrets Manager.

Adjust the CI path filters so that expensive tests and evaluations only run when relevant files change.

Confirm that the 3‑mode contract matches your dev/prod resource allocation and cost model. Modify mode names or add new modes if needed.

Define your default allowlists and denylists for the file triage script (which directories files can be moved to, which files are protected).

Define source‑to‑doc mapping rules for the doc‑check script (which .py files correspond to which .md files).

8) New Teammate Onboarding

Provide the following path when bringing a new engineer onto the project:

Read: START_HERE.md, then AGENTS.md, then CLAUDE.md and CURSOR_RULES.md.

Clone the repo and set up Python and uv. Run pre‑commit install.

Enter offline mode via use‑env.ps1 or use‑env.sh.

Run verify-fast to ensure the environment is sane.

Learn the codebase by following REPO_MAP.md (which should be kept up to date via /repo-map).

Learn the daily workflow: /repo-map at start of day, /verify before push, /eod at end of day.

Understand how to propose changes: implementer → reviewer → human approval.

For new env variables, follow the template TEMPLATE_ADD_ENV_VAR.md to ensure consistency across modes.

Conclusion

This guide should give you everything you need to connect the scaffold to real infrastructure, enforce best practices, and ramp up new developers. After you define your project's goals, make sure to revisit the "Fill‑Me" sections and complete them. If you have additional questions or run into issues, document them in docs/planning/OpenQuestions_Risks.md so they can be addressed and incorporated back into the template in future updates.
