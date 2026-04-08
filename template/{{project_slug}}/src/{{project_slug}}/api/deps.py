"""Dependency injection singletons for FastAPI route handlers.

Uses ``@lru_cache`` to create expensive AWS SDK clients once per Lambda
container lifetime. Call ``reset_for_testing()`` in test fixtures to clear
all cached singletons between tests.
"""

from __future__ import annotations

from functools import lru_cache
from typing import Any


@lru_cache
def get_dynamodb_resource() -> Any:
    """DynamoDB resource singleton. Respects 3-mode contract."""
    # TODO: Implement with mode-aware endpoint selection
    # - OFFLINE: return None or a stub
    # - LOCAL_LIVE: boto3.resource("dynamodb", endpoint_url=os.environ["DYNAMODB_ENDPOINT"])
    # - PROD: boto3.resource("dynamodb")
    pass


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
    get_dynamodb_resource.cache_clear()
    get_s3_client.cache_clear()
    get_bedrock_client.cache_clear()
