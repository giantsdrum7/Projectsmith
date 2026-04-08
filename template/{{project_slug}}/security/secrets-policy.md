# Secrets Management Policy

**Project:** {{ project_name }}
**Last reviewed:** FILL (update after each security review)

---

## 1. Storage Matrix

All secrets are stored in AWS-managed services. **No secrets in source code, `.env` files committed to git, or CI/CD environment variables.** The 3-mode environment system (`offline` / `local-live` / `prod`) defines which secret source is used at runtime.

| Secret Type | Dev (offline) | Dev (local-live) | Staging / Prod | Service |
|---|---|---|---|---|
| **Database credentials** | Local defaults in `mode_defaults.json` | SSM Parameter Store | AWS Secrets Manager | SecretsManager auto-rotation |
| **Cognito app client secret** | Not used (offline stub) | SSM Parameter Store | AWS Secrets Manager | Rotated via Cognito |
| **LLM API keys (if OpenAI)** | Dummy key in mode defaults | SSM Parameter Store | AWS Secrets Manager | Manual rotation (90-day) |
| **Bedrock access** | N/A (offline stub) | IAM role (no key) | IAM role (no key) | IAM role-based, no secret |
| **S3 / DynamoDB access** | LocalStack / DDB Local | IAM role | IAM role | IAM role-based, no secret |
| **GitHub Actions deploy** | N/A | N/A | OIDC federation | No static credentials |
| **Third-party webhook secrets** | Dummy value | SSM Parameter Store | AWS Secrets Manager | Manual rotation (90-day) |
| **Encryption keys (KMS)** | N/A (no encryption offline) | AWS-managed KMS key | CMK with alias | Automatic annual rotation |
| **JWT signing key** | Hardcoded test key | Cognito-managed | Cognito-managed | Cognito rotation |

**Key principle:** IAM roles are preferred over credential-based access for all AWS services. Bedrock, S3, DynamoDB, Step Functions, and Lambda use role-based access exclusively — no API keys.

---

## 2. Rotation Schedule

| Secret Type | Rotation Cadence | Method | Alert on Expiry |
|---|---|---|---|
| Database credentials | 30 days | Secrets Manager auto-rotation (Lambda rotator) | CloudWatch alarm at 7 days before expiry |
| Cognito client secret | 90 days | Manual rotation via Cognito console/CLI | Calendar reminder + CloudWatch |
| LLM API keys (OpenAI) | 90 days | Manual rotation, update in Secrets Manager | Calendar reminder |
| Third-party webhooks | 90 days | Manual rotation, update in Secrets Manager | Calendar reminder |
| KMS CMK | 365 days | Automatic (AWS-managed rotation) | AWS Config rule |
| GitHub OIDC | N/A | No rotation needed (federated identity) | N/A |
| IAM role credentials | Automatic | STS temporary credentials (1-hour max) | N/A |

**Rotation verification:** After any secret rotation, run the deployment verification script (`scripts/deploy/post-deploy-verify.ps1`) to confirm all services remain healthy.

---

## 3. New Secret Procedure

Follow these steps when adding a new secret to the project:

### Step 1: Classify the secret

| Classification | Storage | Example |
|---|---|---|
| **Critical** (breach = data loss) | Secrets Manager with auto-rotation | DB passwords, encryption keys |
| **High** (breach = unauthorized access) | Secrets Manager | API keys, webhook secrets |
| **Medium** (breach = limited exposure) | SSM Parameter Store (SecureString) | Feature flags with sensitive defaults |
| **Low** (not a real secret) | SSM Parameter Store (String) or env var | Region, log level |

### Step 2: Add to environment spec

1. Add the variable to `src/{{ project_slug }}/config/env_spec.py` with appropriate `category`, `required` flag, and per-mode defaults
2. Run `python scripts/env/generate_env_templates.py` to regenerate `.env.example` and `mode_defaults.json`
3. Update `docs/reference/ENV_VARS.md` with the new variable's purpose and allowed values

