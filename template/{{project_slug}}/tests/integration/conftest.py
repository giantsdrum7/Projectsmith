"""Shared fixtures for integration tests.

Provides DynamoDB Local table creation/teardown, test tenant context,
Bedrock stubs, and a pre-configured API test client.
"""

from __future__ import annotations

import os
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


@pytest.fixture(scope="session")
def dynamodb_endpoint() -> str:
    """DynamoDB Local endpoint URL from environment or default."""
    return os.environ.get("DYNAMODB_ENDPOINT", "http://localhost:8000")


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
