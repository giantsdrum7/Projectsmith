#Requires -Version 5.1
<#
.SYNOPSIS
    Generate/update REPO_MAP.md with current repository state.
.DESCRIPTION
    Builds directory tree from git-tracked files (respects .gitignore),
    extracts entry points, captures git activity.
    Updates only AUTO-marked sections in REPO_MAP.md; never overwrites HUMAN sections.
.PARAMETER DryRun
    Preview changes without writing (default behavior).
.PARAMETER Apply
    Write changes to REPO_MAP.md.
.PARAMETER Out
    Custom proof bundle output directory.
.PARAMETER Format
    Output format: json or text (default: text).
.EXAMPLE
    pwsh scripts/dev/repo-map.ps1
    pwsh scripts/dev/repo-map.ps1 -Apply
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
$RepoMapPath = Join-Path $RepoRoot "REPO_MAP.md"

if (-not $Apply) { $DryRun = $true }

# ---------------------------------------------------------------------------
# Helper: Build a directory tree from git-tracked files (respects .gitignore)
# ---------------------------------------------------------------------------
function Get-RepoTree {
    param(
        [string]$Path,
        [int]$MaxDepth = 4
    )

    $trackedFiles = & git -C $Path ls-files 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $trackedFiles) {
        return @("+-- (no tracked files)")
    }

    # Build a nested hashtable representing the directory tree
    $tree = @{}
    foreach ($file in $trackedFiles) {
        $parts = $file -split '/'
        $current = $tree
        for ($j = 0; $j -lt $parts.Count; $j++) {
            $part = $parts[$j]
            if ($j -eq ($parts.Count - 1)) {
                # Leaf file — store $null to distinguish from directories
                $current[$part] = $null
            } else {
                if (-not $current.ContainsKey($part) -or $current[$part] -eq $null) {
                    $current[$part] = @{}
                }
                $current = $current[$part]
            }
        }
    }

    # Render the tree with ASCII connectors, depth-limited
    function Render-Tree {
        param(
            [hashtable]$Node,
            [string]$Prefix = "",
            [int]$Depth = 0,
            [int]$MaxD = 4
        )
        $lines = New-Object System.Collections.Generic.List[string]

        # Separate dirs (hashtable values) from files ($null values), sort each
        $dirs = @($Node.GetEnumerator() | Where-Object { $_.Value -is [hashtable] } | Sort-Object Name)
        $files = @($Node.GetEnumerator() | Where-Object { $_.Value -eq $null } | Sort-Object Name)
        $items = @($dirs) + @($files)

        for ($i = 0; $i -lt $items.Count; $i++) {
            $entry = $items[$i]
            $isLast = ($i -eq ($items.Count - 1))
            if ($isLast) { $connector = "+-- " } else { $connector = "|-- " }
            if ($isLast) { $extension = "    " } else { $extension = "|   " }

            if ($entry.Value -is [hashtable]) {
                $lines.Add("$Prefix$connector$($entry.Name)/")
                if ($Depth -lt $MaxD) {
                    $childLines = Render-Tree -Node $entry.Value -Prefix "$Prefix$extension" -Depth ($Depth + 1) -MaxD $MaxD
                    foreach ($cl in $childLines) { $lines.Add($cl) }
                }
            } else {
                $lines.Add("$Prefix$connector$($entry.Name)")
            }
        }
        return $lines
    }

    return Render-Tree -Node $tree -MaxD $MaxDepth
}

