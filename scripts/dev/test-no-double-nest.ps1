#Requires -Version 7.0
<#
.SYNOPSIS
    Regression test: assert Projectsmith renders single-level (no double-nesting).

.DESCRIPTION
    Generates a throwaway project from the local template into a temp directory
    and asserts that scaffold files (AGENTS.md, src/, pyproject.toml, etc.)
    appear DIRECTLY at the destination root — not inside an extra
    project_slug-named subdirectory.

    Locks in the v1.1.0 collapse fix where template/{{project_slug}}/ was
    flattened into template/ to eliminate emitted-project double-nesting.

.PARAMETER Slug
    project_slug to generate with. Defaults to a short slug; pass a long one
    when chaining with the long-slug regression net.

.PARAMETER KeepOutput
    Keep the temp directory after the run (useful for debugging).

.EXAMPLE
    pwsh scripts/dev/test-no-double-nest.ps1
.EXAMPLE
    pwsh scripts/dev/test-no-double-nest.ps1 -Slug very_long_project_slug_for_testing
#>

param(
    [string]$Slug = "smoke_no_nest",
    [switch]$KeepOutput
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." "..")).Path

$tempBase = Join-Path ([System.IO.Path]::GetTempPath()) ("projectsmith-no-nest-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random))
New-Item -ItemType Directory -Path $tempBase -Force | Out-Null

Write-Host "=== test-no-double-nest ===" -ForegroundColor Cyan
Write-Host "Repo root: $RepoRoot"
Write-Host "Temp dir:  $tempBase"
Write-Host "Slug:      $Slug"
Write-Host ""

$copierArgs = @(
    "copy", $RepoRoot, $tempBase,
    "--defaults", "--vcs-ref", "HEAD",
    "--data", "project_name=Smoke",
    "--data", "project_slug=$Slug",
    "--data", "github_org=test-org",
    "--data", "client_id=test"
)

Write-Host "Running: copier $($copierArgs -join ' ')" -ForegroundColor DarkGray
& copier @copierArgs 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: copier copy exited $LASTEXITCODE" -ForegroundColor Red
    if (-not $KeepOutput) { Remove-Item -Recurse -Force $tempBase -ErrorAction SilentlyContinue }
    exit 1
}

# Sentinel files expected DIRECTLY at the destination root after the v1.1.0 collapse.
$sentinels = @(
    "AGENTS.md",
    "CLAUDE.md",
    "CURSOR_RULES.md",
    "README.md",
    "pyproject.toml",
    "src",
    ".cursor",
    ".claude"
)

$failures = @()
foreach ($s in $sentinels) {
    $p = Join-Path $tempBase $s
    if (-not (Test-Path $p)) {
        $failures += "missing at root: $s"
    }
}

# Anti-sentinel: an extra <slug>/ dir at the destination root would mean the
# old double-nested layout regressed. The Python package directory lives
# inside src/, never at the destination root.
$nestedRegression = Join-Path $tempBase $Slug
if (Test-Path $nestedRegression) {
    $failures += "DOUBLE-NESTING DETECTED: extra '$Slug/' directory found at destination root"
}

# Also assert the Python package directory ended up where it belongs.
$pkgDir = Join-Path $tempBase "src" $Slug
if (-not (Test-Path $pkgDir)) {
    $failures += "Python package directory missing: src/$Slug/"
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "FAIL: no-double-nest assertions failed:" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "  - $f" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Top-level entries observed:" -ForegroundColor Yellow
    Get-ChildItem $tempBase -Force | ForEach-Object { Write-Host "  $($_.Name)" }
    if (-not $KeepOutput) { Remove-Item -Recurse -Force $tempBase -ErrorAction SilentlyContinue }
    exit 1
}

Write-Host ""
Write-Host "PASS: rendered project is single-level (no double-nesting)." -ForegroundColor Green
Write-Host "Verified $($sentinels.Count) root sentinels and Python package at src/$Slug/." -ForegroundColor Green

if ($KeepOutput) {
    Write-Host ""
    Write-Host "Output preserved at: $tempBase" -ForegroundColor DarkGray
} else {
    Remove-Item -Recurse -Force $tempBase -ErrorAction SilentlyContinue
}

exit 0
