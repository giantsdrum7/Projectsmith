#!/usr/bin/env bash
# Open the last Playwright HTML report in a browser.
# Run this after 'bash scripts/e2e-test.sh' to view results.
#
# Usage:
#   bash scripts/e2e-report.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
E2E_DIR="$REPO_ROOT/apps/web/e2e"

cd "$E2E_DIR"
npx playwright show-report
