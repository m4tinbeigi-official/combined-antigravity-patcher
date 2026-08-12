#!/usr/bin/env pwsh
# ==============================================================================
# install-antigravity-patch.ps1 - Combined Antigravity Patcher
# ==============================================================================
# Inspired by and based on:
#   - https://github.com/kakajan/antigravity-patch       (Authorization fix)
#   - https://github.com/AvenCores/open-antigravity-patcher (Region bypass)
# Usage: pwsh ./install-antigravity-patch.ps1
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

function Assert-MacOS {
    if (-not $IsMacOS) {
        Write-Fail "This script only supports macOS. Detected: $($PSVersionTable.OS)"
        exit 1
    }
    Write-OK "macOS detected."
}

function Assert-PSVersion {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Fail "PowerShell 7+ required. Install: brew install --cask powershell"
        exit 1
    }
    Write-OK "PowerShell $($PSVersionTable.PSVersion) OK."
}

function Test-Cmd { param([string]$c); $null -ne (Get-Command $c -ErrorAction SilentlyContinue) }

function Ensure-Homebrew {
    if (Test-Cmd "brew") { Write-OK "Homebrew already installed."; return }
    Write-Warn "Homebrew not found - installing..."
    $installScript = Invoke-RestMethod "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    bash -c $installScript
    if ($LASTEXITCODE -ne 0) { Write-Fail "Homebrew install failed."; exit 1 }
    Write-OK "Homebrew installed."
}

function Ensure-Wine {
    if (Test-Cmd "wine") { Write-OK "Wine already installed."; return }
    Write-Warn "Wine not found - installing via Homebrew..."
    brew install --cask wine-stable
    if ($LASTEXITCODE -ne 0) { Write-Fail "Wine install failed."; exit 1 }
    Write-OK "Wine installed."
}

function Get-LatestAssetUrl {
    param([string]$Owner, [string]$Repo, [string]$Pattern)
    $api = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
    $rel = Invoke-RestMethod -Uri $api -Headers @{ "User-Agent" = "CombinedAntigravityPatcher/1.0" }
    $asset = $rel.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $asset) { Write-Fail "Asset '$Pattern' not found in $Owner/$Repo"; exit 1 }
    return $asset.browser_download_url
}

function Download-File {
    param([string]$Url, [string]$Dest)
    Write-Info "Downloading: $([System.IO.Path]::GetFileName($Dest))"
    Invoke-WebRequest -Uri $Url -OutFile $Dest -UseBasicParsing
    $size = [math]::Round((Get-Item $Dest).Length / 1024, 1)
    Write-OK "Downloaded ($size KB)"
}

function Get-AGPath {
    $paths = @(
        "/Applications/Antigravity.app/Contents/Resources",
        "/Applications/Antigravity.app/Contents/MacOS",
        "$HOME/Applications/Antigravity.app/Contents/Resources"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { Write-OK "Antigravity found at: $p"; return $p }
    }
    Write-Warn "Antigravity not found in default locations."
    $custom = Read-Host "  Enter Antigravity resources path (or press Enter to skip)"
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
        Write-Info "Manually copy '$dll' to your Antigravity resources folder."
    }
}

function Apply-RegionPatch {
    param([string]$WorkDir)
    Write-Step "Patch 2/2 - open-antigravity-patcher (Region Bypass)"
    Write-Info "Source: https://github.com/AvenCores/open-antigravity-patcher"
    $url = Get-LatestAssetUrl -Owner "AvenCores" -Repo "open-antigravity-patcher" -Pattern "*.exe"
    $exe = Join-Path $WorkDir "Open.AG.Patcher.exe"
    Download-File -Url $url -Dest $exe
    Write-Info "Running patcher via Wine..."
    $out = wine $exe --apply 2>&1
    Write-Info $out
    if ($LASTEXITCODE -eq 0) {
        Write-OK "Region patch applied."
    } else {
        Write-Warn "Patcher exited with code $LASTEXITCODE. If HTTP 500, try another account."
    }
}

# ---- MAIN ------------------------------------------------------------------
Write-Banner

Write-Step "Checking environment..."
Assert-MacOS
Assert-PSVersion

Write-Step "Checking dependencies..."
Ensure-Homebrew
Ensure-Wine

$workDir   = Join-Path ([System.IO.Path]::GetTempPath()) "antigravity_combined_$(Get-Date -Format yyyyMMddHHmmss)"
$backupDir = Join-Path $HOME ".antigravity_backups"
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
Write-Host "  To uninstall: pwsh ./uninstall-antigravity-patch.ps1" -ForegroundColor DarkGray
Write-Host ""
