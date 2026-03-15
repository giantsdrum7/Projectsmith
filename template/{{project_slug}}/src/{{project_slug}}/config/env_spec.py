"""Environment variable specification.

This module is the single source of truth for all environment variables.
Run scripts/env/generate_env_templates.py to regenerate mode_defaults.json and .env.example.
"""

from __future__ import annotations

import enum
from dataclasses import dataclass, field


class Category(enum.StrEnum):
    """Logical grouping for environment variables."""

    MODE = "mode"
    AWS = "aws"
    BEDROCK = "bedrock"
    S3 = "s3"
    SECRETS = "secrets"
    COGNITO = "cognito"
    LOGGING = "logging"
    TIMEOUTS = "timeouts"
    FEATURES = "features"
    API = "api"
    OPENSEARCH = "opensearch"
    EXTERNAL = "external"


class Mode(enum.StrEnum):
    """Application runtime modes matching the 3-mode contract."""

    OFFLINE = "offline"
    LOCAL_LIVE = "local-live"
    PROD = "prod"


@dataclass(frozen=True)
class EnvVar:
    """Specification for a single environment variable."""

    name: str
    description: str
    category: Category
    defaults: dict[Mode, str] = field(default_factory=dict)
    required: bool = True
    secret: bool = False


# ---------------------------------------------------------------------------
# ENV_SPEC — all ~60 variables
# ---------------------------------------------------------------------------

