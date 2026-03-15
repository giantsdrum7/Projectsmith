#!/usr/bin/env bash
# Fast verification: lint + format + typecheck only (no tests)
# Use for quick feedback during development

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURE_LOG="$REPO_ROOT/.cursor/last-verify-failure.txt"
FAILURES=""

# Python targets for ruff and mypy — keep in sync with verify.sh, ci.yml,
# and pyproject.toml excludes.
TARGETS=(
    src/ tests/
    scripts/env/generate_env_templates.py
)

echo "=== VERIFY-FAST: Quick Check (lint + format + types) ==="

# Step 1: Lint
echo "[1/3] Running ruff check..."
RUFF_OUTPUT=$(uv run ruff check "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}RUFF:\n${RUFF_OUTPUT}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Step 2: Format check
echo "[2/3] Running ruff format --check..."
FMT_OUTPUT=$(uv run ruff format --check "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}RUFF-FORMAT:\n${FMT_OUTPUT}\n  Fix with: uv run ruff format ${TARGETS[*]}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Step 3: Type check
echo "[3/3] Running mypy..."
MYPY_OUTPUT=$(uv run mypy "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}MYPY:\n${MYPY_OUTPUT}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Results
if [ -n "$FAILURES" ]; then
    echo -e "VERIFY-FAST: FAIL\nTimestamp: $(date)\n\n${FAILURES}" > "$FAILURE_LOG"
    echo ""
    echo "=== VERIFY-FAST: FAIL ==="
    echo "Failures written to: $FAILURE_LOG"
    exit 1
else
    rm -f "$FAILURE_LOG"
    echo ""
    echo "=== VERIFY-FAST: PASS ==="
    exit 0
fi
