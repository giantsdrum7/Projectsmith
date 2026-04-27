# OWASP LLM Top 10 — Security Controls

**Project:** {{ project_name }}
**Last reviewed:** FILL (update after each security review)
**Reference:** [OWASP Top 10 for LLM Applications](https://owasp.org/www-project-top-10-for-large-language-model-applications/)

> **Legend:** `[x]` = enforced by template scaffold or CI. `[ ]` = requires post-generation implementation.

---

## LLM01: Prompt Injection

**Risk:** Attackers craft inputs that override system instructions, causing the LLM to execute unintended actions, bypass controls, or leak sensitive data.

- [x] System prompts separated from user content (prompt registry pattern — prompts loaded by ID, not concatenated with user input)
- [x] Input validation on all user-facing prompts (FastAPI request models with Pydantic validation)
- [x] PII redaction applied before LLM input (see `security/redaction-config.yaml`, `llm_input: true` context)
- [ ] Prompt injection detection guard (wire to `prompt_injection_guard.py` post-generation)
- [ ] Output filtering to prevent instruction leakage in responses
- [ ] Canary token injection for prompt exfiltration detection

**Architectural reference:** Deliverable 3 §2.5 — request flow separates prompt resolution from user input binding. Prompt templates are versioned artifacts, not user-modifiable strings.

---

## LLM02: Insecure Output Handling

**Risk:** LLM-generated output is trusted without validation, leading to XSS, SSRF, code injection, or privilege escalation in downstream systems.

- [x] Structured output validation via Pydantic models (contracts package enforces output schemas)
- [x] Deterministic validators run post-generation: citation validator, financial validator, claim validator (Deliverable 3 §3.1 validation pipeline)
- [ ] HTML/Markdown sanitization before rendering in frontend
- [ ] Output length limits enforced per task type
- [ ] Server-side rendering escapes all LLM-generated content before DOM insertion

**Architectural reference:** Group 2 locked contract — `ProposalTemplate.output_pydantic` enforces typed output schemas. Financial outputs use Decimal-only types (no float corruption).

---

## LLM03: Training Data Poisoning

**Risk:** Manipulated training data influences model behavior, introducing biases, backdoors, or factual errors.

- [x] Using managed foundation models only (Bedrock Converse — no fine-tuning in V1)
- [x] RAG retrieval corpus is curated and version-controlled (S3 artifacts bucket with versioning enabled)
- [ ] Document provenance tracking for all ingested corpus material
- [ ] Periodic retrieval quality evaluation (promptfoo eval suite — evals scaffold provided)
- [ ] Corpus change audit trail ({% if metadata_store == "dynamodb" %}DynamoDB Streams → S3 archival{% elif metadata_store == "postgres" %}PostgreSQL audit/outbox table → S3 archival{% else %}chosen metadata-store audit log → archival storage{% endif %})

**Architectural reference:** Deliverable 3 §3.4 — retrieval validation gate requires ≥80% recall on curated validation set before KB goes live.

---

## LLM04: Model Denial of Service

**Risk:** Attackers send resource-intensive prompts to exhaust LLM quotas, degrade performance, or increase costs.

- [x] API Gateway throttling (REST API with usage plans — per-tenant rate limiting)
- [x] Per-execution budget ceiling in ExecutionManifest (BudgetConsumed atomic updates, fail on ceiling breach)
- [x] Lambda timeout limits (29s sync, configurable async)
- [ ] Token counting pre-flight check before LLM invocation
- [ ] Per-tenant daily/monthly cost caps with alerting
- [ ] Prompt complexity scoring to reject adversarial inputs

**Architectural reference:** Deliverable 3 §2.5 — budget ceiling check is part of the unified request flow. Group 3 `CostPolicy` defines per-bundle cost limits.

---

## LLM05: Supply Chain Vulnerabilities

**Risk:** Compromised LLM plugins, packages, or dependencies introduce vulnerabilities.

- [x] `pip-audit` in CI security workflow (`.github/workflows/security.yml`, enforcing mode)
- [x] `gitleaks` pre-commit and CI hook for secret detection
- [x] Dependency pinning in `pyproject.toml` and `requirements.txt`
- [x] GitHub Actions OIDC — no static AWS credentials in CI (IAM stack enforces)
- [ ] Software Bill of Materials (SBOM) generation
- [ ] Automated dependency update review (Dependabot or Renovate)

**Architectural reference:** Deliverable 4 §2.11 — pip-audit set to enforcing (`continue-on-error: false`). IAM stack (§2.4) enforces OIDC-only deploy role.

---

## LLM06: Sensitive Information Disclosure

**Risk:** LLM inadvertently reveals PII, API keys, internal system details, or proprietary data in its responses.

- [x] PII redaction config for LLM input and logging contexts (see `security/redaction-config.yaml`)
- [x] Secrets stored in AWS Secrets Manager / SSM Parameter Store — never in code or env vars (see `security/secrets-policy.md`)
- [x] Structured logging with correlation IDs — no raw user data in logs (Lambda Powertools)
- [ ] Output PII scanning before returning responses to users
- [ ] Data classification labels on {% if metadata_store == "dynamodb" %}DynamoDB items{% elif metadata_store == "postgres" %}PostgreSQL rows/tables{% else %}metadata records{% endif %} and S3 objects
- [ ] Redaction of internal system paths and stack traces from user-facing errors

**Architectural reference:** Deliverable 3 §2.6 — all log entries are structured JSON. Tenant isolation via `custom:tenant_id` Cognito claim prevents cross-tenant data leakage.

---

## LLM07: Insecure Plugin Design

**Risk:** LLM plugins (tools) operate with excessive permissions, lack input validation, or enable unintended actions.

- [x] Capability bundle authorization — tools granted per-role, per-tenant (Group 3 `ToolGrant` with trust tiers)
- [x] Fail-closed tool resolution — if bundle resolution fails, `allowed_tools` is empty (Deliverable 3 §2.4)
- [x] Tool call audit trail — every tool invocation logged with input hash, output summary, cost ({% if metadata_store == "dynamodb" %}DynamoDB audit records{% elif metadata_store == "postgres" %}PostgreSQL audit records{% else %}metadata-store-neutral audit contract{% endif %})
- [ ] Per-tool input schema validation at invocation time
- [ ] Tool execution sandboxing (separate Lambda per tool category)
- [ ] Rate limiting per tool per user session

**Architectural reference:** Group 3 locked contract — `CapabilityBundle` defines `allowed_tools` per role. Group 4 MCP gateway defines trust tiers for external tool servers.

---

## LLM08: Excessive Agency

**Risk:** LLM is granted too much autonomy — performing actions without human oversight, especially for high-impact operations.

- [x] Proposal review lifecycle with human-in-the-loop approval (Step Functions `.waitForTaskToken` — Deliverable 3 §3.1)
- [x] Group 3 approval defaults — `proposal_author` bundle allows generation without per-call approval, but export crosses a release boundary requiring reviewer approval
- [ ] Configurable approval gates per task type and sensitivity level
- [ ] Action confirmation UI for destructive or irreversible operations
- [ ] Escalation workflow for actions exceeding confidence thresholds

**Architectural reference:** Deliverable 3 §3.2 — review lifecycle maps to Group 2 stages. Export is the release boundary where human approval is mandatory.

---

## LLM09: Overreliance

**Risk:** Users trust LLM outputs without verification, leading to decisions based on hallucinated or incorrect information.

- [x] Citation validator in post-generation pipeline (claims must have backing references)
- [x] Financial validator ensures calculator outputs match LLM claims (Decimal-only, deterministic)
- [x] Eval harness scaffold (promptfoo) for measuring hallucination rates
- [ ] Confidence scores displayed alongside LLM-generated content
- [ ] "AI-generated" watermarks on all LLM outputs
- [ ] User training documentation on appropriate LLM reliance levels

**Architectural reference:** Deliverable 3 §3.1 — validation pipeline runs citation, financial, claim, and numeric consistency validators on every generated proposal.

---

## LLM10: Model Theft

**Risk:** Unauthorized access to the LLM model, prompts, or fine-tuning data through API exploitation or infrastructure compromise.

- [x] Bedrock — managed service, no model weights exposed (model theft N/A for managed inference)
- [x] IAM least-privilege with region-deny and Bedrock NotAction scoping (IAM stack)
- [x] Prompt templates stored as versioned S3 artifacts — access controlled by IAM, not embedded in code
- [ ] Prompt registry access audit logging
- [ ] API key rotation automation for any third-party LLM providers
- [ ] Network isolation (VPC endpoints for Bedrock) for production deployments

**Architectural reference:** IAM stack (Deliverable 4 §2.4) — deploy role scoped to namespace, region-deny with Bedrock NotAction. Prompts are versioned artifacts, not source code.
