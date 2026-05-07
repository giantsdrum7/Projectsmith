#Requires -Version 7.0
<#
.SYNOPSIS
    End-of-day documentation drift check.
.DESCRIPTION
    Checks if documentation has drifted from today's code changes.
    Compares function signatures and module references. Always propose-only.
.PARAMETER DryRun
    Preview drift report without applying patches (default).
.PARAMETER Apply
    Reserved for future use (currently always propose-only).
.PARAMETER Out
    Custom proof bundle output directory.
.PARAMETER Format
    Output format: json or text (default: text).
.EXAMPLE
    pwsh scripts/dev/doc-sync.ps1
    pwsh scripts/dev/doc-sync.ps1 -Format json
    pwsh scripts/dev/doc-sync.ps1 -Out ./my-audit
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

if ($Apply) {
    Write-Warning "doc-sync.ps1 is always propose-only. --Apply is reserved for future use."
}

$Now = Get-Date
$DateStamp = $Now.ToString("yyyy-MM-dd")
$TimeStamp = $Now.ToString("HHmmss")

if ($Out) {
    $BundleDir = $Out
} else {
    $BundleDir = Join-Path $RepoRoot ".cursor" "audits" "doc-check" $DateStamp $TimeStamp
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Test-GitRepo {
    try {
        $null = git -C $RepoRoot rev-parse --is-inside-work-tree 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Get-ChangedPythonFiles {
    <#
    .SYNOPSIS
        Return unique list of .py files changed in the last day.
    #>
    $files = @()

    $committed = git -C $RepoRoot log --since="1 day ago" --name-only --diff-filter=ACMR --pretty=format:"" -- "*.py" 2>$null
    if ($committed) {
        $files += $committed | Where-Object { $_ -ne "" }
    }

    $staged = git -C $RepoRoot diff --cached --name-only --diff-filter=ACMR -- "*.py" 2>$null
    if ($staged) {
        $files += $staged | Where-Object { $_ -ne "" }
    }

    $unstaged = git -C $RepoRoot diff --name-only --diff-filter=ACMR -- "*.py" 2>$null
    if ($unstaged) {
        $files += $unstaged | Where-Object { $_ -ne "" }
    }

    return ($files | Sort-Object -Unique)
}

function Get-PublicFunctions {
    <#
    .SYNOPSIS
        Extract public (non-underscore-prefixed) function signatures from a Python file.
    #>
    param([string]$FilePath)

    $absPath = if ([System.IO.Path]::IsPathRooted($FilePath)) { $FilePath } else { Join-Path $RepoRoot $FilePath }
    if (-not (Test-Path $absPath)) { return @() }

    $content = Get-Content $absPath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return @() }

    $pattern = '(?m)^def\s+([a-zA-Z][a-zA-Z0-9_]*)\s*\(([^)]*)\)(?:\s*->\s*([^:]+))?\s*:'
    $regexMatches = [regex]::Matches($content, $pattern)

    $functions = @()
    foreach ($m in $regexMatches) {
        $name = $m.Groups[1].Value
        if (-not $name.StartsWith("_")) {
            $linesBefore = ($content.Substring(0, $m.Index) -split "`n").Count
            $functions += [PSCustomObject]@{
                Name      = $name
                Signature = $m.Value.TrimEnd(":").Trim()
                Line      = $linesBefore
                Params    = $m.Groups[2].Value.Trim()
                ReturnType = if ($m.Groups[3].Success) { $m.Groups[3].Value.Trim() } else { $null }
            }
        }
    }
    return $functions
}

function Get-DocFiles {
    <#
    .SYNOPSIS
        Collect all Markdown doc files from docs/ subtree.
    #>
    $docsDir = Join-Path $RepoRoot "docs"
    if (-not (Test-Path $docsDir)) { return @() }
    return Get-ChildItem -Path $docsDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
}

function Find-FunctionRefsInDocs {
    <#
    .SYNOPSIS
        Search all doc files for references to a given function name.
        Returns array of objects with File, Line, and MatchedText.
    #>
    param([string]$FunctionName, [array]$DocFiles)

    $refs = @()
    foreach ($doc in $DocFiles) {
        $lines = Get-Content $doc.FullName -ErrorAction SilentlyContinue
        if (-not $lines) { continue }
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "\b$([regex]::Escape($FunctionName))\b") {
                $refs += [PSCustomObject]@{
                    File        = $doc.FullName
                    RelPath     = [System.IO.Path]::GetRelativePath($RepoRoot, $doc.FullName)
                    Line        = $i + 1
                    MatchedText = $lines[$i].Trim()
                }
            }
        }
    }
    return $refs
}

