"""Smoke test: FastAPI healthcheck endpoint."""

from __future__ import annotations

from fastapi.testclient import TestClient

from {{ project_slug }}.api.app import app


def test_healthcheck_returns_200() -> None:
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200

    body = response.json()
    assert body["status"] == "ok"
    assert "mode" in body
    assert "namespace" in body


def test_healthcheck_offline_mode_value() -> None:
    """In offline mode (pinned by root conftest), mode should be 'offline'."""
    with TestClient(app) as client:
        response = client.get("/health")

    body = response.json()
    assert body["mode"] == "offline"
