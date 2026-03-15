# Environment Variables — {{ project_name }}

> Source of truth: `src/{{ project_slug }}/config/env_spec.py` (73 variables, 13 categories).
> Generated templates: `scripts/env/mode_defaults.json`, `.env.example`.

## Generated vs Hand-Edited Contract

| File | Type | Purpose |
|---|---|---|
| `src/{{ project_slug }}/config/env_spec.py` | **Source of truth** | Defines all environment variables, their types, defaults, and categories |
| `scripts/env/generate_env_templates.py` | Generator | Reads `env_spec.py` and produces the generated files below |
| `.env.example` | **Generated** | Template with placeholder values for all variables |
| `scripts/env/mode_defaults.json` | **Generated** | Default values per mode (offline, local-live, prod) |
| `.env` | **Hand-edited** | Local overrides (gitignored, never committed) |

1. **Always** edit `env_spec.py` as the source of truth for adding, removing, or modifying variables.
2. **Regenerate** `.env.example` and `mode_defaults.json` by running `generate_env_templates.py`.
3. **Never** edit `.env.example` or `mode_defaults.json` by hand — they will be overwritten.
4. **Local overrides** go in `.env` only. This file is gitignored.

---

## Mode (3 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `APP_MODE` | Runtime mode | `offline` | `local-live` | `prod` |
| `APP_ENV` | Deployment environment label | `development` | `development` | `production` |
| `DEBUG` | Enable debug helpers and verbose output | `true` | `true` | `false` |

---

## AWS Core (6 variables)

| Variable | Description | Offline | Local-live | Prod | Secret |
|---|---|---|---|---|---|
| `AWS_REGION` | Primary AWS region | `{{ aws_region }}` | `{{ aws_region }}` | `{{ aws_region }}` | — |
| `AWS_ACCOUNT_ID` | AWS account ID | `000000000000` | `REDACTED` | `REDACTED` | — |
| `AWS_ROLE_ARN` | IAM role ARN for OIDC/cross-account | `""` | `REDACTED` | `REDACTED` | Yes |
| `AWS_ACCESS_KEY_ID` | Temporary access key | `""` | `""` | `""` | Yes |
| `AWS_SECRET_ACCESS_KEY` | Temporary secret key | `""` | `""` | `""` | Yes |
| `AWS_SESSION_TOKEN` | Session token for assumed roles | `""` | `""` | `""` | Yes |

---

## DynamoDB (6 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `DYNAMODB_DOCUMENTS_TABLE` | Doc-level metadata (ACL, title, active version) | `""` | `{{ project_slug }}-Documents-dev` | `{{ project_slug }}-Documents-prod` |
| `DYNAMODB_VERSIONS_TABLE` | Document versions | `""` | `{{ project_slug }}-DocumentVersions-dev` | `{{ project_slug }}-DocumentVersions-prod` |
| `DYNAMODB_JOBS_TABLE` | Ingestion jobs | `""` | `{{ project_slug }}-IngestJobs-dev` | `{{ project_slug }}-IngestJobs-prod` |
| `DYNAMODB_REVIEW_TABLE` | Review tasks (contradiction/supersession) | `""` | `{{ project_slug }}-ReviewTasks-dev` | `{{ project_slug }}-ReviewTasks-prod` |
| `DYNAMODB_MANIFESTS_TABLE` | Answer manifests (provenance audit) | `""` | `{{ project_slug }}-AnswerManifests-dev` | `{{ project_slug }}-AnswerManifests-prod` |
| `SFN_INGEST_ARN` | Step Functions state machine ARN | `""` | `REDACTED` | `REDACTED` |

---

