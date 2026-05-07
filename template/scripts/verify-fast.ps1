#Requires -Version 7.0
<#
.SYNOPSIS
    Fast verification: lint + typecheck only (no tests).
.DESCRIPTION
    Runs ruff and mypy. Writes failures to .cursor/last-verify-failure.txt.
    Use this for quick feedback during development. Run full verify.ps1 before pushing.
.EXAMPLE
    pwsh scripts/verify-fast.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$FailureLog = Join-Path $RepoRoot ".cursor" "last-verify-failure.txt"

# Python targets for ruff and mypy — keep in sync with verify.ps1, ci.yml,
# and pyproject.toml excludes.
$LintTargets = @(
    "src/", "tests/",
    "scripts/env/generate_env_templates.py"
)

$failures = @()

Write-Host "=== VERIFY-FAST: Quick Check (lint + format + types) ===" -ForegroundColor Cyan

# Step 1: Lint
Write-Host "[1/3] Running ruff check..." -ForegroundColor Yellow
try {
    $ruffOutput = & uv run ruff check $LintTargets 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures += "RUFF: $ruffOutput"
        Write-Host "  FAIL" -ForegroundColor Red
    } else {
        Write-Host "  PASS" -ForegroundColor Green
    }
} catch {
    $failures += "RUFF: $_"
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Step 2: Format check
Write-Host "[2/3] Running ruff format --check..." -ForegroundColor Yellow
try {
    $fmtOutput = & uv run ruff format --check $LintTargets 2>&1
    if ($LASTEXITCODE -ne 0) {
        $fmtFix = $LintTargets -join " "
        $failures += "RUFF-FORMAT: $fmtOutput`n  Fix with: uv run ruff format $fmtFix"
        Write-Host "  FAIL" -ForegroundColor Red
    } else {
        Write-Host "  PASS" -ForegroundColor Green
    }
} catch {
    $failures += "RUFF-FORMAT: $_"
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Step 3: Type check
Write-Host "[3/3] Running mypy..." -ForegroundColor Yellow
try {
    # NOTE: invoke mypy via `python -m mypy` rather than `uv run mypy` so that
    # uv's script-path canonicalization (which corrupts the mypy console-script
    # entry point on Windows under uv >= 0.7.20) is bypassed. Behaviour is
    # equivalent: still runs inside the uv-managed venv, just dispatched
    # through the interpreter instead of the Scripts/ stub.
    $mypyOutput = & uv run python -m mypy $LintTargets 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures += "MYPY: $mypyOutput"
        Write-Host "  FAIL" -ForegroundColor Red
    } else {
        Write-Host "  PASS" -ForegroundColor Green
    }
} catch {
    $failures += "MYPY: $_"
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Results
if ($failures.Count -gt 0) {
    $failureText = "VERIFY-FAST: FAIL`nTimestamp: $(Get-Date)`n`n" + ($failures -join "`n`n")
    $failureText | Out-File -FilePath $FailureLog -Encoding utf8
    Write-Host "`n=== VERIFY-FAST: FAIL ===" -ForegroundColor Red
    Write-Host "Failures written to: $FailureLog"
    exit 1
} else {
    if (Test-Path $FailureLog) { Remove-Item $FailureLog -Force }
    Write-Host "`n=== VERIFY-FAST: PASS ===" -ForegroundColor Green
    exit 0
}