# ---------------------------------------------------------------------------
# Helper: Parse [project.scripts] from pyproject.toml
# ---------------------------------------------------------------------------
function Get-EntryPoints {
    $tomlPath = Join-Path $RepoRoot "pyproject.toml"
    if (-not (Test-Path $tomlPath)) {
        return "_No pyproject.toml found._"
    }

    $fileLines = Get-Content $tomlPath -Encoding UTF8
    $inSection = $false
    $entries = New-Object System.Collections.Generic.List[string]

    foreach ($line in $fileLines) {
        if ($line -match '^\[project\.scripts\]') {
            $inSection = $true
            continue
        }
        if ($inSection -and $line -match '^\[') {
            break
        }
        if ($inSection) {
            $trimmed = $line.Trim()
            if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
            if ($trimmed -match '^(\S+)\s*=\s*"(.+)"') {
                $entries.Add("| ``$($Matches[1])`` | ``$($Matches[2])`` |")
            }
        }
    }

    if ($entries.Count -eq 0) {
        return "_No CLI entry points defined yet in ``[project.scripts]``._"
    }

    $header = @("| Command | Target |", "| --- | --- |")
    return ($header + $entries) -join "`n"
}

# ---------------------------------------------------------------------------
# Helper: Capture recent git activity (safe when no repo / shallow history)
# ---------------------------------------------------------------------------
function Get-GitActivity {
    $gitDir = Join-Path $RepoRoot ".git"
    if (-not (Test-Path $gitDir)) {
        return "_Not a git repository yet._"
    }

    $output = New-Object System.Collections.Generic.List[string]

    try {
        $log = & git -C $RepoRoot log --oneline -20 2>&1
        if ($LASTEXITCODE -eq 0 -and $log) {
            $output.Add("### Recent Commits")
            $output.Add("")
            $output.Add('```')
            foreach ($l in $log) { $output.Add([string]$l) }
            $output.Add('```')
        }
        else {
            $output.Add("_No commits yet._")
        }
    }
    catch {
        $output.Add("_No commits yet._")
    }

    try {
        $countRaw = & git -C $RepoRoot rev-list --count HEAD 2>&1
        if ($LASTEXITCODE -eq 0) {
            $commitCount = [int]$countRaw
            if ($commitCount -ge 5) {
                $diff = & git -C $RepoRoot diff --stat "HEAD~5..HEAD" 2>&1
                if ($LASTEXITCODE -eq 0 -and $diff) {
                    $output.Add("")
                    $output.Add("### Changed Files (last 5 commits)")
                    $output.Add("")
                    $output.Add('```')
                    foreach ($d in $diff) { $output.Add([string]$d) }
                    $output.Add('```')
                }
            }
        }
    }
    catch {
        # Silently skip if not enough history
    }

    if ($output.Count -eq 0) {
        return "_No git activity to report._"
    }
    return $output -join "`n"
}

# ---------------------------------------------------------------------------
# Helper: Generate how_to_run content
# ---------------------------------------------------------------------------
function Get-HowToRun {
    $lines = @(
        '```bash'
        '# 1. Clone and enter the repo'
        'git clone <repo-url> && cd {{ project_slug }}'
        ''
        '# 2. Create a virtual environment'
        'python -m venv .venv'
        '# Windows: .venv\Scripts\Activate.ps1'
        '# Unix:    source .venv/bin/activate'
        ''
        '# 3. Install dependencies (with dev extras)'
        'pip install -e ".[dev]"'
        ''
        '# 4. Copy environment template'
        'cp .env.example .env.local   # then fill in values'
        ''
        '# 5. Select environment mode'
        'pwsh scripts/env/use-env.ps1 -Mode offline   # no external calls'
        ''
        '# 6. Run verification'
        'pwsh scripts/verify-fast.ps1   # lint + type-check'
        'pwsh scripts/verify.ps1        # full: lint + type-check + tests'
        '```'
    )
    return $lines -join "`n"
}

# ---------------------------------------------------------------------------
# Helper: Generate environments summary
# ---------------------------------------------------------------------------
function Get-Environments {
    $lines = @(
        '| Mode | Description | Set via |'
        '| --- | --- | --- |'
        '| `offline` | No external calls. Stub LLM responses. Safe for air-gapped dev. | `use-env.ps1 -Mode offline` |'
        '| `local-live` | Real Bedrock calls against dev resources. | `use-env.ps1 -Mode local-live` |'
        '| `prod` | CI/CD only. Never set locally. | CI/CD pipeline only |'
        ''
        'Switch modes: `pwsh scripts/env/use-env.ps1 -Mode <mode>` (Windows) or `bash scripts/env/use-env.sh <mode>` (Unix).'
    )
    return $lines -join "`n"
}

