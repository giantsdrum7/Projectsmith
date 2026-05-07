"""Shared test fixtures.

Provides mode-pinning and common utilities for all tests.
"""

from __future__ import annotations

import pytest


@pytest.fixture(autouse=True)
def _pin_offline_mode(monkeypatch: pytest.MonkeyPatch) -> None:
    """Pin APP_MODE to offline for all tests by default.

    Tests that need a different mode should override this fixture.
    This prevents shell environment leakage from causing flaky tests.
    """
    monkeypatch.setenv("APP_MODE", "offline")