function Get-PreviousFunctions {
    <#
    .SYNOPSIS
        Extract public function names from the previous version of a file (HEAD).
        Returns empty array if git fails (e.g., new file).
    #>
    param([string]$RelativePath)

    try {
        $oldContent = git -C $RepoRoot show "HEAD:$RelativePath" 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $oldContent) { return @() }

        $joined = $oldContent -join "`n"
        $pattern = '(?m)^def\s+([a-zA-Z][a-zA-Z0-9_]*)\s*\(([^)]*)\)(?:\s*->\s*([^:]+))?\s*:'
        $regexMatches = [regex]::Matches($joined, $pattern)

        $functions = @()
        foreach ($m in $regexMatches) {
            $name = $m.Groups[1].Value
            if (-not $name.StartsWith("_")) {
                $functions += [PSCustomObject]@{
                    Name      = $name
                    Signature = $m.Value.TrimEnd(":").Trim()
                    Params    = $m.Groups[2].Value.Trim()
                    ReturnType = if ($m.Groups[3].Success) { $m.Groups[3].Value.Trim() } else { $null }
                }
            }
        }
        return $functions
    } catch {
        return @()
    }
}

# ---------------------------------------------------------------------------
# Drift analysis
# ---------------------------------------------------------------------------

function Build-DriftReport {
    <#
    .SYNOPSIS
        Analyze all changed Python files and produce a list of drift items.
    #>
    param([array]$ChangedFiles, [array]$DocFiles)

    $driftItems = @()

    foreach ($relPath in $ChangedFiles) {
        $absPath = Join-Path $RepoRoot $relPath
        if (-not (Test-Path $absPath)) { continue }

        $currentFunctions = Get-PublicFunctions -FilePath $absPath
        $previousFunctions = Get-PreviousFunctions -RelativePath $relPath

        $prevByName = @{}
        foreach ($pf in $previousFunctions) {
            $prevByName[$pf.Name] = $pf
        }

        $currByName = @{}
        foreach ($cf in $currentFunctions) {
            $currByName[$cf.Name] = $cf
        }

        foreach ($fn in $currentFunctions) {
            $docRefs = Find-FunctionRefsInDocs -FunctionName $fn.Name -DocFiles $DocFiles

            if (-not $prevByName.ContainsKey($fn.Name)) {
                # New function — check if documented
                if ($docRefs.Count -eq 0) {
                    $driftItems += [PSCustomObject]@{
                        SourceFile  = $relPath
                        SourceLine  = $fn.Line
                        Function    = $fn.Name
                        Signature   = $fn.Signature
                        DriftType   = "new_undocumented"
                        Priority    = "high"
                        Description = "New public function '$($fn.Name)' has no documentation reference."
                        Action      = "Add documentation for '$($fn.Name)' in docs/reference/ or docs/architecture/."
                        DocRefs     = @()
                    }
                }
            } else {
                # Existing function — check for signature change.
                # Normalize whitespace before comparing to avoid false
                # positives from line-ending differences (Get-Content -Raw
                # preserves \r\n while git-show output is joined with \n).
                $oldSig = $prevByName[$fn.Name]
                $normCurParams = ($fn.Params -replace '\s+', ' ').Trim()
                $normOldParams = ($oldSig.Params -replace '\s+', ' ').Trim()
                $normCurReturn = if ($fn.ReturnType) { ($fn.ReturnType -replace '\s+', ' ').Trim() } else { $null }
                $normOldReturn = if ($oldSig.ReturnType) { ($oldSig.ReturnType -replace '\s+', ' ').Trim() } else { $null }
                $sigChanged = ($normCurParams -ne $normOldParams) -or ($normCurReturn -ne $normOldReturn)

                if ($sigChanged -and $docRefs.Count -gt 0) {
                    $driftItems += [PSCustomObject]@{
                        SourceFile  = $relPath
                        SourceLine  = $fn.Line
                        Function    = $fn.Name
                        Signature   = $fn.Signature
                        DriftType   = "signature_mismatch"
                        Priority    = "medium"
                        Description = "Signature of '$($fn.Name)' changed but docs still reference the old version."
                        Action      = "Update documentation references to match new signature."
                        DocRefs     = $docRefs
                    }
                }
            }
        }

        # Detect removed functions still referenced in docs
        foreach ($name in $prevByName.Keys) {
            if (-not $currByName.ContainsKey($name)) {
                $docRefs = Find-FunctionRefsInDocs -FunctionName $name -DocFiles $DocFiles
                if ($docRefs.Count -gt 0) {
                    $driftItems += [PSCustomObject]@{
                        SourceFile  = $relPath
                        SourceLine  = $null
                        Function    = $name
                        Signature   = $prevByName[$name].Signature
                        DriftType   = "stale_reference"
                        Priority    = "low"
                        Description = "Function '$name' was removed but is still referenced in documentation."
                        Action      = "Remove or update stale references in documentation."
                        DocRefs     = $docRefs
                    }
                }
            }
        }
    }

    # Sort by priority: high > medium > low
    $priorityOrder = @{ "high" = 0; "medium" = 1; "low" = 2 }
    $driftItems = $driftItems | Sort-Object { $priorityOrder[$_.Priority] }, SourceFile, SourceLine

    return $driftItems
}

