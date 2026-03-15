"""Contract test: dev/prod guardrails are in place."""

from __future__ import annotations

import importlib.util
from pathlib import Path
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    import types


def _load_mode_module() -> types.ModuleType:
    """Load mode.py by filesystem path."""
    src_dir = Path(__file__).resolve().parent.parent.parent / "src"
    candidates = [p for p in src_dir.iterdir() if p.is_dir() and (p / "config" / "mode.py").exists()]
    if not candidates:
        msg = f"Could not find config/mode.py under {src_dir}"
        raise FileNotFoundError(msg)

    spec = importlib.util.spec_from_file_location("mode", candidates[0] / "config" / "mode.py")
    module = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(module)  # type: ignore[union-attr]
    return module


def test_default_mode_is_offline(monkeypatch: pytest.MonkeyPatch) -> None:
    """When APP_MODE is unset, the default must be offline (safe by default)."""
    monkeypatch.delenv("APP_MODE", raising=False)
    module = _load_mode_module()
    result = module.get_current_mode()
    assert result.value == "offline", f"Default mode should be 'offline', got '{result.value}'"


def test_invalid_mode_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    """An invalid APP_MODE value must raise ValueError."""
    monkeypatch.setenv("APP_MODE", "not-a-real-mode")
    module = _load_mode_module()
    with pytest.raises(ValueError, match="Invalid APP_MODE"):
        module.get_current_mode()
