"""Contract test: mode_defaults.json stays in sync with env_spec.py."""

from __future__ import annotations

import json
from pathlib import Path

_MODE_DEFAULTS = Path(__file__).resolve().parent.parent.parent / "scripts" / "env" / "mode_defaults.json"


def test_mode_defaults_has_required_modes() -> None:
    """mode_defaults.json must define all three operating modes."""
    assert _MODE_DEFAULTS.exists(), f"Missing: {_MODE_DEFAULTS}"
    data = json.loads(_MODE_DEFAULTS.read_text())
    required = {"offline", "local-live", "prod"}
    actual = set(data.keys())
    missing = required - actual
    assert not missing, f"mode_defaults.json missing modes: {missing}"
