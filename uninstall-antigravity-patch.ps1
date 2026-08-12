#!/usr/bin/env pwsh
# ==============================================================================
# uninstall-antigravity-patch.ps1 - Combined Antigravity Patcher (Uninstaller)
# ==============================================================================
# Restores all original files backed up by install-antigravity-patch.ps1
# Usage: pwsh ./uninstall-antigravity-patch.ps1
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step { param([string]$m); Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m); Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m); Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m); Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Info { param([string]$m); Write-Host "  [..] $m" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host "  |   Combined Antigravity Patcher - Uninstaller        |" -ForegroundColor Yellow
Write-Host "  +======================================================+" -ForegroundColor Yellow
Write-Host ""

$backupDir = Join-Path $HOME ".antigravity_backups"

if (-not (Test-Path $backupDir)) {
    Write-Warn "No backup directory found at: $backupDir"
    Write-Info "Nothing to restore. Patch may not have been applied."
    exit 0
}

Write-Step "Locating Antigravity installation..."
$candidates = @(
    "/Applications/Antigravity.app/Contents/Resources",
    "/Applications/Antigravity.app/Contents/MacOS",
    "$HOME/Applications/Antigravity.app/Contents/Resources"
)
$agPath = $null
foreach ($p in $candidates) {
    if (Test-Path $p) { $agPath = $p; Write-OK "Found at: $p"; break }
}
if (-not $agPath) {
    $agPath = Read-Host "  Enter Antigravity resources path (or press Enter to skip)"
    if ([string]::IsNullOrWhiteSpace($agPath) -or -not (Test-Path $agPath)) {
        Write-Warn "Skipping file restore - path not provided."
        $agPath = $null
    }
}

Write-Step "Restoring backed-up files..."
$backups = Get-ChildItem -Path $backupDir -Filter "*.bak" -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending

if ($backups.Count -eq 0) {
    Write-Warn "No backup files found in $backupDir"
} else {
    $restored = @{}
    foreach ($bak in $backups) {
        $orig = $bak.Name -replace "\.\d{8}_\d{6}\.bak$", ""
        if ($restored.ContainsKey($orig)) { continue }
        if ($agPath) {
            $dest = Join-Path $agPath $orig
            try {
                Copy-Item $bak.FullName $dest -Force
                Write-OK "Restored: $orig"
                $restored[$orig] = $true
            } catch {
                Write-Fail "Failed to restore $orig : $_"
            }
        }
    }
    if ($restored.Count -eq 0) {
        Write-Warn "No files restored (Antigravity path not set or no matching files)."
    }
}

Write-Step "Cleaning up..."
$confirm = Read-Host "  Delete backup directory '$backupDir'? (y/N)"
if ($confirm -eq "y" -or $confirm -eq "Y") {
    Remove-Item $backupDir -Recurse -Force
    Write-OK "Backup directory removed."
} else {
    Write-Info "Backup directory kept at: $backupDir"
}

Write-Host ""
Write-Host "  Uninstall complete. Restart Antigravity." -ForegroundColor Green
Write-Host ""
