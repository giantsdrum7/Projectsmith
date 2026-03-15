"""Generate .env.example and mode_defaults.json from env_spec.py."""

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
        print("ERROR: Could not find config/env_spec.py under src/", file=sys.stderr)
        sys.exit(1)

    spec_file = candidates[0] / "config" / "env_spec.py"
    spec = importlib.util.spec_from_file_location("env_spec", spec_file)
    module = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    spec.loader.exec_module(module)  # type: ignore[union-attr]
    return module


def main() -> None:
    """Generate environment template files from env_spec.py.

    # {{ project_name }} Environment Variables
    # Generated from src/{{ project_slug }}/config/env_spec.py
    """
    env_spec_module = _load_env_spec()
    env_spec = env_spec_module.ENV_SPEC  # type: ignore[attr-defined]
    print(f"Found {len(env_spec)} environment variables in spec.")
    print("Template generation not yet implemented.")
    # {% raw %}{{FILL: Implement .env.example and mode_defaults.json generation}}{% endraw %}


if __name__ == "__main__":
    main()