# ---------------------------------------------------------------------------
# Helper: Generate verification summary
# ---------------------------------------------------------------------------
function Get-Verification {
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add('```bash')
    $lines.Add('# Fast check (before every commit)')
    $lines.Add('pwsh scripts/verify-fast.ps1')
    $lines.Add('')
    $lines.Add('# Full check (before finishing a task)')
    $lines.Add('pwsh scripts/verify.ps1')
    $lines.Add('```')
    $lines.Add('')

    $failPath = Join-Path (Join-Path $RepoRoot ".cursor") "last-verify-failure.txt"
    if (Test-Path $failPath) {
        $failTime = (Get-Item $failPath).LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        $lines.Add("**Last failure recorded:** $failTime -- see ``.cursor/last-verify-failure.txt``.")
    }
    else {
        $lines.Add("_No verification failures on record._")
    }

    return $lines -join "`n"
}

# ---------------------------------------------------------------------------
# Replace content inside AUTO markers, preserving everything else
# ---------------------------------------------------------------------------
function Update-AutoSection {
    param(
        [string]$Document,
        [string]$SectionName,
        [string]$NewContent
    )

    $startMarker = "<!-- AUTO:START:$SectionName -->"
    $endMarker = "<!-- AUTO:END:$SectionName -->"
    $escapedStart = [regex]::Escape($startMarker)
    $escapedEnd = [regex]::Escape($endMarker)

    $pattern = "(?s)($escapedStart)(.*?)($escapedEnd)"

    if (-not [regex]::IsMatch($Document, $pattern)) {
        Write-Warning "AUTO section '$SectionName' not found in REPO_MAP.md -- skipping."
        return $Document
    }

    $replacement = ('${1}' + "`n" + $NewContent + "`n" + '${3}')
    return [regex]::Replace($Document, $pattern, $replacement)
}

# ---------------------------------------------------------------------------
# Write proof bundle
# ---------------------------------------------------------------------------
function Write-ProofBundle {
    param(
        [string]$BaseDir,
        [string]$Summary,
        [string]$StdOut,
        [bool]$Applied
    )

    $now = Get-Date
    $dateDir = $now.ToString("yyyy-MM-dd")
    $tsDir = $now.ToString("HHmmss")

    if ($BaseDir) {
        $bundlePath = $BaseDir
    }
    else {
        $bundlePath = Join-Path (Join-Path (Join-Path (Join-Path (Join-Path $RepoRoot ".cursor") "audits") "repo-map") $dateDir) $tsDir
    }

    if (-not (Test-Path $bundlePath)) {
        New-Item -ItemType Directory -Path $bundlePath -Force | Out-Null
    }

    if ($Applied) { $modeStr = "apply" } else { $modeStr = "dry-run" }

    $meta = @{
        action    = "repo-map"
        timestamp = $now.ToString("o")
        mode      = $modeStr
        format    = $Format
        repo_root = $RepoRoot
    }
    $meta | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $bundlePath "meta.json") -Encoding UTF8

    Set-Content (Join-Path $bundlePath "summary.md") -Value $Summary -Encoding UTF8
    Set-Content (Join-Path $bundlePath "stdout.txt") -Value $StdOut -Encoding UTF8

    return $bundlePath
}

# ===========================================================================
# Main execution
# ===========================================================================

$stdoutCapture = New-Object System.Collections.Generic.List[string]

function Log {
    param([string]$Msg, [string]$Color = "White")
    Write-Host $Msg -ForegroundColor $Color
    $script:stdoutCapture.Add($Msg)
}

