#!/usr/bin/env bash
# Full verification gate: lint + typecheck + tests
# Writes failures to .cursor/last-verify-failure.txt
# Exit code 0 = PASS, non-zero = FAIL

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURE_LOG="$REPO_ROOT/.cursor/last-verify-failure.txt"
FAILURES=""
START_TIME=$(date +%s)

# Python targets for ruff and mypy — keep in sync with verify-fast.sh,
# ci.yml, and pyproject.toml excludes.
TARGETS=(
    src/ tests/
    scripts/env/generate_env_templates.py
)

echo "=== VERIFY: Full Verification Gate ==="
echo "Started: $(date)"
echo ""

# Step 1: Lint
echo "[1/4] Running ruff check..."
RUFF_OUTPUT=$(uv run ruff check "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}RUFF:\n${RUFF_OUTPUT}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Step 2: Format check
echo "[2/4] Running ruff format --check..."
FMT_OUTPUT=$(uv run ruff format --check "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}RUFF-FORMAT:\n${FMT_OUTPUT}\n  Fix with: uv run ruff format ${TARGETS[*]}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Step 3: Type check
echo "[3/4] Running mypy..."
MYPY_OUTPUT=$(uv run mypy "${TARGETS[@]}" 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}MYPY:\n${MYPY_OUTPUT}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Step 4: Tests
echo "[4/4] Running pytest..."
PYTEST_OUTPUT=$(uv run pytest tests/ --tb=short -q 2>&1)
if [ $? -ne 0 ]; then
    FAILURES="${FAILURES}PYTEST:\n${PYTEST_OUTPUT}\n\n"
    echo "  FAIL"
else
    echo "  PASS"
fi

# Results
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo ""

if [ -n "$FAILURES" ]; then
    echo -e "VERIFY: FAIL\nTimestamp: $(date)\nDuration: ${DURATION}s\n\n${FAILURES}" > "$FAILURE_LOG"
    echo "=== VERIFY: FAIL ==="
    echo "Failures written to: $FAILURE_LOG"
    exit 1
else
    rm -f "$FAILURE_LOG"
    echo "=== VERIFY: PASS ==="
    echo "Duration: ${DURATION}s"
    exit 0
fi
