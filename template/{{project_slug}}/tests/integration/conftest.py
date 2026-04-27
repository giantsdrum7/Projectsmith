"""Shared fixtures for integration tests.

Provides {% if metadata_store == "dynamodb" %}DynamoDB Local table helpers{% elif metadata_store == "postgres" %}PostgreSQL connection settings{% else %}metadata-store-neutral fixtures{% endif %}, test tenant context, Bedrock stubs, and a pre-configured API test client.
"""

from __future__ import annotations

{% if metadata_store in ["dynamodb", "postgres"] -%}
import os
{% endif -%}
from typing import TYPE_CHECKING, Any

import pytest

if TYPE_CHECKING:
    from collections.abc import Generator

from fastapi.testclient import TestClient

from {{ project_slug }}.api.app import app
from {{ project_slug }}.api.deps import reset_for_testing


@pytest.fixture(autouse=True)
def _pin_offline_mode(monkeypatch: pytest.MonkeyPatch) -> None:
    """Pin APP_MODE to offline for integration tests by default."""
    monkeypatch.setenv("APP_MODE", "offline")


@pytest.fixture(autouse=True)
def _reset_singletons() -> Generator[None, None, None]:
    """Clear cached DI singletons before each test."""
    reset_for_testing()
    yield
    reset_for_testing()


{% if metadata_store == "dynamodb" -%}
@pytest.fixture(scope="session")
def dynamodb_endpoint() -> str:
    """DynamoDB Local endpoint URL from environment or default."""
    return os.environ.get("DYNAMODB_ENDPOINT", "http://localhost:8000")
{% elif metadata_store == "postgres" -%}
@pytest.fixture(scope="session")
def postgres_connection_info() -> dict[str, str]:
    """PostgreSQL connection settings from environment or local defaults."""
    return {
        "host": os.environ.get("POSTGRES_HOST", "localhost"),
        "port": os.environ.get("POSTGRES_PORT", "5432"),
        "database": os.environ.get("POSTGRES_DATABASE", "{{ project_slug }}"),
        "user": os.environ.get("POSTGRES_USER", "{{ project_slug }}"),
    }
{% endif %}

@pytest.fixture
def test_tenant_context() -> dict[str, Any]:
    """Test tenant identity and role claims."""
    return {
        "tenant_id": "test-tenant",
        "user_id": "test-user-001",
        "groups": ["admin", "proposal_author"],
        "email": "test@example.com",
    }


@pytest.fixture
def api_client() -> Generator[TestClient, None, None]:
    """FastAPI TestClient with offline-mode auth headers."""
    with TestClient(app) as client:
        yield client
