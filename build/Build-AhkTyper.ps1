<#
Script            : Build AHK-Typer release files
FileName          : Build-AhkTyper.ps1
Author            : Philippe Addelia
Created           : 2026-10-25 04:30 EDT
Modified          : 2026-10-25 12:05 EDT
Preferred Location: build\ (repo AutoHotkey-Typer)
Version           : 1.5.0.1
Purpose           : Compiles src\AutoHotkey-Typer.ahk into dist\AHK-Typer.exe
                    with Ahk2Exe and the AutoHotkey v2 64-bit base, then writes
                      dist\AHK-Typer.exe.sha256   (hash file, sha256sum format)
                      dist\release-notes.md       (CHANGELOG section + SHA-256;
                                                    no title - GitHub shows the
                                                    release title already)
                    and prints the GitHub CLI command to publish the release.

Requirements      : AutoHotkey v2 with the Ahk2Exe compiler, version 1.1.36 or
                    later (older versions cannot build v2 scripts and reject
                    /base). Update it from the AutoHotkey Dash ("Compile") or
                    https://github.com/AutoHotkey/Ahk2Exe/releases.
                    Only built-in cmdlets are used.
                    Optional: GitHub CLI (gh) to publish the release.

Test              : .\build\Build-AhkTyper.ps1
                    .\build\Build-AhkTyper.ps1 -Ahk2Exe "D:\Tools\Ahk2Exe\Ahk2Exe.exe"
#>
[CmdletBinding()]
param(
    [string]$Ahk2Exe = "$($env:ProgramFiles)\AutoHotkey\Compiler\Ahk2Exe.exe",
    [string]$Base    = "$($env:ProgramFiles)\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
$repo      = Split-Path -Path $PSScriptRoot -Parent
$source    = Join-Path $repo 'src\AutoHotkey-Typer.ahk'
$changelog = Join-Path $repo 'CHANGELOG.md'
$dist      = Join-Path $repo 'dist'
$exe       = Join-Path $dist 'AHK-Typer.exe'
$hashFile  = Join-Path $dist 'AHK-Typer.exe.sha256'
$notesFile = Join-Path $dist 'release-notes.md'

foreach ($p in @($Ahk2Exe, $Base, $source, $changelog)) {
    if (-not (Test-Path -LiteralPath $p)) {
        throw "Not found: $($p). Use -Ahk2Exe / -Base to point to your AutoHotkey install."
    }
}

# ---------------------------------------------------------------------------
# Ahk2Exe must be new enough for AutoHotkey v2 (/base, /silent)
# ---------------------------------------------------------------------------
$minAhk2Exe = [version]'1.1.36'
$rawVer     = (Get-Item -LiteralPath $Ahk2Exe).VersionInfo.FileVersion
$ahkVer     = $null
if ($rawVer -and [version]::TryParse(($rawVer -replace '[^0-9.].*$', ''), [ref]$ahkVer)) {
    if ($ahkVer -lt $minAhk2Exe) {
        throw ("Ahk2Exe $($ahkVer) at $($Ahk2Exe) is too old to compile AutoHotkey v2 " +
               "scripts (needs $($minAhk2Exe) or later). Update it from the AutoHotkey " +
               "Dash (Compile) or https://github.com/AutoHotkey/Ahk2Exe/releases, or run " +
               "this script with -Ahk2Exe <path to a newer Ahk2Exe.exe>.")
    }
    Write-Host "Ahk2Exe $($ahkVer)" -ForegroundColor DarkGray
} else {
    Write-Warning "Could not read the Ahk2Exe version - continuing."
}

# ---------------------------------------------------------------------------
# Version - read from APP_VERSION in the main script (single source of truth)
# ---------------------------------------------------------------------------
$match = Select-String -LiteralPath $source -Pattern 'APP_VERSION\s*:=\s*"([^"]+)"' |
         Select-Object -First 1
if (-not $match) { throw "APP_VERSION not found in $($source)" }
$version = $match.Matches[0].Groups[1].Value
Write-Host "Building AHK-Typer $($version)" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Compile. /compress 0 = no UPX/MPRESS packing: packed .exe files trigger
# more antivirus false positives.
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Path $dist -Force | Out-Null
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }

$argList = @(
    '/in',       "`"$($source)`"",
    '/out',      "`"$($exe)`"",
    '/base',     "`"$($Base)`"",
    '/compress', '0',
    '/silent',   'verbose'
)
$proc = Start-Process -FilePath $Ahk2Exe -ArgumentList $argList -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $exe)) {
    throw "Ahk2Exe failed (exit code $($proc.ExitCode))."
}

# ---------------------------------------------------------------------------
# SHA-256
# ---------------------------------------------------------------------------
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -LiteralPath $hashFile -Value "$($hash) *AHK-Typer.exe" -Encoding ascii

# ---------------------------------------------------------------------------
# Release notes: this version's CHANGELOG section + hash + verify steps
# ---------------------------------------------------------------------------
$lines   = Get-Content -LiteralPath $changelog
$section = New-Object System.Collections.Generic.List[string]
$inside  = $false
foreach ($line in $lines) {
    if ($line -match '^## ') {
        if ($inside) { break }
        if ($line -match "^## $([regex]::Escape($version))( |$)") { $inside = $true; continue }
    }
    if ($inside) { $section.Add($line) }
}
if ($section.Count -eq 0) {
    Write-Warning "No '## $($version)' section in CHANGELOG.md - release notes will have no change list."
}

$sizeKB = [math]::Round((Get-Item -LiteralPath $exe).Length / 1KB)
$notes = @"
$(($section -join "`n").Trim())

## Download

**AHK-Typer.exe** - no installation and no AutoHotkey needed. Run it; it
starts in the system tray (red "T" icon).

Windows may show "Windows protected your PC" because the file is not
code-signed: choose **More info > Run anyway**.

## Verify the download

SHA-256 of AHK-Typer.exe ($($sizeKB) KB):

``````
$($hash)
``````

In PowerShell, in the download folder:

``````powershell
(Get-FileHash .\AHK-Typer.exe -Algorithm SHA256).Hash
``````

The result must match the value above (upper or lower case does not matter).
The same value is in the attached file AHK-Typer.exe.sha256.
"@
Set-Content -LiteralPath $notesFile -Value $notes -Encoding utf8

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
@(
    [PSCustomObject]@{ File = 'AHK-Typer.exe';        SizeKB = $sizeKB; Detail = "version $($version)" }
    [PSCustomObject]@{ File = 'AHK-Typer.exe.sha256'; SizeKB = 1;       Detail = $hash }
    [PSCustomObject]@{ File = 'release-notes.md';     SizeKB = 1;       Detail = 'CHANGELOG section + SHA-256' }
) | Format-Table -AutoSize | Out-String -Width 200 | Write-Host

Write-Host 'Publish with the GitHub CLI (optional), from the repo folder:' -ForegroundColor Cyan
Write-Host "  git tag v$($version) ; git push origin v$($version)"
Write-Host "  gh release create v$($version) dist\AHK-Typer.exe dist\AHK-Typer.exe.sha256 --title `"AHK-Typer $($version)`" --notes-file dist\release-notes.md"
Write-Host 'Or on github.com: Releases > Draft a new release, attach both files and paste release-notes.md.'
