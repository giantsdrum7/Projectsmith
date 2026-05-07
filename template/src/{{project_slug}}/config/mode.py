"""Application mode management.

The 3-mode contract:
- offline: stubs all external calls; no cloud traffic; safe for air-gapped dev
- local-live: real cloud calls against dev resources
- prod: CI/CD only; never set locally without explicit override
"""

from __future__ import annotations

import enum
import os


class AppMode(enum.StrEnum):
    """Application operating modes."""

    OFFLINE = "offline"
    LOCAL_LIVE = "local-live"
    PROD = "prod"


def get_current_mode() -> AppMode:
    """Return the current application mode from APP_MODE env var.

    Defaults to OFFLINE if not set — safe by default.
    """
    raw = os.environ.get("APP_MODE", AppMode.OFFLINE.value)
    try:
        return AppMode(raw)
    except ValueError:
        msg = f"Invalid APP_MODE: {raw!r}. Must be one of: {', '.join(m.value for m in AppMode)}"
        raise ValueError(msg) from None
