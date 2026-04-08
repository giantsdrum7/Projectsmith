# Multi-stage Dockerfile for {{ project_name }}
#
# Stage 1 (builder): Installs dependencies using uv in an isolated build layer.
# Stage 2 (runtime): Lambda-compatible image with only production artifacts.
#
# 3-mode contract compatibility:
#   - offline:    Not typically containerized (local dev with mocks)
#   - local-live: Run via docker-compose with DynamoDB Local and real AWS credentials
#   - prod:       Deployed as Lambda container image via CDK/ECR
#
# Customize per project: add COPY lines for additional source directories,
# adjust the CMD handler path, and add build args as needed.

# ---------------------------------------------------------------------------
# Stage 1: Builder
# ---------------------------------------------------------------------------
FROM python:3.12-slim AS builder
WORKDIR /build

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

COPY pyproject.toml uv.lock* ./
COPY packages/ ./packages/

RUN uv sync --frozen --no-dev

# ---------------------------------------------------------------------------
# Stage 2: Runtime (Lambda-compatible)
# ---------------------------------------------------------------------------
FROM public.ecr.aws/lambda/python:3.12 AS runtime

COPY --from=builder /build/.venv/lib/python3.12/site-packages {% raw %}${LAMBDA_TASK_ROOT}{% endraw %}
COPY src/ {% raw %}${LAMBDA_TASK_ROOT}{% endraw %}/

CMD ["{{ project_slug }}.api.handler.lambda_handler"]
