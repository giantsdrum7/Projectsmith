#Requires -Version 7.0
<#
.SYNOPSIS
    Set environment variables for the specified mode.
.DESCRIPTION
    Authoritative script for entering offline, local-live, or prod mode.
    Loads defaults from mode_defaults.json and sets environment variables
    for the current PowerShell session.

    IMPORTANT: You must DOT-SOURCE this script so that environment variables
    are set in your current shell session. Running it normally (pwsh ...) spawns
    a child process whose env vars do not persist to the parent.
.PARAMETER Mode
    The environment mode: offline, local-live, or prod.
.PARAMETER Force
    Required for prod mode to prevent accidental production configuration.
.EXAMPLE
    . .\scripts\env\use-env.ps1 -Mode offline
.EXAMPLE
    . .\scripts\env\use-env.ps1 -Mode local-live
.EXAMPLE
    . .\scripts\env\use-env.ps1 -Mode prod -Force
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("offline", "local-live", "prod")]
    [string]$Mode,

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DefaultsFile = Join-Path $ScriptDir "mode_defaults.json"

# Safety: prod requires -Force
if ($Mode -eq "prod" -and -not $Force) {
    Write-Error "SAFETY: Prod mode requires -Force flag. This is intentional.`nUsage: .\use-env.ps1 -Mode prod -Force"
    exit 1
}

# Region lock
$ExpectedRegion = "{{ aws_region }}"

# Load defaults
if (-not (Test-Path $DefaultsFile)) {
    Write-Error "mode_defaults.json not found at $DefaultsFile. Run generate_env_templates.py first."
    exit 1
}

$defaults = Get-Content $DefaultsFile -Raw | ConvertFrom-Json
$modeDefaults = $defaults.$Mode

if (-not $modeDefaults) {
    Write-Error "Mode '$Mode' not found in mode_defaults.json."
    exit 1
}

Write-Host "=== Entering $Mode mode ===" -ForegroundColor Cyan

# Set environment variables
foreach ($prop in $modeDefaults.PSObject.Properties) {
    $env = $prop.Name
    $val = $prop.Value
    [System.Environment]::SetEnvironmentVariable($env, $val, "Process")
    Write-Host "  $env = $val"
}

# Region lock check
$currentRegion = [System.Environment]::GetEnvironmentVariable("AWS_REGION", "Process")
if ($currentRegion -and $currentRegion -ne $ExpectedRegion) {
    Write-Warning "AWS_REGION is '$currentRegion' but expected '$ExpectedRegion'. Cross-region calls may occur."
}

# Load .env overrides if present
$envFile = Join-Path (Split-Path -Parent (Split-Path -Parent $ScriptDir)) ".env"
if (Test-Path $envFile) {
    Write-Host "`n  Loading .env overrides..." -ForegroundColor DarkGray
    Get-Content $envFile | Where-Object { $_ -match '^\s*[A-Z_]+=.+' -and $_ -notmatch '^\s*#' } | ForEach-Object {
        $parts = $_ -split '=', 2
        [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        Write-Host "  (override) $($parts[0].Trim())"
    }
}

Write-Host "`n=== Mode: $Mode active ===" -ForegroundColor Green
Write-Host "Run 'pwsh scripts/verify-fast.ps1' to validate configuration."
