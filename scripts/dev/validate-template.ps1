#Requires -Version 7.0
<#
.SYNOPSIS
    Validate Projectsmith template by generating and checking preset projects.
.DESCRIPTION
    Generates projects from the Projectsmith Copier template using predefined
    presets (minimal, ai-core, full-stack) and runs a comprehensive validation
    suite on each: governance files, variable resolution, conditional modules,
    Python toolchain (ruff, mypy, pytest), and more.
.PARAMETER Preset
    Which preset(s) to validate: minimal, ai-core, full-stack, or all.
.PARAMETER OutputDir
    Base directory for generated output. Defaults to a temp directory.
.PARAMETER KeepOutput
    Keep generated output after validation (do not clean up).
.EXAMPLE
    pwsh scripts/dev/validate-template.ps1 -Preset all
.EXAMPLE
    pwsh scripts/dev/validate-template.ps1 -Preset minimal -KeepOutput
#>

param(
    [ValidateSet("minimal", "ai-core", "full-stack", "e2e", "all")]
    [string]$Preset = "all",

    [string]$OutputDir,

    [switch]$KeepOutput
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." "..")).Path

# ── Preset definitions ───────────────────────────────────────────────────────

$Presets = @{
    "minimal" = @{
        Slug = "test_minimal"
        Data = @(
            "--data", "project_name=TestMinimal",
            "--data", "project_slug=test_minimal",
            "--data", "project_description=Minimal preset validation",
            "--data", "github_org=test-org",
            "--data", "github_team_slug=core-team",
            "--data", "aws_region=us-east-1",
            "--data", "python_version=3.12",
            "--data", "license=MIT",
            "--data", "claude_code_model=claude-opus-4-6",
            "--data", "metadata_store=none",
            "--data", "llm_provider=none",
            "--data", "include_frontend=false",
            "--data", "include_infra=false",
            "--data", "include_observability=false",
            "--data", "include_security=false",
            "--data", "include_evals=false"
        )
        ExpectedPresent = @()
        ExpectedAbsent  = @("evals", "apps", "infra", "observability", "security", ".cursor/rules/frontend.mdc")
    }
    "ai-core" = @{
        Slug = "test_ai_core"
        Data = @(
            "--data", "project_name=TestAiCore",
            "--data", "project_slug=test_ai_core",
            "--data", "project_description=AI-core preset validation",
            "--data", "github_org=test-org",
            "--data", "github_team_slug=core-team",
            "--data", "aws_region=us-east-1",
            "--data", "python_version=3.12",
            "--data", "license=MIT",
            "--data", "claude_code_model=claude-opus-4-6",
            "--data", "metadata_store=dynamodb",
            "--data", "llm_provider=bedrock",
            "--data", "include_frontend=false",
            "--data", "include_infra=false",
            "--data", "include_observability=false",
            "--data", "include_security=false",
            "--data", "include_evals=true"
        )
        ExpectedPresent = @("evals")
        ExpectedAbsent  = @("apps", "infra", "observability", "security", ".cursor/rules/frontend.mdc")
    }
    "full-stack" = @{
        Slug = "test_full_stack"
        Data = @(
            "--data", "project_name=TestFullStack",
            "--data", "project_slug=test_full_stack",
            "--data", "project_description=Full-stack preset validation",
            "--data", "github_org=test-org",
            "--data", "github_team_slug=core-team",
            "--data", "aws_region=us-east-1",
            "--data", "python_version=3.12",
            "--data", "license=MIT",
            "--data", "claude_code_model=claude-opus-4-6",
            "--data", "metadata_store=dynamodb",
            "--data", "llm_provider=bedrock",
            "--data", "include_frontend=true",
            "--data", "include_infra=true",
            "--data", "include_observability=true",
            "--data", "include_security=true",
            "--data", "include_evals=true",
            "--data", "include_e2e_tests=false"
        )
        ExpectedPresent = @("evals", "apps", "infra", "observability", "security", ".cursor/rules/frontend.mdc")
        ExpectedAbsent  = @("apps/web/e2e", ".nvmrc", ".github/workflows/e2e.yml", "docs/testing-e2e.md")
    }
    "e2e" = @{
        Slug = "test_e2e"
        Data = @(
            "--data", "project_name=TestE2E",
            "--data", "project_slug=test_e2e",
            "--data", "project_description=E2E preset validation",
            "--data", "github_org=test-org",
            "--data", "github_team_slug=core-team",
            "--data", "aws_region=us-east-1",
            "--data", "python_version=3.12",
            "--data", "license=MIT",
            "--data", "claude_code_model=claude-opus-4-6",
            "--data", "metadata_store=none",
            "--data", "llm_provider=none",
            "--data", "include_frontend=true",
            "--data", "include_infra=false",
            "--data", "include_observability=false",
            "--data", "include_security=false",
            "--data", "include_evals=false",
            "--data", "include_e2e_tests=true"
        )
        ExpectedPresent = @(
            "apps/web/e2e",
            "apps/web/e2e/package.json",
            "apps/web/e2e/playwright.config.ts",
            "apps/web/e2e/tests/smoke.spec.ts",
            ".nvmrc",
            ".github/workflows/e2e.yml",
            "docs/testing-e2e.md",
            "scripts/e2e-install.ps1",
            "scripts/e2e-test.ps1"
        )
        ExpectedAbsent  = @("infra", "observability", "security", "evals")
    }
}

# ── Determine which presets to run ───────────────────────────────────────────

$PresetsToRun = if ($Preset -eq "all") {
    @("minimal", "ai-core", "full-stack", "e2e")
} else {
    @($Preset)
}

# ── Output directory ─────────────────────────────────────────────────────────

if (-not $OutputDir) {
    $OutputDir = Join-Path ([System.IO.Path]::GetTempPath()) "projectsmith-validate-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "=== Projectsmith Template Validation ===" -ForegroundColor Cyan
Write-Host "Repo root:  $RepoRoot"
Write-Host "Output dir: $OutputDir"
Write-Host "Presets:    $($PresetsToRun -join ', ')"
Write-Host ""

# ── Per-preset results tracking ──────────────────────────────────────────────

$AllResults = @{}
$AnyFailure = $false

foreach ($presetName in $PresetsToRun) {
    $presetDef = $Presets[$presetName]
    $presetSlug = $presetDef.Slug
    $presetOutputDir = Join-Path $OutputDir $presetName

    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "  Preset: $presetName" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""

    $results = [ordered]@{}
    $presetFailed = $false

    # ── Step 1: Generate project ─────────────────────────────────────────
    Write-Host "  [1/14] Generating project..." -ForegroundColor White
    if (Test-Path $presetOutputDir) {
        Remove-Item -Recurse -Force $presetOutputDir
    }
    New-Item -ItemType Directory -Path $presetOutputDir -Force | Out-Null

    $copierArgs = @("copy", $RepoRoot, $presetOutputDir, "--defaults", "--vcs-ref", "HEAD") + $presetDef.Data
    & copier @copierArgs 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAIL: copier copy failed (exit $LASTEXITCODE)" -ForegroundColor Red
        $results["generation"] = "FAIL"
        $presetFailed = $true
        $AllResults[$presetName] = $results
        $AnyFailure = $true
        continue
    }

    # Find the generated project directory
    $projectDir = Get-ChildItem -Path $presetOutputDir -Directory | Select-Object -First 1
    if (-not $projectDir) {
        Write-Host "    FAIL: No project directory found in $presetOutputDir" -ForegroundColor Red
        $results["generation"] = "FAIL"
        $presetFailed = $true
        $AllResults[$presetName] = $results
        $AnyFailure = $true
        continue
    }
    $projectPath = $projectDir.FullName
    $results["generation"] = "PASS"
    Write-Host "    PASS: Generated at $projectPath" -ForegroundColor Green

    # ── Step 2: Governance files ─────────────────────────────────────────
    Write-Host "  [2/14] Checking governance files..." -ForegroundColor White
    $requiredFiles = @("AGENTS.md", "CLAUDE.md", "CURSOR_RULES.md", "START_HERE.md", "README.md", "pyproject.toml", ".gitignore", "CODEOWNERS", "LICENSE")
    $missingFiles = $requiredFiles | Where-Object { -not (Test-Path (Join-Path $projectPath $_)) }
    if ($missingFiles) {
        Write-Host "    FAIL: Missing: $($missingFiles -join ', ')" -ForegroundColor Red
        $results["governance_files"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["governance_files"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 3: Variable resolution (project_name) ───────────────────────
    Write-Host "  [3/14] Checking project_name resolved..." -ForegroundColor White
    $unresolvedName = & rg --count-matches '{{ *project_name *}}' $projectPath -g '*.py' -g '*.md' -g '*.toml' -g '*.yml' -g '*.yaml' -g '*.json' 2>$null |
        Where-Object { $_ -notmatch 'FILL' -and $_ -notmatch '.copier-answers' }
    if ($unresolvedName) {
        Write-Host "    FAIL: Unresolved project_name found" -ForegroundColor Red
        $results["project_name_resolved"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["project_name_resolved"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 4: Variable resolution (project_slug) ───────────────────────
    Write-Host "  [4/14] Checking project_slug resolved..." -ForegroundColor White
    $unresolvedSlug = & rg --count-matches '{{ *project_slug *}}' $projectPath -g '*.py' -g '*.md' -g '*.toml' -g '*.yml' -g '*.yaml' -g '*.json' 2>$null |
        Where-Object { $_ -notmatch 'FILL' -and $_ -notmatch '.copier-answers' }
    if ($unresolvedSlug) {
        Write-Host "    FAIL: Unresolved project_slug found" -ForegroundColor Red
        $results["project_slug_resolved"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["project_slug_resolved"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 5: Variable resolution (github_org) ─────────────────────────
    Write-Host "  [5/14] Checking github_org resolved..." -ForegroundColor White
    $unresolvedOrg = & rg --count-matches '{{ *github_org *}}' $projectPath -g '*.py' -g '*.md' -g '*.toml' -g '*.yml' -g '*.yaml' -g '*.json' 2>$null |
        Where-Object { $_ -notmatch 'FILL' -and $_ -notmatch '.copier-answers' }
    if ($unresolvedOrg) {
        Write-Host "    FAIL: Unresolved github_org found" -ForegroundColor Red
        $results["github_org_resolved"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["github_org_resolved"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 6: FILL placeholders survived ───────────────────────────────
    Write-Host "  [6/14] Checking FILL placeholders survived..." -ForegroundColor White
    $fillCount = (& rg --count-matches 'FILL:' $projectPath -g '*.py' -g '*.md' -g '*.toml' -g '*.yml' -g '*.yaml' 2>$null |
        ForEach-Object { ($_ -split ':')[-1] } |
        Measure-Object -Sum).Sum
    if ($fillCount -gt 0) {
        $results["fill_placeholders"] = "PASS ($fillCount found)"
        Write-Host "    PASS: $fillCount placeholder(s) survived" -ForegroundColor Green
    } else {
        $results["fill_placeholders"] = "WARN (0 found)"
        Write-Host "    WARN: No FILL placeholders found" -ForegroundColor Yellow
    }

    # ── Step 7: .copier-answers.yml exists ───────────────────────────────
    Write-Host "  [7/14] Checking .copier-answers.yml..." -ForegroundColor White
    $answersFile = Join-Path $presetOutputDir ".copier-answers.yml"
    if (Test-Path $answersFile) {
        $results["copier_answers"] = "PASS"
        Write-Host "    PASS: Found at output root" -ForegroundColor Green
    } else {
        Write-Host "    FAIL: .copier-answers.yml not found at output root" -ForegroundColor Red
        $results["copier_answers"] = "FAIL"
        $presetFailed = $true
    }

    # ── Step 8: Conditional directories/files ────────────────────────────
    Write-Host "  [8/14] Checking conditional modules..." -ForegroundColor White
    $moduleOk = $true
    foreach ($item in $presetDef.ExpectedPresent) {
        $itemPath = Join-Path $projectPath $item
        if (-not (Test-Path $itemPath)) {
            Write-Host "    FAIL: Expected present: $item" -ForegroundColor Red
            $moduleOk = $false
        }
    }
    foreach ($item in $presetDef.ExpectedAbsent) {
        $itemPath = Join-Path $projectPath $item
        if (Test-Path $itemPath) {
            Write-Host "    FAIL: Expected absent: $item" -ForegroundColor Red
            $moduleOk = $false
        }
    }
    if ($moduleOk) {
        $results["conditional_modules"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    } else {
        $results["conditional_modules"] = "FAIL"
        $presetFailed = $true
    }

    # ── Step 9: uv venv + lock + sync ────────────────────────────────────
    Write-Host "  [9/14] Setting up Python environment..." -ForegroundColor White
    Push-Location $projectPath
    try {
        & uv venv 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "uv venv failed" }
        & uv lock 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "uv lock failed" }
        & uv sync --dev 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "uv sync --dev failed" }
        $results["uv_setup"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    } catch {
        Write-Host "    FAIL: $_" -ForegroundColor Red
        $results["uv_setup"] = "FAIL"
        $presetFailed = $true
        Pop-Location
        $AllResults[$presetName] = $results
        $AnyFailure = $true
        continue
    }

    # ── Step 10: ruff check ──────────────────────────────────────────────
    Write-Host "  [10/14] Running ruff check..." -ForegroundColor White
    $ruffOut = & uv run ruff check src/ tests/ 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAIL:" -ForegroundColor Red
        $ruffOut | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        $results["ruff_check"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["ruff_check"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 11: ruff format --check ─────────────────────────────────────
    Write-Host "  [11/14] Running ruff format --check..." -ForegroundColor White
    $ruffFmtOut = & uv run ruff format --check src/ tests/ 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAIL:" -ForegroundColor Red
        $ruffFmtOut | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        $results["ruff_format"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["ruff_format"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 12: mypy ────────────────────────────────────────────────────
    Write-Host "  [12/14] Running mypy..." -ForegroundColor White
    $mypyOut = & uv run mypy src/ tests/ 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAIL:" -ForegroundColor Red
        $mypyOut | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        $results["mypy"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["mypy"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 13: pytest ──────────────────────────────────────────────────
    Write-Host "  [13/14] Running pytest..." -ForegroundColor White
    $pytestOut = & uv run pytest tests/ -v 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    FAIL:" -ForegroundColor Red
        $pytestOut | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        $results["pytest"] = "FAIL"
        $presetFailed = $true
    } else {
        $results["pytest"] = "PASS"
        Write-Host "    PASS" -ForegroundColor Green
    }

    # ── Step 14: LICENSE + settings.json ─────────────────────────────────
    Write-Host "  [14/14] Checking LICENSE and .claude/settings.json..." -ForegroundColor White
    $licenseContent = Get-Content (Join-Path $projectPath "LICENSE") -Raw -ErrorAction SilentlyContinue
    if ($licenseContent -match "MIT License") {
        $results["license_content"] = "PASS"
        Write-Host "    LICENSE: PASS (MIT)" -ForegroundColor Green
    } else {
        $results["license_content"] = "FAIL"
        Write-Host "    LICENSE: FAIL (expected MIT)" -ForegroundColor Red
        $presetFailed = $true
    }

    $settingsPath = Join-Path $projectPath ".claude" "settings.json"
    if (Test-Path $settingsPath) {
        $settingsJson = Get-Content $settingsPath -Raw | ConvertFrom-Json
        if ($settingsJson.model -eq "claude-opus-4-6") {
            $results["settings_model"] = "PASS"
            Write-Host "    settings.json model: PASS (claude-opus-4-6)" -ForegroundColor Green
        } else {
            $results["settings_model"] = "FAIL (got: $($settingsJson.model))"
            Write-Host "    settings.json model: FAIL (got: $($settingsJson.model))" -ForegroundColor Red
            $presetFailed = $true
        }
    } else {
        $results["settings_model"] = "FAIL (file missing)"
        Write-Host "    settings.json: FAIL (not found)" -ForegroundColor Red
        $presetFailed = $true
    }

    Pop-Location

    if ($presetFailed) { $AnyFailure = $true }
    $AllResults[$presetName] = $results
    Write-Host ""
}

# ── Summary ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║              VALIDATION SUMMARY                         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

foreach ($presetName in $PresetsToRun) {
    $results = $AllResults[$presetName]
    $allPass = ($results.Values | Where-Object { $_ -match "FAIL" }).Count -eq 0
    $statusIcon = if ($allPass) { "PASS" } else { "FAIL" }
    $color = if ($allPass) { "Green" } else { "Red" }

    Write-Host "  [$statusIcon] $presetName" -ForegroundColor $color
    foreach ($check in $results.GetEnumerator()) {
        $checkColor = if ($check.Value -match "PASS") { "Green" } elseif ($check.Value -match "WARN") { "Yellow" } else { "Red" }
        Write-Host "       $($check.Key): $($check.Value)" -ForegroundColor $checkColor
    }
    Write-Host ""
}

# ── Cleanup ──────────────────────────────────────────────────────────────────

if (-not $KeepOutput -and -not $AnyFailure) {
    Write-Host "Cleaning up output directory..." -ForegroundColor DarkGray
    Remove-Item -Recurse -Force $OutputDir -ErrorAction SilentlyContinue
} else {
    Write-Host "Output preserved at: $OutputDir" -ForegroundColor DarkGray
}

if ($AnyFailure) {
    Write-Host ""
    Write-Host "VALIDATION FAILED — one or more presets had failures." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "ALL PRESETS PASSED" -ForegroundColor Green
    exit 0
}
