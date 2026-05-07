#!/usr/bin/env bash
# Regression test: assert Projectsmith renders single-level (no double-nesting).
#
# Locks in the v1.0.0 collapse fix where template/{{project_slug}}/ was
# flattened into template/ to eliminate emitted-project double-nesting.
#
# Usage:
#   scripts/dev/test-no-double-nest.sh [SLUG] [--keep-output]
#
# Examples:
#   scripts/dev/test-no-double-nest.sh
#   scripts/dev/test-no-double-nest.sh very_long_project_slug_for_testing
#   scripts/dev/test-no-double-nest.sh smoke --keep-output

set -euo pipefail

SLUG="${1:-smoke_no_nest}"
KEEP_OUTPUT=0
if [[ "${2:-}" == "--keep-output" ]]; then
    KEEP_OUTPUT=1
fi

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_BASE="$(mktemp -d -t projectsmith-no-nest.XXXXXXXX)"

echo "=== test-no-double-nest ==="
echo "Repo root: $REPO_ROOT"
echo "Temp dir:  $TEMP_BASE"
echo "Slug:      $SLUG"
echo

cleanup() {
    if [[ "$KEEP_OUTPUT" -eq 0 ]]; then
        rm -rf "$TEMP_BASE"
    else
        echo
        echo "Output preserved at: $TEMP_BASE"
    fi
}

if ! copier copy "$REPO_ROOT" "$TEMP_BASE" \
    --defaults --vcs-ref HEAD \
    --data "project_name=Smoke" \
    --data "project_slug=$SLUG" \
    --data "github_org=test-org" \
    --data "client_id=test" >/dev/null 2>&1; then
    echo "FAIL: copier copy failed"
    cleanup
    exit 1
fi

# Sentinel files expected DIRECTLY at the destination root after the v1.0.0 collapse.
SENTINELS=(
    "AGENTS.md"
    "CLAUDE.md"
    "CURSOR_RULES.md"
    "README.md"
    "pyproject.toml"
    "src"
    ".cursor"
    ".claude"
)

FAILURES=()
for s in "${SENTINELS[@]}"; do
    if [[ ! -e "$TEMP_BASE/$s" ]]; then
        FAILURES+=("missing at root: $s")
    fi
done

# Anti-sentinel: an extra <slug>/ dir at the destination root would mean the
# old double-nested layout regressed. The Python package directory lives
# inside src/, never at the destination root.
if [[ -d "$TEMP_BASE/$SLUG" ]]; then
    FAILURES+=("DOUBLE-NESTING DETECTED: extra '$SLUG/' directory found at destination root")
fi

# Also assert the Python package directory ended up where it belongs.
if [[ ! -d "$TEMP_BASE/src/$SLUG" ]]; then
    FAILURES+=("Python package directory missing: src/$SLUG/")
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo
    echo "FAIL: no-double-nest assertions failed:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    echo
    echo "Top-level entries observed:"
    ls -A "$TEMP_BASE" | sed 's/^/  /'
    cleanup
    exit 1
fi

echo
echo "PASS: rendered project is single-level (no double-nesting)."
echo "Verified ${#SENTINELS[@]} root sentinels and Python package at src/$SLUG/."

cleanup
exit 0