ENV_SPEC: tuple[EnvVar, ...] = (
    # ── Mode ──────────────────────────────────────────────────────────────
    EnvVar(
        name="APP_MODE",
        description="Runtime mode: offline, local-live, or prod",
        category=Category.MODE,
        defaults={Mode.OFFLINE: "offline", Mode.LOCAL_LIVE: "local-live", Mode.PROD: "prod"},
    ),
    EnvVar(
        name="APP_ENV",
        description="Deployment environment label",
        category=Category.MODE,
        defaults={Mode.OFFLINE: "development", Mode.LOCAL_LIVE: "development", Mode.PROD: "production"},
    ),
    EnvVar(
        name="DEBUG",
        description="Enable debug helpers and verbose output",
        category=Category.MODE,
        defaults={Mode.OFFLINE: "true", Mode.LOCAL_LIVE: "true", Mode.PROD: "false"},
    ),
    # ── AWS Core ──────────────────────────────────────────────────────────
    EnvVar(
        name="AWS_REGION",
        description="Primary AWS region",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "{{ aws_region }}", Mode.LOCAL_LIVE: "{{ aws_region }}", Mode.PROD: "{{ aws_region }}"},
    ),
    EnvVar(
        name="AWS_ACCOUNT_ID",
        description="AWS account ID for resource references",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "000000000000",
            Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC",
            Mode.PROD: "REDACTED_ORG_SPECIFIC",
        },
    ),
    EnvVar(
        name="AWS_ROLE_ARN",
        description="IAM role ARN for OIDC / cross-account deployments",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
        secret=True,
    ),
    EnvVar(
        name="AWS_ACCESS_KEY_ID",
        description="Temporary access key (prefer OIDC over static keys)",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "", Mode.PROD: ""},
        required=False,
        secret=True,
    ),
    EnvVar(
        name="AWS_SECRET_ACCESS_KEY",
        description="Temporary secret key (prefer OIDC over static keys)",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "", Mode.PROD: ""},
        required=False,
        secret=True,
    ),
    EnvVar(
        name="AWS_SESSION_TOKEN",
        description="Session token for assumed roles",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "", Mode.PROD: ""},
        required=False,
        secret=True,
    ),
    # ── DynamoDB ──────────────────────────────────────────────────────────
    EnvVar(
        name="DYNAMODB_DOCUMENTS_TABLE",
        description="DynamoDB table for doc-level metadata (ACL, title, active version)",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-Documents-dev",
            Mode.PROD: "{{ project_slug }}-Documents-prod",
        },
        required=False,
    ),
    EnvVar(
        name="DYNAMODB_VERSIONS_TABLE",
        description="DynamoDB table for document versions",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-DocumentVersions-dev",
            Mode.PROD: "{{ project_slug }}-DocumentVersions-prod",
        },
        required=False,
    ),
    EnvVar(
        name="DYNAMODB_JOBS_TABLE",
        description="DynamoDB table for ingestion jobs",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-IngestJobs-dev",
            Mode.PROD: "{{ project_slug }}-IngestJobs-prod",
        },
        required=False,
    ),
    EnvVar(
        name="DYNAMODB_REVIEW_TABLE",
        description="DynamoDB table for review tasks (contradiction/supersession)",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-ReviewTasks-dev",
            Mode.PROD: "{{ project_slug }}-ReviewTasks-prod",
        },
        required=False,
    ),
    EnvVar(
        name="DYNAMODB_MANIFESTS_TABLE",
        description="DynamoDB table for answer manifests (provenance audit)",
        category=Category.AWS,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-AnswerManifests-dev",
            Mode.PROD: "{{ project_slug }}-AnswerManifests-prod",
        },
        required=False,
    ),
    # ── Orchestration ─────────────────────────────────────────────────────
    EnvVar(
        name="SFN_INGEST_ARN",
        description="Step Functions state machine ARN for the ingestion pipeline",
        category=Category.AWS,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    # ── Bedrock / LLM ────────────────────────────────────────────────────
    # Claude 4.6 model routing (us-east-1 inference profiles):
    #   Default (extraction/chat): us.anthropic.claude-sonnet-4-6
    #   Complex legal/regulatory:  us.anthropic.claude-opus-4-6-v1
    #   Lightweight routing (if needed): anthropic.claude-haiku-4-5-20251001-v1:0
    #   Note: Sonnet 4.6 and Opus 4.6 require inference profiles on Bedrock,
    #   not direct model IDs. Haiku 4.6 does not exist on Bedrock yet.
    EnvVar(
        name="BEDROCK_INFERENCE_PROFILE_ARN",
        description="Bedrock inference profile ARN for routing",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="BEDROCK_MODEL_ID",
        description="Default Bedrock model identifier",
        category=Category.BEDROCK,
        defaults={
            Mode.OFFLINE: "us.anthropic.claude-sonnet-4-6",
            Mode.LOCAL_LIVE: "us.anthropic.claude-sonnet-4-6",
            Mode.PROD: "us.anthropic.claude-sonnet-4-6",
        },
    ),
    EnvVar(
        name="BEDROCK_MAX_TOKENS",
        description="Maximum tokens per LLM response",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "4096", Mode.LOCAL_LIVE: "4096", Mode.PROD: "4096"},
    ),
    EnvVar(
        name="BEDROCK_TEMPERATURE",
        description="LLM sampling temperature (0.0 = deterministic)",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "0.0", Mode.LOCAL_LIVE: "0.0", Mode.PROD: "0.0"},
    ),
    EnvVar(
        name="BEDROCK_TOP_P",
        description="LLM nucleus sampling threshold",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "1.0", Mode.LOCAL_LIVE: "1.0", Mode.PROD: "1.0"},
    ),
    EnvVar(
        name="BEDROCK_STOP_SEQUENCES",
        description="Comma-separated stop sequences for LLM",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "", Mode.PROD: ""},
        required=False,
    ),
    EnvVar(
        name="BEDROCK_RETRY_MAX",
        description="Maximum retries for Bedrock API calls",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "3", Mode.LOCAL_LIVE: "3", Mode.PROD: "3"},
    ),
    EnvVar(
        name="BEDROCK_RETRY_BACKOFF_BASE",
        description="Exponential backoff base (seconds) for Bedrock retries",
        category=Category.BEDROCK,
        defaults={Mode.OFFLINE: "2.0", Mode.LOCAL_LIVE: "2.0", Mode.PROD: "2.0"},
    ),
    EnvVar(
        name="BEDROCK_EMBEDDING_MODEL_ID",
        description="Bedrock embedding model for chunk vectorization",
        category=Category.BEDROCK,
        defaults={
            Mode.OFFLINE: "amazon.titan-embed-text-v2:0",
            Mode.LOCAL_LIVE: "amazon.titan-embed-text-v2:0",
            Mode.PROD: "amazon.titan-embed-text-v2:0",
        },
    ),
    # ── OpenSearch Serverless ─────────────────────────────────────────────
    EnvVar(
        name="OPENSEARCH_SEARCH_ENDPOINT",
        description="OpenSearch Serverless search collection endpoint URL",
        category=Category.OPENSEARCH,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="OPENSEARCH_VECTOR_ENDPOINT",
        description="OpenSearch Serverless vector collection endpoint URL",
        category=Category.OPENSEARCH,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="OPENSEARCH_INDEX_NAME",
        description="Index name within both OpenSearch collections",
        category=Category.OPENSEARCH,
        defaults={Mode.OFFLINE: "chunks-v1", Mode.LOCAL_LIVE: "chunks-v1", Mode.PROD: "chunks-v1"},
    ),
    EnvVar(
        name="OPENSEARCH_KNN_DIMENSION",
        description="kNN vector dimension (must match embedding model output)",
        category=Category.OPENSEARCH,
        defaults={Mode.OFFLINE: "1024", Mode.LOCAL_LIVE: "1024", Mode.PROD: "1024"},
    ),
    # ── S3 Storage ────────────────────────────────────────────────────────
    EnvVar(
        name="S3_DATALAKE_BUCKET",
        description="Canonical single-bucket datalake (replaces S3_ARTIFACTS/UPLOADS_BUCKET)",
        category=Category.S3,
        defaults={
            Mode.OFFLINE: "",
            Mode.LOCAL_LIVE: "{{ project_slug }}-datalake-dev",
            Mode.PROD: "{{ project_slug }}-datalake-prod",
        },
        required=False,
    ),
    EnvVar(
        name="S3_KMS_KEY_ARN",
        description="KMS CMK ARN for S3 default encryption",
        category=Category.S3,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="S3_ARTIFACTS_BUCKET",
        description="S3 bucket for build/eval artifacts",
        category=Category.S3,
        defaults={
            Mode.OFFLINE: "{{ project_slug }}-artifacts-dev",
            Mode.LOCAL_LIVE: "{{ project_slug }}-artifacts-dev",
            Mode.PROD: "{{ project_slug }}-artifacts-prod",
        },
    ),
    EnvVar(
        name="S3_UPLOADS_BUCKET",
        description="S3 bucket for user uploads",
        category=Category.S3,
        defaults={
            Mode.OFFLINE: "{{ project_slug }}-uploads-dev",
            Mode.LOCAL_LIVE: "{{ project_slug }}-uploads-dev",
            Mode.PROD: "{{ project_slug }}-uploads-prod",
        },
    ),
    EnvVar(
        name="S3_REGION",
        description="AWS region for S3 buckets (may differ from primary region)",
        category=Category.S3,
        defaults={Mode.OFFLINE: "{{ aws_region }}", Mode.LOCAL_LIVE: "{{ aws_region }}", Mode.PROD: "{{ aws_region }}"},
    ),
    EnvVar(
        name="S3_PRESIGNED_URL_EXPIRY",
        description="Presigned URL expiration in seconds",
        category=Category.S3,
        defaults={Mode.OFFLINE: "3600", Mode.LOCAL_LIVE: "3600", Mode.PROD: "3600"},
    ),
    # ── Secrets Manager ───────────────────────────────────────────────────
    EnvVar(
        name="SECRETS_PREFIX",
        description="Prefix path in AWS Secrets Manager",
        category=Category.SECRETS,
        defaults={
            Mode.OFFLINE: "{{ project_slug }}/dev",
            Mode.LOCAL_LIVE: "{{ project_slug }}/dev",
            Mode.PROD: "{{ project_slug }}/prod",
        },
    ),
    EnvVar(
        name="SECRETS_CACHE_TTL",
        description="Secrets cache time-to-live in seconds",
        category=Category.SECRETS,
        defaults={Mode.OFFLINE: "300", Mode.LOCAL_LIVE: "300", Mode.PROD: "300"},
    ),
    EnvVar(
        name="SECRETS_FALLBACK_TO_ENV",
        description="Fall back to env vars when Secrets Manager is unavailable",
        category=Category.SECRETS,
        defaults={Mode.OFFLINE: "true", Mode.LOCAL_LIVE: "true", Mode.PROD: "false"},
    ),
    # ── Cognito / Auth ────────────────────────────────────────────────────
    EnvVar(
        name="COGNITO_USER_POOL_ID",
        description="Cognito user pool identifier",
        category=Category.COGNITO,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
    ),
    EnvVar(
        name="COGNITO_CLIENT_ID",
        description="Cognito app client ID",
        category=Category.COGNITO,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
    ),
    EnvVar(
        name="COGNITO_DOMAIN",
        description="Cognito hosted UI domain prefix",
        category=Category.COGNITO,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="COGNITO_CALLBACK_URL",
        description="OAuth2 callback URL for Cognito",
        category=Category.COGNITO,
        defaults={
            Mode.OFFLINE: "http://localhost:3000/auth/callback",
            Mode.LOCAL_LIVE: "http://localhost:3000/auth/callback",
            Mode.PROD: "REDACTED_ORG_SPECIFIC",
        },
    ),
    EnvVar(
        name="JWT_AUDIENCE",
        description="Expected JWT audience claim for token validation",
        category=Category.COGNITO,
        defaults={
            Mode.OFFLINE: "{{ project_slug }}-local",
            Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC",
            Mode.PROD: "REDACTED_ORG_SPECIFIC",
        },
    ),
    # ── Logging & Observability ───────────────────────────────────────────
    EnvVar(
        name="LOG_LEVEL",
        description="Minimum log level",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "DEBUG", Mode.LOCAL_LIVE: "INFO", Mode.PROD: "WARNING"},
    ),
    EnvVar(
        name="LOG_FORMAT",
        description="Log output format: json or text",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "text", Mode.LOCAL_LIVE: "json", Mode.PROD: "json"},
    ),
    EnvVar(
        name="LOG_OUTPUT",
        description="Log output destination: stdout or file",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "stdout", Mode.LOCAL_LIVE: "stdout", Mode.PROD: "stdout"},
    ),
    EnvVar(
        name="OTEL_EXPORTER_ENDPOINT",
        description="OpenTelemetry collector gRPC endpoint",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "http://localhost:4317", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
    ),
    EnvVar(
        name="OTEL_SERVICE_NAME",
        description="Service name reported to OpenTelemetry",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "{{ project_slug }}", Mode.LOCAL_LIVE: "{{ project_slug }}", Mode.PROD: "{{ project_slug }}"},
    ),
    EnvVar(
        name="SENTRY_DSN",
        description="Sentry Data Source Name for error tracking",
        category=Category.LOGGING,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
        secret=True,
    ),
    # ── Timeouts & Limits ─────────────────────────────────────────────────
    EnvVar(
        name="REQUEST_TIMEOUT_SECONDS",
        description="Default HTTP request timeout",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "30", Mode.LOCAL_LIVE: "30", Mode.PROD: "30"},
    ),
    EnvVar(
        name="LLM_TIMEOUT_SECONDS",
        description="Timeout for individual LLM API calls",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "120", Mode.LOCAL_LIVE: "120", Mode.PROD: "120"},
    ),
    EnvVar(
        name="WORKER_TIMEOUT_SECONDS",
        description="Timeout for background worker tasks",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "300", Mode.LOCAL_LIVE: "300", Mode.PROD: "300"},
    ),
    EnvVar(
        name="MAX_CONCURRENT_LLM_CALLS",
        description="Maximum parallel LLM requests",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "5", Mode.LOCAL_LIVE: "5", Mode.PROD: "5"},
    ),
    EnvVar(
        name="MAX_UPLOAD_SIZE_MB",
        description="Maximum file upload size in megabytes",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "50", Mode.LOCAL_LIVE: "50", Mode.PROD: "50"},
    ),
    EnvVar(
        name="RATE_LIMIT_PER_MINUTE",
        description="API rate limit per client per minute",
        category=Category.TIMEOUTS,
        defaults={Mode.OFFLINE: "60", Mode.LOCAL_LIVE: "60", Mode.PROD: "60"},
    ),
    # ── Feature Flags ─────────────────────────────────────────────────────
    EnvVar(
        name="FEATURE_EVAL_ENABLED",
        description="Enable evaluation harness",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "true", Mode.PROD: "true"},
    ),
    EnvVar(
        name="FEATURE_FRONTEND_ENABLED",
        description="Enable frontend serving",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "false", Mode.PROD: "true"},
    ),
    EnvVar(
        name="FEATURE_WORKERS_ENABLED",
        description="Enable background worker processes",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "false", Mode.PROD: "true"},
    ),
    EnvVar(
        name="FEATURE_AUTH_ENABLED",
        description="Enable authentication enforcement",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "false", Mode.PROD: "true"},
    ),
    EnvVar(
        name="FEATURE_OBSERVABILITY_ENABLED",
        description="Enable OpenTelemetry and Sentry integrations",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "false", Mode.PROD: "true"},
    ),
    EnvVar(
        name="FEATURE_CACHE_ENABLED",
        description="Enable response caching layer",
        category=Category.FEATURES,
        defaults={Mode.OFFLINE: "false", Mode.LOCAL_LIVE: "false", Mode.PROD: "true"},
    ),
    # ── API Server ────────────────────────────────────────────────────────
    EnvVar(
        name="API_HOST",
        description="API server bind address",
        category=Category.API,
        defaults={Mode.OFFLINE: "0.0.0.0", Mode.LOCAL_LIVE: "0.0.0.0", Mode.PROD: "0.0.0.0"},
    ),
    EnvVar(
        name="API_PORT",
        description="API server port",
        category=Category.API,
        defaults={Mode.OFFLINE: "8000", Mode.LOCAL_LIVE: "8000", Mode.PROD: "8000"},
    ),
    EnvVar(
        name="API_WORKERS",
        description="Number of uvicorn worker processes",
        category=Category.API,
        defaults={Mode.OFFLINE: "1", Mode.LOCAL_LIVE: "1", Mode.PROD: "4"},
    ),
    EnvVar(
        name="API_CORS_ORIGINS",
        description="Comma-separated allowed CORS origins",
        category=Category.API,
        defaults={Mode.OFFLINE: "*", Mode.LOCAL_LIVE: "*", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
    ),
    EnvVar(
        name="API_BASE_PATH",
        description="Base URL path prefix for all API routes",
        category=Category.API,
        defaults={Mode.OFFLINE: "/api/v1", Mode.LOCAL_LIVE: "/api/v1", Mode.PROD: "/api/v1"},
    ),
    # ── External Services ─────────────────────────────────────────────────
    EnvVar(
        name="SERPER_API_KEY",
        description="Serper.dev API key for web search",
        category=Category.EXTERNAL,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
        secret=True,
    ),
    EnvVar(
        name="GITHUB_TOKEN",
        description="GitHub personal access token for repo operations",
        category=Category.EXTERNAL,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
        secret=True,
    ),
    EnvVar(
        name="SLACK_WEBHOOK_URL",
        description="Slack incoming webhook for notifications",
        category=Category.EXTERNAL,
        defaults={Mode.OFFLINE: "", Mode.LOCAL_LIVE: "REDACTED_ORG_SPECIFIC", Mode.PROD: "REDACTED_ORG_SPECIFIC"},
        required=False,
        secret=True,
    ),
)


# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------


def get_defaults_for_mode(mode: Mode) -> dict[str, str]:
    """Return a flat dict of {var_name: default_value} for the given mode."""
    return {var.name: var.defaults.get(mode, "") for var in ENV_SPEC}


def get_required_vars(mode: Mode) -> list[str]:
    """Return names of variables that are required in the given mode.

    A variable is considered required for a mode when ``required=True``
    **and** it has a non-empty default for that mode (empty-string defaults
    signal that the variable must be supplied externally).
    """
    return [var.name for var in ENV_SPEC if var.required]


def get_secret_vars() -> list[str]:
    """Return names of all variables marked as secrets."""
    return [var.name for var in ENV_SPEC if var.secret]


def get_vars_by_category(category: Category) -> list[EnvVar]:
    """Return all EnvVar entries belonging to *category*."""
    return [var for var in ENV_SPEC if var.category == category]
