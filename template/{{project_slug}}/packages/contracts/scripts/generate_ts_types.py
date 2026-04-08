#!/usr/bin/env python3
"""Generate JSON Schema and (optionally) TypeScript types from Pydantic models.

Pipeline:
  1. Import all Pydantic models from idi_platform_contracts
  2. Call model_json_schema() on each
  3. Write JSON Schema files to packages/contracts/generated/
  4. If json-schema-to-typescript (json2ts) is available, generate .d.ts files

Usage:
  python packages/contracts/scripts/generate_ts_types.py

The generated JSON Schema files are always produced. TypeScript generation
requires the npm package json-schema-to-typescript to be installed:
  npm install -g json-schema-to-typescript
"""

import json
import subprocess
import sys
from pathlib import Path

from pydantic import BaseModel


def discover_models() -> dict[str, type[BaseModel]]:
    """Import and collect all Pydantic models from the contracts package."""
    import idi_platform_contracts  # noqa: F811
    from idi_platform_contracts import manifest, sample

    models: dict[str, type[BaseModel]] = {}
    for module in [manifest, sample, idi_platform_contracts]:
        for name in dir(module):
            obj = getattr(module, name)
            if isinstance(obj, type) and issubclass(obj, BaseModel) and obj is not BaseModel:
                models[name] = obj
    return models


def main() -> None:
    output_dir = Path(__file__).resolve().parent.parent / "generated"
    output_dir.mkdir(exist_ok=True)

    models = discover_models()
    if not models:
        print("No Pydantic models found.", file=sys.stderr)
        sys.exit(1)

    print(f"Found {len(models)} model(s): {', '.join(models.keys())}")

    schema_files: list[Path] = []
    for name, model in models.items():
        schema = model.model_json_schema()
        schema_path = output_dir / f"{name}.schema.json"
        schema_path.write_text(json.dumps(schema, indent=2) + "\n")
        schema_files.append(schema_path)
        print(f"  Wrote {schema_path.relative_to(output_dir.parent)}")

    # Attempt TypeScript generation if json2ts is available
    json2ts = _find_json2ts()
    if json2ts:
        ts_dir = output_dir / "ts"
        ts_dir.mkdir(exist_ok=True)
        for schema_path in schema_files:
            ts_path = ts_dir / (schema_path.stem.replace(".schema", "") + ".d.ts")
            try:
                subprocess.run(
                    [json2ts, "--input", str(schema_path), "--output", str(ts_path)],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                print(f"  Wrote {ts_path.relative_to(output_dir.parent)}")
            except subprocess.CalledProcessError as e:
                print(f"  Warning: TypeScript generation failed for {schema_path.name}: {e.stderr}", file=sys.stderr)
    else:
        print("\n  json-schema-to-typescript not found — skipping .d.ts generation.")
        print("  Install with: npm install -g json-schema-to-typescript")


def _find_json2ts() -> str | None:
    """Check if json2ts CLI is available on PATH."""
    try:
        subprocess.run(["json2ts", "--help"], capture_output=True, check=True)
        return "json2ts"
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None


if __name__ == "__main__":
    main()
