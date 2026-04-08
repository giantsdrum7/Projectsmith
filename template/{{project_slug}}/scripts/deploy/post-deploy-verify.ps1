<#
.SYNOPSIS
    Post-deploy verification script for the platform infrastructure.

.DESCRIPTION
    Runs a series of checks to verify that deployed AWS resources are
    accessible and healthy. Each check uses phase-state output:
    NOT_RUN -> RUNNING -> PASS/FAIL.

    Checks: API Gateway health, DynamoDB table, Cognito pool, S3 buckets,
    AppConfig application.

.PARAMETER Namespace
    The deployment namespace (e.g., "portal-testclient-dev").

.PARAMETER Region
    AWS region where resources are deployed.

.PARAMETER DryRun
    If set, all checks report PASS without making AWS API calls.

.EXAMPLE
    .\post-deploy-verify.ps1 -Namespace "portal-testclient-dev" -Region "us-east-1"
    .\post-deploy-verify.ps1 -Namespace "portal-testclient-dev" -Region "us-east-1" -DryRun
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Namespace,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$checks = @(
    @{ Name = "API Gateway Health"; Status = "NOT_RUN" },
    @{ Name = "DynamoDB Table"; Status = "NOT_RUN" },
    @{ Name = "Cognito User Pool"; Status = "NOT_RUN" },
    @{ Name = "S3 Artifacts Bucket"; Status = "NOT_RUN" },
    @{ Name = "S3 Frontend Bucket"; Status = "NOT_RUN" },
    @{ Name = "AppConfig Application"; Status = "NOT_RUN" }
)

function Write-CheckStatus {
    param([string]$Name, [string]$Status)
    switch ($Status) {
        "NOT_RUN"  { Write-Host "[ NOT_RUN ] $Name" -ForegroundColor Gray }
        "RUNNING"  { Write-Host "[ RUNNING ] $Name" -ForegroundColor Yellow }
        "PASS"     { Write-Host "[ PASS    ] $Name" -ForegroundColor Green }
        "FAIL"     { Write-Host "[ FAIL    ] $Name" -ForegroundColor Red }
    }
}

function Invoke-Check {
    param(
        [string]$Name,
        [scriptblock]$Check
    )

    $idx = -1
    for ($i = 0; $i -lt $checks.Count; $i++) {
        if ($checks[$i].Name -eq $Name) { $idx = $i; break }
    }
    if ($idx -lt 0) { Write-Error "Unknown check: $Name"; return }

    $checks[$idx].Status = "RUNNING"
    Write-CheckStatus -Name $Name -Status "RUNNING"

    if ($DryRun) {
        $checks[$idx].Status = "PASS"
        Write-CheckStatus -Name $Name -Status "PASS"
        Write-Host "  (DRY RUN — skipped actual verification)" -ForegroundColor DarkGray
        return
    }

    try {
        & $Check
        $checks[$idx].Status = "PASS"
        Write-CheckStatus -Name $Name -Status "PASS"
    }
    catch {
        $checks[$idx].Status = "FAIL"
        Write-CheckStatus -Name $Name -Status "FAIL"
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Post-Deploy Verification ===" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace"
Write-Host "Region:    $Region"
if ($DryRun) { Write-Host "Mode:      DRY RUN" -ForegroundColor Yellow }
Write-Host ""

# --- Check: API Gateway Health ---
Invoke-Check -Name "API Gateway Health" -Check {
    $apis = aws apigateway get-rest-apis --region $Region --output json 2>&1 | ConvertFrom-Json
    $api = $apis.items | Where-Object { $_.name -eq "$Namespace-api" }
    if (-not $api) { throw "API Gateway '$Namespace-api' not found" }
    Write-Host "  Found API: $($api.name) (id: $($api.id))" -ForegroundColor DarkGray
}

# --- Check: DynamoDB Table ---
Invoke-Check -Name "DynamoDB Table" -Check {
    $table = aws dynamodb describe-table `
        --table-name "$Namespace-platform" `
        --region $Region `
        --output json 2>&1 | ConvertFrom-Json
    $status = $table.Table.TableStatus
    if ($status -ne "ACTIVE") { throw "Table status is '$status', expected 'ACTIVE'" }
    Write-Host "  Table: $Namespace-platform (status: $status)" -ForegroundColor DarkGray
}

# --- Check: Cognito User Pool ---
Invoke-Check -Name "Cognito User Pool" -Check {
    $pools = aws cognito-idp list-user-pools --max-results 60 --region $Region --output json 2>&1 | ConvertFrom-Json
    $pool = $pools.UserPools | Where-Object { $_.Name -eq "$Namespace-users" }
    if (-not $pool) { throw "Cognito User Pool '$Namespace-users' not found" }
    Write-Host "  Pool: $($pool.Name) (id: $($pool.Id))" -ForegroundColor DarkGray
}

# --- Check: S3 Artifacts Bucket ---
Invoke-Check -Name "S3 Artifacts Bucket" -Check {
    aws s3api head-bucket --bucket "$Namespace-artifacts" --region $Region 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "S3 bucket '$Namespace-artifacts' not accessible" }
    Write-Host "  Bucket: $Namespace-artifacts (accessible)" -ForegroundColor DarkGray
}

# --- Check: S3 Frontend Bucket ---
Invoke-Check -Name "S3 Frontend Bucket" -Check {
    aws s3api head-bucket --bucket "$Namespace-frontend" --region $Region 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "S3 bucket '$Namespace-frontend' not accessible" }
    Write-Host "  Bucket: $Namespace-frontend (accessible)" -ForegroundColor DarkGray
}

# --- Check: AppConfig Application ---
Invoke-Check -Name "AppConfig Application" -Check {
    $apps = aws appconfig list-applications --region $Region --output json 2>&1 | ConvertFrom-Json
    $appEntry = $apps.Items | Where-Object { $_.Name -eq "$Namespace-config" }
    if (-not $appEntry) { throw "AppConfig application '$Namespace-config' not found" }
    Write-Host "  AppConfig: $($appEntry.Name) (id: $($appEntry.Id))" -ForegroundColor DarkGray
}

# --- Summary ---
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$passCount = ($checks | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($checks | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $checks.Count

Write-Host "PASS: $passCount / $totalCount" -ForegroundColor $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })
Write-Host "FAIL: $failCount / $totalCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })

if ($failCount -gt 0) {
    Write-Host "`nFailed checks:" -ForegroundColor Red
    $checks | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`nAll checks passed." -ForegroundColor Green
exit 0
