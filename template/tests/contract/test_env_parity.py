"""Contract test: env_spec.py is importable and structurally valid."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import types


def _load_env_spec() -> types.ModuleType:
    """Load env_spec.py by filesystem path (works before Copier resolves package name)."""
    src_dir = Path(__file__).resolve().parent.parent.parent / "src"
    candidates = [p for p in src_dir.iterdir() if p.is_dir() and (p / "config" / "env_spec.py").exists()]
    if not candidates:
        msg = f"Could not find config/env_spec.py under {src_dir}"
        raise FileNotFoundError(msg)

    spec_file = candidates[0] / "config" / "env_spec.py"
    spec = importlib.util.spec_from_file_location("env_spec", spec_file)
    module = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    sys.modules["env_spec"] = module
    spec.loader.exec_module(module)  # type: ignore[union-attr]
    return module


def test_env_spec_importable() -> None:
    """The env_spec module must load without errors."""
    module = _load_env_spec()
    assert hasattr(module, "ENV_SPEC"), "env_spec.py must export ENV_SPEC"


def test_env_spec_has_entries() -> None:
    """ENV_SPEC must contain at least one entry."""
    module = _load_env_spec()
    assert len(module.ENV_SPEC) > 0, "ENV_SPEC is empty"
