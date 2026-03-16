"""Contract test: mode_defaults.json stays in sync with env_spec.py."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import types

_MODE_DEFAULTS = Path(__file__).resolve().parent.parent.parent / "scripts" / "env" / "mode_defaults.json"
_ENV_SPEC = Path(__file__).resolve().parent.parent.parent / "src"


def _load_env_spec() -> types.ModuleType:
    candidates = [p for p in _ENV_SPEC.iterdir() if p.is_dir() and (p / "config" / "env_spec.py").exists()]
    assert candidates, "Could not find src/*/config/env_spec.py"

    spec_file = candidates[0] / "config" / "env_spec.py"
    spec = importlib.util.spec_from_file_location("env_spec", spec_file)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_mode_defaults_has_required_modes() -> None:
    """mode_defaults.json must define all three operating modes."""
    assert _MODE_DEFAULTS.exists(), f"Missing: {_MODE_DEFAULTS}"
    data = json.loads(_MODE_DEFAULTS.read_text())
    required = {"offline", "local-live", "prod"}
    actual = set(data.keys()) - {"_comment"}
    missing = required - actual
    assert not missing, f"mode_defaults.json missing modes: {missing}"


def test_mode_defaults_matches_env_spec() -> None:
    """mode_defaults.json must match the defaults defined in env_spec.py."""
    env_spec = _load_env_spec()
    data = json.loads(_MODE_DEFAULTS.read_text())

    expected = {
        "offline": env_spec.get_defaults_for_mode(env_spec.Mode.OFFLINE),
        "local-live": env_spec.get_defaults_for_mode(env_spec.Mode.LOCAL_LIVE),
        "prod": env_spec.get_defaults_for_mode(env_spec.Mode.PROD),
    }

    for mode_name, expected_defaults in expected.items():
        assert data[mode_name] == expected_defaults, f"mode_defaults.json drift for mode: {mode_name}"