if ($Apply) { $modeLabel = "APPLY" } else { $modeLabel = "DRY-RUN" }

Log "=== Repo Map Generator ===" "Cyan"
Log "Mode: $modeLabel"
Log "Format: $Format"
Log "Repo root: $RepoRoot"
Log ""

# --- Generate each section ---------------------------------------------------

Log "Generating repo tree..." "Yellow"
$treeLines = Get-RepoTree -Path $RepoRoot
$treeContent = '```' + "`n" + ($treeLines -join "`n") + "`n" + '```'
Log "  Tree: $($treeLines.Count) entries"

Log "Extracting entry points..." "Yellow"
$entryPointsContent = Get-EntryPoints
Log "  Done."

Log "Capturing git activity..." "Yellow"
$gitContent = Get-GitActivity
Log "  Done."

Log "Generating how-to-run..." "Yellow"
$howToRunContent = Get-HowToRun
Log "  Done."

Log "Generating environments..." "Yellow"
$environmentsContent = Get-Environments
Log "  Done."

Log "Generating verification..." "Yellow"
$verificationContent = Get-Verification
Log "  Done."
Log ""

# --- Read existing REPO_MAP.md and update AUTO sections ----------------------

if (-not (Test-Path $RepoMapPath)) {
    Log "WARNING: REPO_MAP.md not found at $RepoMapPath" "Red"
    Log "Cannot update AUTO sections without existing file."
    exit 1
}

$original = Get-Content $RepoMapPath -Raw -Encoding UTF8

$updated = $original
$updated = Update-AutoSection -Document $updated -SectionName "repo_tree" -NewContent $treeContent
$updated = Update-AutoSection -Document $updated -SectionName "entry_points" -NewContent $entryPointsContent
$updated = Update-AutoSection -Document $updated -SectionName "how_to_run" -NewContent $howToRunContent
$updated = Update-AutoSection -Document $updated -SectionName "environments" -NewContent $environmentsContent
$updated = Update-AutoSection -Document $updated -SectionName "verification" -NewContent $verificationContent

$changed = $updated -ne $original

# --- Output results ----------------------------------------------------------

if ($Format -eq "json") {
    $result = @{
        changed      = $changed
        mode         = $modeLabel.ToLower()
        sections     = @("repo_tree", "entry_points", "how_to_run", "environments", "verification")
        tree_entries = $treeLines.Count
    }
    $result | ConvertTo-Json -Depth 4 | Write-Output
}
else {
    if ($changed) {
        Log "AUTO sections updated." "Green"
    }
    else {
        Log "No changes detected in AUTO sections." "DarkGray"
    }
}

# --- Apply or preview --------------------------------------------------------

if ($Apply -and $changed) {
    Set-Content -Path $RepoMapPath -Value $updated -Encoding UTF8 -NoNewline
    Log "REPO_MAP.md written." "Green"
}
elseif (-not $Apply -and $changed) {
    Log "[DRY-RUN] Would update REPO_MAP.md. Re-run with -Apply to write." "Yellow"
}

# --- Proof bundle ------------------------------------------------------------

if ($Apply) { $bundleMode = "apply" } else { $bundleMode = "dry-run" }

$summaryLines = @(
    "# Repo Map -- Proof Bundle"
    ""
    "- **Timestamp:** $(Get-Date -Format 'o')"
    "- **Mode:** $bundleMode"
    "- **Changed:** $changed"
    "- **Tree entries:** $($treeLines.Count)"
    "- **Sections updated:** repo_tree, entry_points, how_to_run, environments, verification"
)

$bundlePath = Write-ProofBundle `
    -BaseDir $Out `
    -Summary ($summaryLines -join "`n") `
    -StdOut ($stdoutCapture -join "`n") `
    -Applied $Apply

Log ""
Log "Proof bundle: $bundlePath" "DarkGray"
Log "Done." "Cyan"