# ---------------------------------------------------------------------------
# Output formatters
# ---------------------------------------------------------------------------

function Format-DriftAsText {
    param([array]$DriftItems, [array]$ChangedFiles)

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("=== Documentation Drift Report ===")
    [void]$sb.AppendLine("Generated: $($Now.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$sb.AppendLine("Files scanned: $($ChangedFiles.Count)")
    [void]$sb.AppendLine("Drift items found: $($DriftItems.Count)")
    [void]$sb.AppendLine("")

    if ($DriftItems.Count -eq 0) {
        [void]$sb.AppendLine("No documentation drift detected. All clear!")
        return $sb.ToString()
    }

    $grouped = $DriftItems | Group-Object Priority
    foreach ($group in $grouped) {
        $label = switch ($group.Name) {
            "high"   { "HIGH PRIORITY (new undocumented public API)" }
            "medium" { "MEDIUM PRIORITY (signature mismatches)" }
            "low"    { "LOW PRIORITY (stale references)" }
        }
        [void]$sb.AppendLine("--- $label ---")
        [void]$sb.AppendLine("")

        foreach ($item in $group.Group) {
            $loc = if ($item.SourceLine) { "$($item.SourceFile):$($item.SourceLine)" } else { $item.SourceFile }
            [void]$sb.AppendLine("  [$($item.DriftType)] $($item.Function)")
            [void]$sb.AppendLine("    Source: $loc")
            [void]$sb.AppendLine("    Signature: $($item.Signature)")
            [void]$sb.AppendLine("    Issue: $($item.Description)")
            [void]$sb.AppendLine("    Action: $($item.Action)")

            if ($item.DocRefs -and $item.DocRefs.Count -gt 0) {
                [void]$sb.AppendLine("    Doc references:")
                foreach ($ref in $item.DocRefs) {
                    [void]$sb.AppendLine("      - $($ref.RelPath):$($ref.Line)")
                }
            }
            [void]$sb.AppendLine("")
        }
    }

    [void]$sb.AppendLine("--- Summary ---")
    $highCount = ($DriftItems | Where-Object { $_.Priority -eq "high" }).Count
    $medCount  = ($DriftItems | Where-Object { $_.Priority -eq "medium" }).Count
    $lowCount  = ($DriftItems | Where-Object { $_.Priority -eq "low" }).Count
    [void]$sb.AppendLine("  High:   $highCount")
    [void]$sb.AppendLine("  Medium: $medCount")
    [void]$sb.AppendLine("  Low:    $lowCount")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Mode: PROPOSE-ONLY (review and apply manually)")

    return $sb.ToString()
}

function Format-DriftAsJson {
    param([array]$DriftItems, [array]$ChangedFiles)

    $report = @{
        generated    = $Now.ToString("o")
        files_scanned = $ChangedFiles.Count
        drift_count  = $DriftItems.Count
        mode         = "propose-only"
        items        = @()
    }

    foreach ($item in $DriftItems) {
        $docRefList = @()
        if ($item.DocRefs) {
            foreach ($ref in $item.DocRefs) {
                $docRefList += @{
                    file = $ref.RelPath
                    line = $ref.Line
                }
            }
        }

        $report.items += @{
            source_file  = $item.SourceFile
            source_line  = $item.SourceLine
            function     = $item.Function
            signature    = $item.Signature
            drift_type   = $item.DriftType
            priority     = $item.Priority
            description  = $item.Description
            action       = $item.Action
            doc_refs     = $docRefList
        }
    }

    return ($report | ConvertTo-Json -Depth 5)
}

# ---------------------------------------------------------------------------
# Proof bundle
# ---------------------------------------------------------------------------

function Write-ProofBundle {
    param([array]$DriftItems, [array]$ChangedFiles, [string]$TextReport)

    New-Item -Path $BundleDir -ItemType Directory -Force | Out-Null

    $meta = @{
        action       = "doc-check"
        timestamp    = $Now.ToString("o")
        mode         = "propose-only"
        files_scanned = $ChangedFiles.Count
        drift_count  = $DriftItems.Count
        format       = $Format
        repo_root    = $RepoRoot
    }
    $meta | ConvertTo-Json -Depth 3 | Out-File (Join-Path $BundleDir "meta.json") -Encoding utf8

    $jsonReport = Format-DriftAsJson -DriftItems $DriftItems -ChangedFiles $ChangedFiles
    $jsonReport | Out-File (Join-Path $BundleDir "drift-report.json") -Encoding utf8

    $summaryLines = @(
        "# Doc Sync — Drift Report"
        ""
        "**Date:** $DateStamp"
        "**Time:** $TimeStamp"
        "**Mode:** propose-only"
        "**Files scanned:** $($ChangedFiles.Count)"
        "**Drift items:** $($DriftItems.Count)"
        ""
    )

    if ($DriftItems.Count -eq 0) {
        $summaryLines += "No documentation drift detected."
    } else {
        $highCount = ($DriftItems | Where-Object { $_.Priority -eq "high" }).Count
        $medCount  = ($DriftItems | Where-Object { $_.Priority -eq "medium" }).Count
        $lowCount  = ($DriftItems | Where-Object { $_.Priority -eq "low" }).Count
        $summaryLines += "## Counts"
        $summaryLines += ""
        $summaryLines += "| Priority | Count |"
        $summaryLines += "|----------|-------|"
        $summaryLines += "| High     | $highCount |"
        $summaryLines += "| Medium   | $medCount |"
        $summaryLines += "| Low      | $lowCount |"
        $summaryLines += ""
        $summaryLines += "## Items"
        $summaryLines += ""

        foreach ($item in $DriftItems) {
            $summaryLines += "### ``$($item.Function)`` ($($item.Priority))"
            $summaryLines += ""
            $summaryLines += "- **Type:** $($item.DriftType)"
            $summaryLines += "- **Source:** $($item.SourceFile)$(if ($item.SourceLine) { ":$($item.SourceLine)" })"
            $summaryLines += "- **Issue:** $($item.Description)"
            $summaryLines += "- **Action:** $($item.Action)"

            if ($item.DocRefs -and $item.DocRefs.Count -gt 0) {
                $summaryLines += "- **Doc refs:**"
                foreach ($ref in $item.DocRefs) {
                    $summaryLines += "  - $($ref.RelPath):$($ref.Line)"
                }
            }
            $summaryLines += ""
        }
    }

    ($summaryLines -join "`n") | Out-File (Join-Path $BundleDir "summary.md") -Encoding utf8

    return $BundleDir
}

# ---------------------------------------------------------------------------
# Main execution
# ---------------------------------------------------------------------------

Write-Host "=== Documentation Drift Check ===" -ForegroundColor Cyan
Write-Host "Mode: PROPOSE-ONLY (never auto-applies)"
Write-Host ""

if (-not (Test-GitRepo)) {
    Write-Host "ERROR: Not inside a git repository. Cannot detect changed files." -ForegroundColor Red
    exit 1
}

$changedFiles = Get-ChangedPythonFiles

if (-not $changedFiles -or $changedFiles.Count -eq 0) {
    Write-Host "No Python files changed in the last day." -ForegroundColor Green

    $emptyItems = @()
    $emptyFiles = @()
    $textOutput = Format-DriftAsText -DriftItems $emptyItems -ChangedFiles $emptyFiles
    $bundlePath = Write-ProofBundle -DriftItems $emptyItems -ChangedFiles $emptyFiles -TextReport $textOutput
    Write-Host "Proof bundle: $bundlePath"
    exit 0
}

Write-Host "Changed Python files ($($changedFiles.Count)):" -ForegroundColor Yellow
foreach ($f in $changedFiles) {
    Write-Host "  - $f"
}
Write-Host ""

$docFiles = Get-DocFiles

if (-not $docFiles -or $docFiles.Count -eq 0) {
    Write-Host "WARNING: No documentation files found in docs/. Skipping cross-reference check." -ForegroundColor Yellow
    Write-Host "All public functions in changed files will be flagged as undocumented." -ForegroundColor Yellow
    Write-Host ""
    $docFiles = @()
}

$driftItems = Build-DriftReport -ChangedFiles $changedFiles -DocFiles $docFiles

if ($Format -eq "json") {
    $output = Format-DriftAsJson -DriftItems $driftItems -ChangedFiles $changedFiles
} else {
    $output = Format-DriftAsText -DriftItems $driftItems -ChangedFiles $changedFiles
}

Write-Host $output

$bundlePath = Write-ProofBundle -DriftItems $driftItems -ChangedFiles $changedFiles -TextReport $output

Write-Host ""
Write-Host "Proof bundle written to: $bundlePath" -ForegroundColor Cyan
Write-Host "Files: meta.json, drift-report.json, summary.md" -ForegroundColor DarkGray

if ($driftItems.Count -gt 0) {
    $highCount = ($driftItems | Where-Object { $_.Priority -eq "high" }).Count
    if ($highCount -gt 0) {
        Write-Host ""
        Write-Host "ACTION REQUIRED: $highCount high-priority drift item(s) detected." -ForegroundColor Red
    }
}
