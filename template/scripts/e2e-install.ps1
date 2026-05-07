#Requires -Version 7.0
<#
.SYNOPSIS
    Install Playwright browsers and Node dependencies for e2e tests.
.DESCRIPTION
    Runs npm install and installs Chromium inside apps/web/e2e/.
    Run this once after cloning or after updating @playwright/test.
.EXAMPLE
    pwsh scripts/e2e-install.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$E2EDir = Join-Path $RepoRoot "apps" "web" "e2e"

if (-not (Test-Path $E2EDir)) {
    Write-Error "e2e directory not found at $E2EDir. Was include_e2e_tests enabled at generation time?"
    exit 1
}

Push-Location $E2EDir
try {
    Write-Host "Installing Node dependencies..." -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "Installing Playwright browsers (chromium only)..." -ForegroundColor Cyan
    npx playwright install chromium --with-deps
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host ""
    Write-Host "Done. Run 'pwsh scripts/e2e-test.ps1' to execute the smoke test." -ForegroundColor Green
} finally {
    Pop-Location
}
