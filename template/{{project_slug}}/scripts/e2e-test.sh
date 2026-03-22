#!/usr/bin/env bash
# Run Playwright e2e tests.
# When BASE_URL is not set, tests that require a running web app will skip.
#
# Usage:
#   bash scripts/e2e-test.sh [BASE_URL]
#
# Examples:
#   bash scripts/e2e-test.sh
#   bash scripts/e2e-test.sh http://localhost:3000

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
E2E_DIR="$REPO_ROOT/apps/web/e2e"

if [ -n "${1:-}" ]; then
    export BASE_URL="$1"
fi

cd "$E2E_DIR"
npx playwright test
