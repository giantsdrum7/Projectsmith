"""Dependency injection singletons for FastAPI route handlers.

Uses ``@lru_cache`` to create expensive AWS SDK clients once per Lambda
container lifetime. Call ``reset_for_testing()`` in test fixtures to clear
all cached singletons between tests.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Any


{% if metadata_store == "dynamodb" -%}
@lru_cache
def get_dynamodb_resource() -> Any:
    """DynamoDB resource singleton. Respects 3-mode contract."""
    # TODO: Implement with mode-aware endpoint selection
    # - OFFLINE: return None or a stub
    # - LOCAL_LIVE: boto3.resource("dynamodb", endpoint_url=os.environ["DYNAMODB_ENDPOINT"])
    # - PROD: boto3.resource("dynamodb")
    pass
{% elif metadata_store == "postgres" -%}
@lru_cache
def get_postgres_client() -> Any:
    """PostgreSQL client singleton. Respects 3-mode contract."""
    # TODO: Implement with mode-aware endpoint selection.
    # Recommended live path: Aurora PostgreSQL Serverless v2 via RDS Data API.
    # RDS Data API is Aurora-only; standard RDS PostgreSQL needs direct network
    # connectivity and connection pooling (RDS Proxy or PgBouncer).
    # - OFFLINE: return a local/stub client
    # - LOCAL_LIVE/PROD with POSTGRES_DATA_API_ENABLED=true: use rds-data
    # - LOCAL_LIVE/PROD otherwise: use a pooled PostgreSQL driver connection
    pass
{% endif %}

@lru_cache
def get_s3_client() -> Any:
    """S3 client singleton."""
    # TODO: Implement with mode-aware configuration
    pass


@lru_cache
def get_bedrock_client() -> Any:
    """Bedrock Runtime client singleton for Converse API calls."""
    # TODO: Implement with mode-aware configuration
    pass


def reset_for_testing() -> None:
    """Clear all cached singletons. Call in test fixtures."""
{% if metadata_store == "dynamodb" -%}
{{ "    get_dynamodb_resource.cache_clear()" }}
{% elif metadata_store == "postgres" -%}
{{ "    get_postgres_client.cache_clear()" }}
{% endif -%}
{{ "    get_s3_client.cache_clear()" }}
    get_bedrock_client.cache_clear()
