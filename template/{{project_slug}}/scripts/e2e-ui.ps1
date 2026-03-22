#Requires -Version 7.0
<#
.SYNOPSIS
    Open Playwright UI mode for interactive test exploration.
.DESCRIPTION
    Launches the Playwright Test UI in apps/web/e2e/. Useful for
    debugging tests and stepping through actions interactively.
.PARAMETER BaseUrl
    Target URL (e.g. http://localhost:3000). Overrides BASE_URL.
.EXAMPLE
    pwsh scripts/e2e-ui.ps1
.EXAMPLE
    pwsh scripts/e2e-ui.ps1 -BaseUrl http://localhost:3000
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
    npx playwright test --ui
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
