#Requires -Version 7.0
<#
.SYNOPSIS
    SessionStart hook: informational reminder for stale workflow artifacts.
.DESCRIPTION
    Triggered by the SessionStart hook in .claude/settings.json via matcher
    "startup|resume|clear|compact".

    Inspects audit artifact directories and REPO_MAP.md for staleness.
    If any workflow artifact is missing or older than the staleness threshold (24 hours),
    prints a concise informational summary suggesting which commands to run.

    Exit 0 always — purely informational, never mutates anything.
#>

$ErrorActionPreference = "SilentlyContinue"

try {
    $raw = [Console]::In.ReadToEnd()
} catch {
    # Consume stdin even if empty
}

$StalenessHours = 24
$Now = Get-Date

$artifacts = @(
    @{ Name = "Repo map";   AuditDir = ".cursor/audits/repo-map";   Command = "/repo-map";   Supplementary = "REPO_MAP.md" },
    @{ Name = "Doc check";  AuditDir = ".cursor/audits/doc-check";  Command = "/eod (step 2)"; Supplementary = $null },
    @{ Name = "EOD triage"; AuditDir = ".cursor/audits/eod-triage"; Command = "/eod (step 1)"; Supplementary = $null }
)

$staleItems = @()

foreach ($art in $artifacts) {
    $lastTime = $null

    if (Test-Path $art.AuditDir) {
        $metaFiles = Get-ChildItem -Path $art.AuditDir -Filter "meta.json" -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($metaFiles) {
            try {
                $metaContent = Get-Content $metaFiles.FullName -Raw | ConvertFrom-Json -ErrorAction Stop
                if ($metaContent.generated_at) {
                    $lastTime = [DateTime]::Parse($metaContent.generated_at)
                }
            } catch {
                # Fall back to file modification time
            }

            if (-not $lastTime) {
                $lastTime = $metaFiles.LastWriteTime
            }
        }
    }

    if (-not $lastTime -and $art.Supplementary -and (Test-Path $art.Supplementary)) {
        $lastTime = (Get-Item $art.Supplementary).LastWriteTime
    }

    if (-not $lastTime) {
        $staleItems += @{ Name = $art.Name; Command = $art.Command; Reason = "no artifacts found" }
    } elseif (($Now - $lastTime).TotalHours -gt $StalenessHours) {
        $age = [math]::Round(($Now - $lastTime).TotalHours, 0)
        $staleItems += @{ Name = $art.Name; Command = $art.Command; Reason = "${age}h old" }
    }
}

if ($staleItems.Count -eq 0) { exit 0 }

Write-Host ""
Write-Host "[stale-artifacts] Some workflow artifacts may be stale:" -ForegroundColor DarkYellow
foreach ($item in $staleItems) {
    Write-Host "  - $($item.Name) ($($item.Reason)) -> run $($item.Command)" -ForegroundColor DarkYellow
}

exit 0
