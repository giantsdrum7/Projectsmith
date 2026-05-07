#!/usr/bin/env bash
# Open Playwright UI mode for interactive test exploration.
# Useful for debugging tests and stepping through actions interactively.
#
# Usage:
#   bash scripts/e2e-ui.sh [BASE_URL]
#
# Examples:
#   bash scripts/e2e-ui.sh
#   bash scripts/e2e-ui.sh http://localhost:3000

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
E2E_DIR="$REPO_ROOT/apps/web/e2e"

if [ -n "${1:-}" ]; then
    export BASE_URL="$1"
fi

cd "$E2E_DIR"
npx playwright test --ui