## Bedrock / LLM (8 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `BEDROCK_INFERENCE_PROFILE_ARN` | Bedrock inference profile ARN for routing | `""` | `REDACTED` | `REDACTED` |
| `BEDROCK_MODEL_ID` | Default Bedrock model (extraction/chat) | `us.anthropic.claude-sonnet-4-6` | `us.anthropic.claude-sonnet-4-6` | `us.anthropic.claude-sonnet-4-6` |
| `BEDROCK_EMBEDDING_MODEL_ID` | Embedding model for chunk vectorization | `amazon.titan-embed-text-v2:0` | `amazon.titan-embed-text-v2:0` | `amazon.titan-embed-text-v2:0` |
| `BEDROCK_MAX_TOKENS` | Maximum tokens per LLM response | `4096` | `4096` | `4096` |
| `BEDROCK_TEMPERATURE` | Sampling temperature (0.0 = deterministic) | `0.0` | `0.0` | `0.0` |
| `BEDROCK_TOP_P` | Nucleus sampling threshold | `1.0` | `1.0` | `1.0` |
| `BEDROCK_STOP_SEQUENCES` | Comma-separated stop sequences | `""` | `""` | `""` |
| `BEDROCK_RETRY_MAX` | Maximum retries for Bedrock API calls | `3` | `3` | `3` |
| `BEDROCK_RETRY_BACKOFF_BASE` | Exponential backoff base (seconds) | `2.0` | `2.0` | `2.0` |

---

## OpenSearch Serverless (4 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `OPENSEARCH_SEARCH_ENDPOINT` | Search collection endpoint (bare hostname, no `https://`) | `""` | `REDACTED` | `REDACTED` |
| `OPENSEARCH_VECTOR_ENDPOINT` | Vector collection endpoint (bare hostname, no `https://`) | `""` | `REDACTED` | `REDACTED` |
| `OPENSEARCH_INDEX_NAME` | Index name within both collections | `chunks-v1` | `chunks-v1` | `chunks-v1` |
| `OPENSEARCH_KNN_DIMENSION` | kNN vector dimension (must match embedding model) | `1024` | `1024` | `1024` |

> **Important:** Store endpoints as bare hostnames (without `https://` prefix) to avoid the double-prefix bug. See `Lessons_Learned/notable.md` 2026-03-07 entry.

---

## S3 Storage (6 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `S3_DATALAKE_BUCKET` | Canonical single-bucket datalake | `""` | `{{ project_slug }}-datalake-dev` | `{{ project_slug }}-datalake-prod` |
| `S3_KMS_KEY_ARN` | KMS CMK ARN for S3 encryption | `""` | `REDACTED` | `REDACTED` |
| `S3_ARTIFACTS_BUCKET` | Build/eval artifacts bucket | `{{ project_slug }}-artifacts-dev` | `{{ project_slug }}-artifacts-dev` | `{{ project_slug }}-artifacts-prod` |
| `S3_UPLOADS_BUCKET` | User uploads bucket (legacy) | `{{ project_slug }}-uploads-dev` | `{{ project_slug }}-uploads-dev` | `{{ project_slug }}-uploads-prod` |
| `S3_REGION` | AWS region for S3 buckets | `{{ aws_region }}` | `{{ aws_region }}` | `{{ aws_region }}` |
| `S3_PRESIGNED_URL_EXPIRY` | Presigned URL expiration (seconds) | `3600` | `3600` | `3600` |

> `S3_DATALAKE_BUCKET` is the canonical variable (single-bucket decision, Phase 1B). `S3_ARTIFACTS_BUCKET` and `S3_UPLOADS_BUCKET` are legacy — new code should use `S3_DATALAKE_BUCKET`.

---

## Secrets Manager (3 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `SECRETS_PREFIX` | Prefix path in Secrets Manager | `{{ project_slug }}/dev` | `{{ project_slug }}/dev` | `{{ project_slug }}/prod` |
| `SECRETS_CACHE_TTL` | Cache TTL (seconds) | `300` | `300` | `300` |
| `SECRETS_FALLBACK_TO_ENV` | Fall back to env vars if fetch fails | `true` | `true` | `false` |

---

## Cognito / Auth (5 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `COGNITO_USER_POOL_ID` | Cognito user pool ID | `""` | `REDACTED` | `REDACTED` |
| `COGNITO_CLIENT_ID` | Cognito app client ID | `""` | `REDACTED` | `REDACTED` |
| `COGNITO_DOMAIN` | Hosted UI domain prefix | `""` | `REDACTED` | `REDACTED` |
| `COGNITO_CALLBACK_URL` | OAuth2 callback URL | `http://localhost:3000/auth/callback` | `http://localhost:3000/auth/callback` | `REDACTED` |
| `JWT_AUDIENCE` | Expected JWT audience claim | `{{ project_slug }}-local` | `REDACTED` | `REDACTED` |

