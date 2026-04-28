#!/usr/bin/env bash
#
# Post-deploy verification script for the platform infrastructure.
# Bash equivalent for CI/Linux environments.
#
# Usage:
#   ./post-deploy-verify.sh --namespace "portal-testclient-dev" --region "us-east-1"
#   ./post-deploy-verify.sh --namespace "portal-testclient-dev" --region "us-east-1" --dry-run

set -euo pipefail

NAMESPACE=""
REGION=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace) NAMESPACE="$2"; shift 2 ;;
        --region) REGION="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$NAMESPACE" || -z "$REGION" ]]; then
    echo "Usage: $0 --namespace <namespace> --region <region> [--dry-run]"
    exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0
FAILED_CHECKS=()

print_status() {
    local name="$1" status="$2"
    case "$status" in
        NOT_RUN) echo -e "[ NOT_RUN ] $name" ;;
        RUNNING) echo -e "[ RUNNING ] $name" ;;
        PASS)    echo -e "[ PASS    ] \033[32m$name\033[0m" ;;
        FAIL)    echo -e "[ FAIL    ] \033[31m$name\033[0m" ;;
    esac
}

run_check() {
    local name="$1"
    shift
    TOTAL_COUNT=$((TOTAL_COUNT + 1))

    print_status "$name" "RUNNING"

    if [[ "$DRY_RUN" == "true" ]]; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_status "$name" "PASS"
        echo "  (DRY RUN — skipped actual verification)"
        return
    fi

    if "$@" 2>/dev/null; then
        PASS_COUNT=$((PASS_COUNT + 1))
        print_status "$name" "PASS"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        FAILED_CHECKS+=("$name")
        print_status "$name" "FAIL"
    fi
}

check_api_gateway() {
    local api_id
    api_id=$(aws apigateway get-rest-apis --region "$REGION" --output json \
        | python3 -c "import sys,json; apis=json.load(sys.stdin)['items']; print(next(a['id'] for a in apis if a['name']=='${NAMESPACE}-api'))")
    echo "  Found API: ${NAMESPACE}-api (id: $api_id)"
}

{% if metadata_store == "dynamodb" %}
check_dynamodb_table() {
    local status
    status=$(aws dynamodb describe-table \
        --table-name "${NAMESPACE}-platform" \
        --region "$REGION" \
        --query 'Table.TableStatus' \
        --output text)
    [[ "$status" == "ACTIVE" ]]
    echo "  Table: ${NAMESPACE}-platform (status: $status)"
}
{% endif %}

check_cognito_pool() {
    local pool_id
    pool_id=$(aws cognito-idp list-user-pools --max-results 60 --region "$REGION" --output json \
        | python3 -c "import sys,json; pools=json.load(sys.stdin)['UserPools']; print(next(p['Id'] for p in pools if p['Name']=='${NAMESPACE}-users'))")
    echo "  Pool: ${NAMESPACE}-users (id: $pool_id)"
}

check_s3_bucket() {
    local bucket_name="$1"
    aws s3api head-bucket --bucket "$bucket_name" --region "$REGION"
    echo "  Bucket: $bucket_name (accessible)"
}

check_appconfig() {
    local app_id
    app_id=$(aws appconfig list-applications --region "$REGION" --output json \
        | python3 -c "import sys,json; apps=json.load(sys.stdin)['Items']; print(next(a['Id'] for a in apps if a['Name']=='${NAMESPACE}-config'))")
    echo "  AppConfig: ${NAMESPACE}-config (id: $app_id)"
}

echo ""
echo "=== Post-Deploy Verification ==="
echo "Namespace: $NAMESPACE"
echo "Region:    $REGION"
if [[ "$DRY_RUN" == "true" ]]; then echo "Mode:      DRY RUN"; fi
echo ""

run_check "API Gateway Health" check_api_gateway
{% if metadata_store == "dynamodb" %}
run_check "DynamoDB Table" check_dynamodb_table
{% endif %}
run_check "Cognito User Pool" check_cognito_pool
run_check "S3 Artifacts Bucket" check_s3_bucket "${NAMESPACE}-artifacts"
run_check "S3 Frontend Bucket" check_s3_bucket "${NAMESPACE}-frontend"
run_check "AppConfig Application" check_appconfig

echo ""
echo "=== Summary ==="
echo "PASS: $PASS_COUNT / $TOTAL_COUNT"
echo "FAIL: $FAIL_COUNT / $TOTAL_COUNT"

if [[ $FAIL_COUNT -gt 0 ]]; then
    echo ""
    echo "Failed checks:"
    for name in "${FAILED_CHECKS[@]}"; do
        echo "  - $name"
    done
    exit 1
fi

echo ""
echo "All checks passed."
exit 0
