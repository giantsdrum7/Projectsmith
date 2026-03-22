#Requires -Version 7.0
<#
.SYNOPSIS
    Run Playwright e2e tests.
.DESCRIPTION
    Runs all tests in apps/web/e2e/. When BASE_URL is not set, tests that
    require a running web app will skip rather than fail.
.PARAMETER BaseUrl
    Target URL for the test run (e.g. http://localhost:3000).
    Overrides the BASE_URL environment variable for this invocation.
.EXAMPLE
    pwsh scripts/e2e-test.ps1
.EXAMPLE
    pwsh scripts/e2e-test.ps1 -BaseUrl http://localhost:3000
#>

param(
    [string]$BaseUrl
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$E2EDir = Join-Path $RepoRoot "apps" "web" "e2e"

if ($BaseUrl) { $env:BASE_URL = $BaseUrl }

Push-Location $E2EDir
try {
    npx playwright test
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
