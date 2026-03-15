#Requires -Version 7.0
<#
.SYNOPSIS
    Full verification gate: lint + typecheck + tests.
.DESCRIPTION
    Runs ruff, mypy, and pytest. Writes failures to .cursor/last-verify-failure.txt.
    Exit code 0 = PASS, non-zero = FAIL.
.EXAMPLE
    pwsh scripts/verify.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$FailureLog = Join-Path $RepoRoot ".cursor" "last-verify-failure.txt"

# Python targets for ruff and mypy — keep in sync with verify-fast.ps1,
# ci.yml, and pyproject.toml excludes.
$LintTargets = @(
    "src/", "tests/",
    "scripts/env/generate_env_templates.py"
)

$failures = @()
$startTime = Get-Date

Write-Host "=== VERIFY: Full Verification Gate ===" -ForegroundColor Cyan
Write-Host "Started: $startTime"
Write-Host ""

# Step 1: Lint
Write-Host "[1/4] Running ruff check..." -ForegroundColor Yellow
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
Write-Host "[2/4] Running ruff format --check..." -ForegroundColor Yellow
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
Write-Host "[3/4] Running mypy..." -ForegroundColor Yellow
try {
    $mypyOutput = & uv run mypy $LintTargets 2>&1
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

# Step 4: Tests
Write-Host "[4/4] Running pytest..." -ForegroundColor Yellow
try {
    $pytestOutput = & uv run pytest tests/ --tb=short -q 2>&1
    if ($LASTEXITCODE -ne 0) {
        $failures += "PYTEST: $pytestOutput"
        Write-Host "  FAIL" -ForegroundColor Red
    } else {
        Write-Host "  PASS" -ForegroundColor Green
    }
} catch {
    $failures += "PYTEST: $_"
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

# Results
$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host ""

if ($failures.Count -gt 0) {
    $failureText = "VERIFY: FAIL`nTimestamp: $endTime`nDuration: $duration`n`n" + ($failures -join "`n`n")
    $failureText | Out-File -FilePath $FailureLog -Encoding utf8
    Write-Host "=== VERIFY: FAIL ===" -ForegroundColor Red
    Write-Host "Failures written to: $FailureLog"
    exit 1
} else {
    if (Test-Path $FailureLog) { Remove-Item $FailureLog -Force }
    Write-Host "=== VERIFY: PASS ===" -ForegroundColor Green
    Write-Host "Duration: $duration"
    exit 0
}
