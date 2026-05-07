"""Contract test: human-only governance files exist."""

from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

REQUIRED_FILES = [
    "AGENTS.md",
    "CLAUDE.md",
    "CURSOR_RULES.md",
    "START_HERE.md",
    "README.md",
    "pyproject.toml",
    ".gitignore",
    "CODEOWNERS",
]


def test_governance_files_exist() -> None:
    """All required governance files must be present at repo root."""
    missing = [f for f in REQUIRED_FILES if not (REPO_ROOT / f).exists()]
    assert not missing, f"Missing governance files: {missing}"
