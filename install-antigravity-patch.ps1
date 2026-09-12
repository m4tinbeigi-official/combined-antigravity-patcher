# ===========================================================================
# install-antigravity-patch.ps1 – Self‑contained installer for Combined Antigravity Patcher
# ===========================================================================
# This script automatically:
#   1️⃣ Downloads the latest `version.dll` from the antigravity‑patch repository.
#   2️⃣ Downloads the latest `open‑antigravity‑patcher` binary.
#   3️⃣ Backs up any existing files before overwriting.
#   4️⃣ Installs both patches into the Antigravity installation directory.
#   5️⃣ Provides a simple cleanup / uninstall option.
#
# The script is **stand‑alone** – it does not depend on external helper files.
# It works on macOS (requires PowerShell 7+ which is pre‑installed on recent macOS) and
# Windows (PowerShell 5.1+). No additional modules are required.
# ===========================================================================

# ------------------------------- Configuration ------------------------------
# Change these values if your Antigravity installation resides elsewhere.
$AntigravityPath = "$HOME/Library/Application Support/Antigravity" # macOS default path
# For Windows you could use: $Env:LOCALAPPDATA + "\\Antigravity"

# GitHub repositories (public)
$RepoAntigravityPatch = "kakajan/antigravity-patch"
$RepoOpenAntigravity = "AvenCores/open-antigravity-patcher"

# ------------------------------------------------------------------------

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Get-LatestReleaseAsset {
    param(
        [string]$Repo,
        [string]$AssetPattern  # regex pattern to match the desired asset name
    )
    $apiUrl = "https://api.github.com/repos/$Repo/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
    } catch {
        Write-ErrorMsg "Failed to query GitHub API for $Repo"
        return $null
    }
    foreach ($asset in $release.assets) {
        if ($asset.name -match $AssetPattern) {
            return $asset.browser_download_url
        }
    }
    Write-ErrorMsg "No asset matching pattern '$AssetPattern' found in $Repo latest release"
    return $null
}

function Download-File {
    param(
        [string]$Url,
        [string]$DestinationPath
    )
    Write-Info "Downloading $Url ..."
    try {
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath -UseBasicParsing -Headers @{ "User-Agent" = "PowerShell" }
    } catch {
        Write-ErrorMsg "Download failed: $Url"
        return $false
    }
    return $true
}

function Backup-IfExists {
    param([string]$Path)
    if (Test-Path $Path) {
        $backup = "$Path.bak_$(Get-Date -Format 'yyyyMMddHHmmss')"
        Write-Info "Backing up existing $Path -> $backup"
        Move-Item -LiteralPath $Path -Destination $backup
    }
}

function Install-AntigravityPatch {
    Write-Info "--- Installing antigravity‑patch (DLL) ---"
    $dllUrl = Get-LatestReleaseAsset -Repo $RepoAntigravityPatch -AssetPattern "\\.dll$"
    if (-not $dllUrl) { return }
    $targetDll = Join-Path $AntigravityPath "version.dll"
    Backup-IfExists -Path $targetDll
    $tempPath = Join-Path $env:TEMP "version.dll"
    if (Download-File -Url $dllUrl -DestinationPath $tempPath) {
        Move-Item -LiteralPath $tempPath -Destination $targetDll -Force
        Write-Info "DLL installed to $targetDll"
    }
}

function Install-OpenAntigravityPatch {
    Write-Info "--- Installing open‑antigravity‑patcher (binary) ---"
    $exeUrl = Get-LatestReleaseAsset -Repo $RepoOpenAntigravity -AssetPattern "(\\.exe|\\.bin|\\.app)$"
    if (-not $exeUrl) { return }
    $targetExe = Join-Path $AntigravityPath "open-antigravity-patcher"
    Backup-IfExists -Path $targetExe
    $tempPath = Join-Path $env:TEMP "open-antigravity-patcher"
    if (Download-File -Url $exeUrl -DestinationPath $tempPath) {
        # Ensure executable permission on *nix
        if ($IsMacOS) { chmod +x $tempPath }
        Move-Item -LiteralPath $tempPath -Destination $targetExe -Force
        Write-Info "Patch binary installed to $targetExe"
    }
}

function Show-Usage {
    Write-Host "Usage: install-antigravity-patch.ps1 [-Uninstall]"
    Write-Host "   -Uninstall   Remove previously installed patches and restore backups"
}

# ------------------------------------------------------------------------
# Main execution flow
# ------------------------------------------------------------------------
param(
    [switch]$Uninstall
)

if ($Uninstall) {
    Write-Info "Uninstall requested – restoring backups if they exist."
    Get-ChildItem -Path $AntigravityPath -Filter "*.bak_*" -File | ForEach-Object {
        $original = $_.FullName -replace "\\.bak_.*$", ""
        Write-Info "Restoring $original from backup $($_.Name)"
        Move-Item -LiteralPath $_.FullName -Destination $original -Force
    }
    Write-Info "Uninstall complete."
    exit 0
}

if (-not (Test-Path $AntigravityPath)) {
    Write-ErrorMsg "Antigravity directory not found at $AntigravityPath. Please adjust `$AntigravityPath` in the script."
    exit 1
}

Install-AntigravityPatch
Install-OpenAntigravityPatch

Write-Info "All patches applied successfully."
Write-Host "\nYou may now launch Antigravity. If you encounter issues, run this script with -Uninstall to revert."

# End of script