### Step 3: Store the secret

- **Secrets Manager:** Use naming convention `{{ project_slug }}/{environment}/{secret-name}`
- **SSM Parameter Store:** Use path convention `/{{ project_slug }}/{environment}/{parameter-name}`
- Tag all secrets with: `Project={{ project_slug }}`, `Environment={dev|staging|prod}`, `ManagedBy=manual|cdk`

### Step 4: Grant access

- Add IAM permissions to the appropriate CDK stack (API stack for Lambda, IAM stack for deploy role)
- Follow least-privilege: grant `secretsmanager:GetSecretValue` only to the specific secret ARN
- Never use wildcard (`*`) resource ARNs for secret access

### Step 5: Wire into code

- Use `secrets_manager.py` helper to retrieve the secret at runtime
- Never cache secrets longer than 5 minutes in Lambda (use Powertools Parameters with TTL)
- Handle `SecretNotFoundException` gracefully with structured error logging

### Step 6: Verify

- Confirm all three modes work: `offline` (uses default/stub), `local-live` (reads from SSM/SM), `prod` (reads from SM)
- Run `verify-fast` to ensure no regressions
- Add the secret name to the deploy verification script's health check if applicable

---

## 4. Incident Response — Secret Exposure

If a secret is found in logs, source code, error messages, or any unauthorized location:

### Immediate (within 15 minutes)

1. **Revoke** the exposed credential immediately
   - Secrets Manager: create a new version, update the secret value
   - API keys: regenerate from the provider's console
   - IAM keys: deactivate and delete the exposed key
2. **Rotate** the replacement secret into all environments
3. **Deploy** updated configuration to affected environments

### Investigation (within 1 hour)

4. **Audit** CloudTrail / CloudWatch Logs for unauthorized usage of the exposed credential
   - Search for the exposed key ID in CloudTrail events
   - Check for unusual API call patterns or source IPs
5. **Scope** the blast radius — what resources could the credential access?
6. **Document** the incident with timeline, affected systems, and actions taken

### Remediation (within 24 hours)

7. **Root cause** — how was the secret exposed?
   - Missing `.gitignore` pattern?
   - Logged in plain text by application code?
   - Hardcoded in configuration file?
   - Leaked through error response?
8. **Fix** the root cause (add redaction rule, update `.gitignore`, fix logging)
9. **Verify** the fix prevents recurrence
10. **Report** to project lead and security stakeholder

### Post-incident

11. Add a lesson learned entry to `Lessons_Learned/` (if using the 3-tier knowledge capture system)
12. Update this policy if the incident reveals a gap
13. Add a new redaction rule to `security/redaction-config.yaml` if the pattern was not caught

---

## 5. CI/CD Security Requirements

### Authentication

- **OIDC federation only** for GitHub Actions → AWS. No static `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` in repository secrets.
- The IAM stack provisions a dedicated OIDC provider and deploy role scoped to the deployment namespace.
- Trust policy restricts to the specific GitHub org, repo, and branch pattern.

### Secret Scanning

- **gitleaks** runs as a pre-commit hook and in CI (`.github/workflows/security.yml`)
- `.gitleaks.toml` at repo root defines false-positive suppressions
- CI pipeline **fails** on any gitleaks finding — no `continue-on-error`

### Dependency Scanning

- **pip-audit** runs in CI security workflow in enforcing mode (`continue-on-error: false`)
- Known vulnerabilities block the pipeline until remediated or explicitly suppressed with justification

### Environment Variable Hygiene

- CI workflows use `{% raw %}${{ secrets.GITHUB_TOKEN }}{% endraw %}` (auto-provisioned) for GitHub API access
- AWS credentials are obtained via OIDC `configure-aws-credentials` action — never stored as secrets
- No secret values appear in CI logs — GitHub automatically masks repository secrets, but custom secrets passed via SSM must use `::add-mask::` if echoed