> Auth enforcement is not yet wired (`FEATURE_AUTH_ENABLED=false` in offline and local-live). Cognito JWT middleware is planned for Phase 2+.

---

## Logging & Observability (6 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `LOG_LEVEL` | Minimum log level | `DEBUG` | `INFO` | `WARNING` |
| `LOG_FORMAT` | Output format (`json` or `text`) | `text` | `json` | `json` |
| `LOG_OUTPUT` | Output destination | `stdout` | `stdout` | `stdout` |
| `OTEL_EXPORTER_ENDPOINT` | OpenTelemetry collector gRPC endpoint | `""` | `http://localhost:4317` | `REDACTED` |
| `OTEL_SERVICE_NAME` | Service name for OTel | `{{ project_slug }}` | `{{ project_slug }}` | `{{ project_slug }}` |
| `SENTRY_DSN` | Sentry error tracking DSN | `""` | `""` | `REDACTED` |

---

## Timeouts & Limits (6 variables)

| Variable | Description | Default (all modes) |
|---|---|---|
| `REQUEST_TIMEOUT_SECONDS` | Default HTTP request timeout | `30` |
| `LLM_TIMEOUT_SECONDS` | Timeout for LLM API calls | `120` |
| `WORKER_TIMEOUT_SECONDS` | Timeout for background worker tasks | `300` |
| `MAX_CONCURRENT_LLM_CALLS` | Maximum parallel LLM requests | `5` |
| `MAX_UPLOAD_SIZE_MB` | Maximum file upload size (MB) | `50` |
| `RATE_LIMIT_PER_MINUTE` | API rate limit per client | `60` |

---

## Feature Flags (6 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `FEATURE_EVAL_ENABLED` | Enable evaluation harness | `false` | `true` | `true` |
| `FEATURE_FRONTEND_ENABLED` | Enable frontend serving | `false` | `false` | `true` |
| `FEATURE_WORKERS_ENABLED` | Enable background workers | `false` | `false` | `true` |
| `FEATURE_AUTH_ENABLED` | Enable authentication enforcement | `false` | `false` | `true` |
| `FEATURE_OBSERVABILITY_ENABLED` | Enable OTel + Sentry | `false` | `false` | `true` |
| `FEATURE_CACHE_ENABLED` | Enable response caching | `false` | `false` | `true` |

---

## API Server (5 variables)

| Variable | Description | Offline | Local-live | Prod |
|---|---|---|---|---|
| `API_HOST` | Bind address | `0.0.0.0` | `0.0.0.0` | `0.0.0.0` |
| `API_PORT` | Port | `8000` | `8000` | `8000` |
| `API_WORKERS` | Uvicorn worker processes | `1` | `1` | `4` |
| `API_CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `*` | `*` | `REDACTED` |
| `API_BASE_PATH` | URL path prefix | `/api/v1` | `/api/v1` | `/api/v1` |

> **Security note:** `API_CORS_ORIGINS=*` is acceptable for local dev only. Must be restricted before any network-accessible deployment.

---

## External Services (3 variables)

| Variable | Description | Secret |
|---|---|---|
| `SERPER_API_KEY` | Serper.dev API key for web search | Yes |
| `GITHUB_TOKEN` | GitHub PAT for repo operations | Yes |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook for notifications | Yes |

All default to `""` in offline, `REDACTED` in local-live/prod.

---

## Secrets Manager Runtime API

`src/{{ project_slug }}/config/secrets_manager.py` exposes two public functions:

### `load_secrets()`

Fetches `{SECRETS_PREFIX}/all` from AWS Secrets Manager, parses the `SecretString` as JSON, and merges each key into `os.environ`. Existing env vars always win (local overrides take priority). Cached for `SECRETS_CACHE_TTL` seconds. In **offline** mode, returns immediately without AWS calls. Secret values are never logged.

### `reset_cache()`

Clears the in-memory secrets cache. Intended for tests only.
