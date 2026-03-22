#!/usr/bin/env bash
# Install Playwright browsers and Node dependencies for e2e tests.
# Run once after cloning or after updating @playwright/test.
#
# Usage:
#   bash scripts/e2e-install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
E2E_DIR="$REPO_ROOT/apps/web/e2e"

if [ ! -d "$E2E_DIR" ]; then
    echo "Error: e2e directory not found at $E2E_DIR. Was include_e2e_tests enabled at generation time?" >&2
    exit 1
fi

cd "$E2E_DIR"

echo "Installing Node dependencies..."
npm install

echo "Installing Playwright browsers (chromium only)..."
npx playwright install chromium --with-deps

echo ""
echo "Done. Run 'bash scripts/e2e-test.sh' to execute the smoke test."
