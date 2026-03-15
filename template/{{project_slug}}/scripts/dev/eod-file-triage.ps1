#Requires -Version 7.0
<#
.SYNOPSIS
    End-of-day file organizer — scan for misplaced/untracked files.
.DESCRIPTION
    Scans git status and recent modifications for untracked or misplaced files.
    Classifies them against an allowlist and produces a move-plan table.
    Dry-run by default; only moves on -Apply with confirmation.
.PARAMETER DryRun
    Preview move plan without executing (default).
.PARAMETER Apply
    Execute the move plan (requires confirmation).
.PARAMETER Out
    Custom proof bundle output directory.
.PARAMETER Format
    Output format: json or text (default: text).
.EXAMPLE
    pwsh scripts/dev/eod-file-triage.ps1
    pwsh scripts/dev/eod-file-triage.ps1 -Apply
    pwsh scripts/dev/eod-file-triage.ps1 -Format json
#>

param(
    [switch]$DryRun,
    [switch]$Apply,
    [string]$Out,
    [ValidateSet("json", "text")]
    [string]$Format = "text"
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

if (-not $Apply) { $DryRun = $true }

# ── Protected files: never moved ─────────────────────────────────────────────

$ProtectedFiles = @(
    "CLAUDE.md", "AGENTS.md", "README.md", "CURSOR_RULES.md",
    "START_HERE.md", "REPO_MAP.md",
    "pyproject.toml", "uv.lock",
    ".gitignore", ".cursorignore", ".pre-commit-config.yaml", "CODEOWNERS",
    "start_up_guide.md", "start_up_prompt.md", "continue.md",
    ".env.example", ".env.local.example"
)

$ProtectedExtensionsInRoot = @(".toml", ".cfg", ".ini", ".yaml", ".yml")

# Directories that are considered "correct homes" — files here are not triaged
$WellKnownPrefixes = @(
    "src/", "tests/", "docs/", "scripts/", "evals/",
    "infra/", "apps/",
    ".github/", ".cursor/", ".claude/",
    "Lessons_Learned/"
)

# ── Helpers ──────────────────────────────────────────────────────────────────

function Test-GitRepo {
    Push-Location $RepoRoot
    try {
        $null = git rev-parse --is-inside-work-tree 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
}

function Test-IsProtected {
    param([string]$RelativePath)

    $fileName = Split-Path -Leaf $RelativePath
    if ($fileName -in $ProtectedFiles) { return $true }

    $parentDir = Split-Path -Parent $RelativePath
    $extension = [System.IO.Path]::GetExtension($fileName)
    $isRoot = [string]::IsNullOrEmpty($parentDir) -or $parentDir -eq "."
    if ($isRoot -and $extension -in $ProtectedExtensionsInRoot) { return $true }

    return $false
}

function Test-AlreadyCorrect {
    param([string]$RelativePath)

    $normalized = $RelativePath.Replace("\", "/")
    foreach ($prefix in $WellKnownPrefixes) {
        if ($normalized.StartsWith($prefix)) { return $true }
    }
    return $false
}

function Test-DirectoryExists {
    param([string]$DirPath)
    return Test-Path (Join-Path $RepoRoot $DirPath) -PathType Container
}

function Get-SuggestedLocation {
    <#
    .SYNOPSIS
        Classify a file and return a suggested destination, or $null if no move needed.
    #>
    param([string]$RelativePath)

    $normalized = $RelativePath.Replace("\", "/")
    $fileName   = Split-Path -Leaf $normalized
    $extension  = [System.IO.Path]::GetExtension($fileName).ToLower()

    if (Test-IsProtected $normalized)   { return $null }
    if (Test-AlreadyCorrect $normalized) { return $null }

    # Test files
    if ($extension -eq ".py" -and ($fileName -match "^test_" -or $fileName -match "_test\.py$")) {
        $target = "tests/unit/$fileName"
        if (Test-DirectoryExists "tests/unit") {
            return @{ Path = $target; Reason = "Test file -> tests/unit/" }
        }
        $target = "tests/$fileName"
        if (Test-DirectoryExists "tests") {
            return @{ Path = $target; Reason = "Test file -> tests/" }
        }
        return $null
    }

    # Python source (non-test)
    if ($extension -eq ".py") {
        $target = "src/{{ project_slug }}/$fileName"
        if (Test-DirectoryExists "src/{{ project_slug }}") {
            return @{ Path = $target; Reason = "Python source -> src/{{ project_slug }}/" }
        }
        return $null
    }

    # Markdown docs (non-protected already filtered above)
    if ($extension -eq ".md") {
        $target = "docs/$fileName"
        if (Test-DirectoryExists "docs") {
            return @{ Path = $target; Reason = "Documentation -> docs/" }
        }
        return $null
    }

    # Script files
    if ($extension -in @(".ps1", ".sh")) {
        $target = "scripts/$fileName"
        if (Test-DirectoryExists "scripts") {
            return @{ Path = $target; Reason = "Script -> scripts/" }
        }
        return $null
    }

    return $null
}

function Test-IsTracked {
    param([string]$RelativePath)
    Push-Location $RepoRoot
    try {
        $null = git ls-files --error-unmatch $RelativePath 2>&1
        return $LASTEXITCODE -eq 0
    } finally {
        Pop-Location
    }
}

# ── Scan candidates ──────────────────────────────────────────────────────────

function Get-TriageCandidates {
    <#
    .SYNOPSIS
        Collect untracked and recently modified files from git status.
    #>
    $candidates = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    Push-Location $RepoRoot
    try {
        $porcelain = git status --porcelain 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "git status failed - is this a git repository?"
            return @()
        }

        foreach ($line in $porcelain) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $statusCode = $line.Substring(0, 2).Trim()
            $rawPath    = $line.Substring(3).Trim()
            $filePath   = $rawPath.Trim('"')

            # Handle renames: "R  old -> new"
            if ($filePath -match " -> (.+)$") {
                $filePath = $Matches[1]
            }

            # Skip deleted files
            if ($statusCode -eq "D") { continue }

            $null = $candidates.Add($filePath)
        }

        # Also pick up files modified in the last 24 hours not already captured
        $recentFiles = git diff --name-only HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $recentFiles) {
            foreach ($f in $recentFiles) {
                if (-not [string]::IsNullOrWhiteSpace($f)) {
                    $null = $candidates.Add($f.Trim())
                }
            }
        }
    } finally {
        Pop-Location
    }

    return @($candidates)
}

# ── Build move plan ──────────────────────────────────────────────────────────

function Build-MovePlan {
    param([string[]]$Candidates)

    $plan = [System.Collections.ArrayList]::new()

    foreach ($candidate in $Candidates) {
        $normalized = $candidate.Replace("\", "/")
        $suggestion = Get-SuggestedLocation $normalized

        if ($null -eq $suggestion) { continue }

        $targetPath = $suggestion.Path
        $targetDir  = Split-Path -Parent $targetPath

        if (-not (Test-DirectoryExists $targetDir)) { continue }

        $fullSource = Join-Path $RepoRoot $normalized
        if (-not (Test-Path $fullSource)) { continue }

        $fullTarget = Join-Path $RepoRoot $targetPath
        if (Test-Path $fullTarget) {
            $null = $plan.Add([PSCustomObject]@{
                CurrentPath   = $normalized
                SuggestedPath = $targetPath
                Reason        = $suggestion.Reason
                Status        = "SKIP-EXISTS"
            })
            continue
        }

        $tracked = Test-IsTracked $normalized
        $itemStatus = if ($DryRun) { "PLANNED" } else { "PENDING" }
        $null = $plan.Add([PSCustomObject]@{
            CurrentPath   = $normalized
            SuggestedPath = $targetPath
            Reason        = $suggestion.Reason
            Status        = $itemStatus
            Tracked       = $tracked
        })
    }

    return $plan
}

# ── Execute plan ─────────────────────────────────────────────────────────────

function Invoke-MovePlan {
    param([System.Collections.ArrayList]$Plan)

    $actionable = $Plan | Where-Object { $_.Status -eq "PENDING" }
    if (-not $actionable -or @($actionable).Count -eq 0) {
        Write-Host "No actionable moves to apply." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "The following moves will be executed:" -ForegroundColor Yellow
    foreach ($item in $actionable) {
        Write-Host "  $($item.CurrentPath) -> $($item.SuggestedPath)" -ForegroundColor White
    }
    Write-Host ""
    $confirm = Read-Host "Proceed? (y/N)"
    if ($confirm -notin @("y", "Y", "yes", "Yes")) {
        Write-Host "Aborted by user." -ForegroundColor Red
        foreach ($item in $actionable) { $item.Status = "ABORTED" }
        return
    }

    Push-Location $RepoRoot
    try {
        foreach ($item in $actionable) {
            $src = $item.CurrentPath
            $dst = $item.SuggestedPath
            try {
                if ($item.Tracked) {
                    git mv $src $dst
                } else {
                    $fullSrc = Join-Path $RepoRoot $src
                    $fullDst = Join-Path $RepoRoot $dst
                    Move-Item -Path $fullSrc -Destination $fullDst
                }
                $item.Status = "MOVED"
                Write-Host "  MOVED: $src -> $dst" -ForegroundColor Green
            } catch {
                $item.Status = "ERROR"
                Write-Warning "  FAILED: $src -> $dst : $_"
            }
        }
    } finally {
        Pop-Location
    }
}

# ── Output formatting ────────────────────────────────────────────────────────

function Format-PlanAsText {
    param([System.Collections.ArrayList]$Plan)

    if ($Plan.Count -eq 0) {
        Write-Host "No files need triaging. Everything looks tidy!" -ForegroundColor Green
        return
    }

    $colCurrent   = ($Plan | ForEach-Object { $_.CurrentPath.Length }   | Measure-Object -Maximum).Maximum
    $colSuggested = ($Plan | ForEach-Object { $_.SuggestedPath.Length } | Measure-Object -Maximum).Maximum
    $colReason    = ($Plan | ForEach-Object { $_.Reason.Length }        | Measure-Object -Maximum).Maximum
    $colStatus    = ($Plan | ForEach-Object { $_.Status.Length }        | Measure-Object -Maximum).Maximum

    $colCurrent   = [Math]::Max($colCurrent,   12)
    $colSuggested = [Math]::Max($colSuggested, 14)
    $colReason    = [Math]::Max($colReason,     6)
    $colStatus    = [Math]::Max($colStatus,     6)

    $header = "{0,-$colCurrent}  {1,-$colSuggested}  {2,-$colReason}  {3,-$colStatus}" -f `
        "Current Path", "Suggested Path", "Reason", "Status"
    $separator = "{0}  {1}  {2}  {3}" -f `
        ("-" * $colCurrent), ("-" * $colSuggested), ("-" * $colReason), ("-" * $colStatus)

    Write-Host $header -ForegroundColor Cyan
    Write-Host $separator -ForegroundColor DarkGray

    foreach ($item in $Plan) {
        $color = switch ($item.Status) {
            "MOVED"       { "Green" }
            "SKIP-EXISTS" { "DarkYellow" }
            "ERROR"       { "Red" }
            "ABORTED"     { "Red" }
            default       { "White" }
        }
        $row = "{0,-$colCurrent}  {1,-$colSuggested}  {2,-$colReason}  {3,-$colStatus}" -f `
            $item.CurrentPath, $item.SuggestedPath, $item.Reason, $item.Status
        Write-Host $row -ForegroundColor $color
    }
}

function Format-PlanAsJson {
    param([System.Collections.ArrayList]$Plan)

    $output = $Plan | ForEach-Object {
        [ordered]@{
            current_path   = $_.CurrentPath
            suggested_path = $_.SuggestedPath
            reason         = $_.Reason
            status         = $_.Status
        }
    }
    $output | ConvertTo-Json -Depth 5
}

# ── Proof bundle ─────────────────────────────────────────────────────────────

function Write-ProofBundle {
    param(
        [System.Collections.ArrayList]$Plan,
        [string]$Mode
    )

    $now       = Get-Date
    $dateStr   = $now.ToString("yyyy-MM-dd")
    $timeStr   = $now.ToString("HHmmss")

    if ($Out) {
        $bundleDir = $Out
    } else {
        $bundleDir = Join-Path $RepoRoot ".cursor" "audits" "eod-triage" $dateStr $timeStr
    }

    if (-not (Test-Path $bundleDir)) {
        New-Item -ItemType Directory -Path $bundleDir -Force | Out-Null
    }

    $meta = [ordered]@{
        action    = "eod-file-triage"
        mode      = $Mode
        timestamp = $now.ToString("o")
        plan_size = $Plan.Count
        moved     = @($Plan | Where-Object { $_.Status -eq "MOVED" }).Count
        skipped   = @($Plan | Where-Object { $_.Status -eq "SKIP-EXISTS" }).Count
        errors    = @($Plan | Where-Object { $_.Status -eq "ERROR" }).Count
    }
    $meta | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $bundleDir "meta.json") -Encoding utf8

    $planData = $Plan | ForEach-Object {
        [ordered]@{
            current_path   = $_.CurrentPath
            suggested_path = $_.SuggestedPath
            reason         = $_.Reason
            status         = $_.Status
        }
    }
    @($planData) | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $bundleDir "plan.json") -Encoding utf8

    $isoTimestamp = $now.ToString("o")
    $planCount = $Plan.Count
    $summaryLines = @(
        "# EOD File Triage - $dateStr"
        ""
        "**Mode:** $Mode"
        "**Timestamp:** $isoTimestamp"
        "**Files evaluated:** $planCount"
        ""
    )

    if ($Plan.Count -gt 0) {
        $summaryLines += "## Move Plan"
        $summaryLines += ""
        $summaryLines += "| Current Path | Suggested Path | Reason | Status |"
        $summaryLines += "|---|---|---|---|"
        foreach ($item in $Plan) {
            $cp = $item.CurrentPath
            $sp = $item.SuggestedPath
            $rs = $item.Reason
            $st = $item.Status
            $summaryLines += "| $cp | $sp | $rs | $st |"
        }
    } else {
        $summaryLines += "_No files need triaging._"
    }

    ($summaryLines -join "`n") | Set-Content (Join-Path $bundleDir "summary.md") -Encoding utf8

    return $bundleDir
}

# ── Main ─────────────────────────────────────────────────────────────────────

$ModeLabel = if ($Apply) { "APPLY" } else { "DRY-RUN" }

Write-Host "=== End-of-Day File Triage ===" -ForegroundColor Cyan
Write-Host "Mode: $ModeLabel"
Write-Host "Repo: $RepoRoot"
Write-Host ""

if (-not (Test-GitRepo)) {
    Write-Host "ERROR: Not a git repository. Run this from inside a git repo." -ForegroundColor Red
    exit 1
}

$candidates = Get-TriageCandidates
if ($candidates.Count -eq 0) {
    Write-Host "No untracked or modified files found. Working tree is clean." -ForegroundColor Green
    $plan = [System.Collections.ArrayList]::new()
} else {
    Write-Host "Found $($candidates.Count) candidate file(s) to evaluate." -ForegroundColor White
    Write-Host ""
    $plan = Build-MovePlan $candidates
}

if ($Format -eq "json") {
    Format-PlanAsJson $plan
} else {
    Format-PlanAsText $plan
}

if ($Apply -and $plan.Count -gt 0) {
    Invoke-MovePlan $plan
    Write-Host ""
    Write-Host "=== Final Results ===" -ForegroundColor Cyan
    if ($Format -eq "json") {
        Format-PlanAsJson $plan
    } else {
        Format-PlanAsText $plan
    }
}

$bundleMode = if ($Apply) { "apply" } else { "dry-run" }
$bundlePath = Write-ProofBundle -Plan $plan -Mode $bundleMode
Write-Host ""
Write-Host "Proof bundle written to: $bundlePath" -ForegroundColor DarkGray

# ── Lessons Learned reminder ──────────────────────────────────────────────────
Write-Host ""
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host "  Log lessons learned (if any)" -ForegroundColor Cyan
Write-Host "  Did you fix a bug, resolve a workflow issue, or discover a" -ForegroundColor White
Write-Host "  non-obvious behavior today? If yes, capture it:" -ForegroundColor White
Write-Host ""
Write-Host "  Example:" -ForegroundColor DarkGray
Write-Host "  pwsh scripts/dev/add-lesson.ps1 -Category notable -Title `"Short title`" -Symptom `"...`" -Fix `"...`" -Prevention `"...`"" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Categories: critical | notable | quality-of-life" -ForegroundColor DarkGray
Write-Host "  Files:      Lessons_Learned/<category>.md" -ForegroundColor DarkGray
Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
