"""Project path conventions.

Centralizes path construction so modules don't hardcode paths.
"""

from __future__ import annotations

from pathlib import Path

# Project root is 3 levels up from this file: src/<slug>/config/paths.py
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent

SRC_DIR = PROJECT_ROOT / "src"
TESTS_DIR = PROJECT_ROOT / "tests"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
DOCS_DIR = PROJECT_ROOT / "docs"
EVALS_DIR = PROJECT_ROOT / "evals"
