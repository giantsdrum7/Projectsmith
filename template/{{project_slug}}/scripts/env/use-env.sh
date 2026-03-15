#!/usr/bin/env bash
# Set environment variables for the specified mode.
# Usage: source scripts/env/use-env.sh --mode offline
#        source scripts/env/use-env.sh --mode local-live
#        source scripts/env/use-env.sh --mode prod --force

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULTS_FILE="$SCRIPT_DIR/mode_defaults.json"
EXPECTED_REGION="{{ aws_region }}"

MODE=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode) MODE="$2"; shift 2 ;;
        --force) FORCE=true; shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$MODE" ]]; then
    echo "Usage: source use-env.sh --mode <offline|local-live|prod> [--force]"
    return 1 2>/dev/null || exit 1
fi

if [[ "$MODE" != "offline" && "$MODE" != "local-live" && "$MODE" != "prod" ]]; then
    echo "ERROR: Invalid mode '$MODE'. Must be: offline, local-live, or prod"
    return 1 2>/dev/null || exit 1
fi

# Safety: prod requires --force
if [[ "$MODE" == "prod" && "$FORCE" != "true" ]]; then
    echo "SAFETY: Prod mode requires --force flag. This is intentional."
    echo "Usage: source use-env.sh --mode prod --force"
    return 1 2>/dev/null || exit 1
fi

if [[ ! -f "$DEFAULTS_FILE" ]]; then
    echo "ERROR: mode_defaults.json not found. Run generate_env_templates.py first."
    return 1 2>/dev/null || exit 1
fi

echo "=== Entering $MODE mode ==="

# Parse and export variables from mode_defaults.json using python
if command -v python3 &>/dev/null; then
    eval "$(python3 -c "
import json, sys
with open('$DEFAULTS_FILE') as f:
    data = json.load(f)
mode_data = data.get('$MODE', {})
for k, v in mode_data.items():
    print(f'export {k}=\"{v}\"')
")"
else
    echo "WARNING: python3 not found. Set variables manually from $DEFAULTS_FILE."
fi

# Region lock check
if [[ -n "${AWS_REGION:-}" && "$AWS_REGION" != "$EXPECTED_REGION" ]]; then
    echo "WARNING: AWS_REGION is '$AWS_REGION' but expected '$EXPECTED_REGION'."
fi

# Load .env overrides if present
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [[ -f "$REPO_ROOT/.env" ]]; then
    echo "  Loading .env overrides..."
    set -a
    source "$REPO_ROOT/.env"
    set +a
fi

echo "=== Mode: $MODE active ==="
echo "Run 'bash scripts/verify-fast.sh' to validate configuration."
