#Requires -Version 7.0
<#
.SYNOPSIS
    Append a new lesson entry to the appropriate Lessons_Learned file.
.DESCRIPTION
    Non-interactive helper for the Lessons_Learned system. Formats a structured
    entry with today's date and appends it to the correct category file.
    Creates the target file and folder if they do not exist.

    SAFETY: This script never reads or outputs environment variable values, secrets,
    or file contents. It only prints a success message and the path it wrote to.
.PARAMETER Category
    The lessons category: critical, notable, or quality-of-life. (Required)
.PARAMETER Title
    Short descriptive title for the lesson. (Required)
.PARAMETER Symptom
    What was observed — error message, alert, or unexpected behavior. (Optional)
.PARAMETER RootCause
    Why it happened. (Optional)
.PARAMETER Fix
    What was changed to resolve it. (Optional)
.PARAMETER Prevention
    What to do next time to avoid this entirely. (Optional)
.PARAMETER Links
    PR number, issue, commit SHA, or relevant file paths. (Optional)
.EXAMPLE
    pwsh scripts/dev/add-lesson.ps1 -Category notable -Title "uv sync needs --frozen in CI"
.EXAMPLE
    pwsh scripts/dev/add-lesson.ps1 `
        -Category critical `
        -Title "Gitleaks 403 on org repo PRs" `
        -Symptom "CI secret-scan failed with HTTP 403 on every PR" `
        -RootCause "gitleaks-action posts PR comments by default, requires pull-requests:write" `
        -Fix "Set GITLEAKS_ENABLE_COMMENTS=false and add pull-requests:read to job permissions" `
        -Prevention "Always set GITLEAKS_ENABLE_COMMENTS=false when adding gitleaks to workflows" `
        -Links ".github/workflows/ci.yml"
#>

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("critical", "notable", "quality-of-life")]
    [string]$Category,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [string]$Symptom    = "",
    [string]$RootCause  = "",
    [string]$Fix        = "",
    [string]$Prevention = "",
    [string]$Links      = ""
)

$ErrorActionPreference = "Stop"

# Resolve repo root (scripts/dev/ -> scripts/ -> repo root)
$RepoRoot    = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$LessonsDir  = Join-Path $RepoRoot "Lessons_Learned"
$TargetFile  = Join-Path $LessonsDir "$Category.md"

# ── Create folder/file if missing ────────────────────────────────────────────

if (-not (Test-Path $LessonsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $LessonsDir -Force | Out-Null
}

if (-not (Test-Path $TargetFile -PathType Leaf)) {
    $stub = @(
        "# Lessons Learned — $Category",
        "",
        "> Auto-created by add-lesson.ps1. See Lessons_Learned/critical.md for the",
        "> full template and entry format.",
        "",
        "---",
        "",
        "## Entries",
        ""
    ) -join "`n"
    Set-Content -Path $TargetFile -Value $stub -Encoding utf8
}

# ── Format the entry ─────────────────────────────────────────────────────────

$Today = Get-Date -Format "yyyy-MM-dd"

$symptomText    = if ($Symptom)    { $Symptom }    else { "_Not specified._" }
$rootCauseText  = if ($RootCause)  { $RootCause }  else { "_Not specified._" }
$fixText        = if ($Fix)        { $Fix }        else { "_Not specified._" }
$preventionText = if ($Prevention) { $Prevention } else { "_Not specified._" }
$linksText      = if ($Links)      { $Links }      else { "_None._" }

$entry = @(
    "",
    "### $Today — $Title",
    "",
    "**Symptom:** $symptomText  ",
    "**Root cause:** $rootCauseText  ",
    "**Fix:** $fixText  ",
    "**Prevention:** $preventionText  ",
    "**Links:** $linksText",
    ""
) -join "`n"

# ── Append ───────────────────────────────────────────────────────────────────

Add-Content -Path $TargetFile -Value $entry -Encoding utf8

Write-Host ""
Write-Host "Lesson appended successfully." -ForegroundColor Green
Write-Host "  Category : $Category"
Write-Host "  Title    : $Title"
Write-Host "  File     : $TargetFile"
Write-Host ""
