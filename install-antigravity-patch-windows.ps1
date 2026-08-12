#!/usr/bin/env pwsh
# ==============================================================================
# install-antigravity-patch-windows.ps1 - Combined Antigravity Patcher (Windows)
# ==============================================================================
# Inspired by and based on:
#   - https://github.com/kakajan/antigravity-patch       (Authorization fix)
#   - https://github.com/AvenCores/open-antigravity-patcher (Region bypass)
# Usage: Run PowerShell as Administrator, then:
#   pwsh ./install-antigravity-patch-windows.ps1
# ==============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Banner {
    Write-Host ""
    Write-Host "  +======================================================+" -ForegroundColor Magenta
    Write-Host "  |      Combined Antigravity Patcher  v1.0.0           |" -ForegroundColor Magenta
    Write-Host "  |   Authorization Fix + Region Restriction Bypass     |" -ForegroundColor Magenta
    Write-Host "  +------------------------------------------------------+" -ForegroundColor DarkMagenta
    Write-Host "  |  Inspired by:                                       |" -ForegroundColor DarkMagenta
    Write-Host "  |    kakajan/antigravity-patch                        |" -ForegroundColor DarkMagenta
    Write-Host "  |    AvenCores/open-antigravity-patcher               |" -ForegroundColor DarkMagenta
    Write-Host "  +======================================================+" -ForegroundColor Magenta
    Write-Host ""
}

function Write-Step { param([string]$m); Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m); Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Warn { param([string]$m); Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Fail { param([string]$m); Write-Host "  [XX] $m" -ForegroundColor Red }
function Write-Info { param([string]$m); Write-Host "  [..] $m" -ForegroundColor DarkGray }

function Assert-Windows {
    if (-not $IsWindows) {
        Write-Fail "This script only supports Windows. For macOS use install-antigravity-patch.ps1"
        exit 1
    }
    Write-OK "Windows detected: $($PSVersionTable.OS)"
}

function Assert-PSVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Fail "PowerShell 5+ required."
        exit 1
    }
    Write-OK "PowerShell $($PSVersionTable.PSVersion) OK."
}

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
    if (-not $isAdmin) {
        Write-Warn "Not running as Administrator. Some operations may fail."
        Write-Info "Right-click PowerShell and choose Run as Administrator for best results."
    } else {
        Write-OK "Running as Administrator."
    }
}

function Get-LatestAssetUrl {
    param([string]$Owner, [string]$Repo, [string]$Pattern)
    $api = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    try {
        $rel = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "CombinedAntigravityPatcher/1.0" }
        $asset = $rel.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
        if (-not $asset) { Write-Fail "Asset '$Pattern' not found in $Owner/$Repo"; exit 1 }
        return $asset.browser_download_url
    } catch {
        Write-Fail "Could not fetch release info from $Owner/$Repo : $_"
        exit 1
    }
}

function Download-File {
    param([string]$Url, [string]$Dest)
    Write-Info "Downloading: $([System.IO.Path]::GetFileName($Dest))"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
    $size = [math]::Round((Get-Item $Dest).Length / 1024, 1)
    Write-OK "Downloaded ($size KB)"
}

function Get-AGPath {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\Antigravity",
        "$env:PROGRAMFILES\Google\Antigravity",
        "$env:PROGRAMFILES(X86)\Google\Antigravity",
        "$env:LOCALAPPDATA\Google\Antigravity"
    )
    foreach ($p in $candidates) {
        if (Test-Path $p) { Write-OK "Antigravity found at: $p"; return $p }
    }
    Write-Warn "Antigravity not found in default locations."
    $custom = Read-Host "  Enter Antigravity installation path (or press Enter to skip)"
    if ((-not [string]::IsNullOrWhiteSpace($custom)) -and (Test-Path $custom)) { return $custom }
    return $null
}

function Backup-FileIfExists {
    param([string]$File, [string]$BackupDir)
    if (-not (Test-Path $File)) { return }
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    $name = Split-Path $File -Leaf
    $ts   = Get-Date -Format "yyyyMMdd_HHmmss"
    $dest = Join-Path $BackupDir "${name}.${ts}.bak"
    Copy-Item $File $dest -Force
    Write-OK "Backed up: $name"
}

function Apply-AuthPatch {
    param([string]$WorkDir, [string]$BackupDir, [string]$AGPath)
    Write-Step "Patch 1/2 - antigravity-patch (Authorization Fix)"
    Write-Info "Source: https://github.com/kakajan/antigravity-patch"
    $url = Get-LatestAssetUrl -Owner "kakajan" -Repo "antigravity-patch" -Pattern "*.dll"
    $dll = Join-Path $WorkDir "version.dll"
    Download-File -Url $url -Dest $dll
    if ($AGPath) {
        $target = Join-Path $AGPath "version.dll"
        Backup-FileIfExists -File $target -BackupDir $BackupDir
        Copy-Item $dll $target -Force
        Write-OK "version.dll installed to: $target"
    } else {
        Write-Warn "Antigravity path not found - skipping DLL placement."
        Write-Info "Manually copy '$dll' to your Antigravity installation folder."
    }
}

function Apply-RegionPatch {
    param([string]$WorkDir)
    Write-Step "Patch 2/2 - open-antigravity-patcher (Region Bypass)"
    Write-Info "Source: https://github.com/AvenCores/open-antigravity-patcher"
    $url = Get-LatestAssetUrl -Owner "AvenCores" -Repo "open-antigravity-patcher" -Pattern "*.exe"
    $exe = Join-Path $WorkDir "Open.AG.Patcher.exe"
    Download-File -Url $url -Dest $exe
    Write-Info "Running patcher..."
    $proc = Start-Process -FilePath $exe -ArgumentList "--apply" -Wait -PassThru -NoNewWindow
    if ($proc.ExitCode -eq 0) {
        Write-OK "Region patch applied successfully."
    } else {
        Write-Warn "Patcher exited with code $($proc.ExitCode). If HTTP 500, try switching your Google account."
    }
}

# ---- MAIN ------------------------------------------------------------------
Write-Banner

Write-Step "Checking environment..."
Assert-Windows
Assert-PSVersion
Assert-Admin

$workDir   = Join-Path $env:TEMP "antigravity_combined_$(Get-Date -Format yyyyMMddHHmmss)"
$backupDir = Join-Path $env:USERPROFILE ".antigravity_backups"
New-Item -ItemType Directory -Path $workDir -Force | Out-Null
Write-Info "Work dir: $workDir"

Write-Step "Locating Antigravity..."
$agPath = Get-AGPath

Apply-AuthPatch   -WorkDir $workDir -BackupDir $backupDir -AGPath $agPath
Apply-RegionPatch -WorkDir $workDir

Remove-Item $workDir -Recurse -Force
Write-Info "Cleaned up temp files."

Write-Host ""
Write-Host "  All patches applied! Restart Antigravity and sign in." -ForegroundColor Green
Write-Host "  To uninstall: pwsh ./uninstall-antigravity-patch-windows.ps1" -ForegroundColor DarkGray
Write-Host ""
