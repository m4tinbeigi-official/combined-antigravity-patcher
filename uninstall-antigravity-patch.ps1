# ===========================================================================
# uninstall-antigravity-patch.ps1 – Self‑contained remover for Combined Antigravity Patcher
# ===========================================================================
# This script restores any files that were backed up by the installer and removes
# the downloaded patch files. It is completely independent – no external helper
# scripts are required.
# ===========================================================================

# ------------------------------- Configuration ------------------------------
$AntigravityPath = "$HOME/Library/Application Support/Antigravity" # macOS default
# For Windows you could use: $Env:LOCALAPPDATA + "\\Antigravity"
# ------------------------------------------------------------------------

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-ErrorMsg { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }

function Restore-Backups {
    Write-Info "Scanning for backup files in $AntigravityPath..."
    $backups = Get-ChildItem -Path $AntigravityPath -Filter "*.bak_*" -File
    if (-not $backups) {
        Write-Info "No backup files found – nothing to restore."
        return
    }
    foreach ($bak in $backups) {
        $original = $bak.FullName -replace "\\.bak_.*$", ""
        Write-Info "Restoring $original from backup $($bak.Name)"
        if (Test-Path $original) { Remove-Item -LiteralPath $original -Force }
        Move-Item -LiteralPath $bak.FullName -Destination $original -Force
    }
    Write-Info "Restoration complete."
}

function Remove-PatchFiles {
    $files = @(
        Join-Path $AntigravityPath "version.dll",
        Join-Path $AntigravityPath "open-antigravity-patcher"
    )
    foreach ($f in $files) {
        if (Test-Path $f) {
            Write-Info "Removing patch file $f"
            Remove-Item -LiteralPath $f -Force
        }
    }
}

# ------------------------------------------------------------------------
# Main execution
# ------------------------------------------------------------------------
if (-not (Test-Path $AntigravityPath)) {
    Write-ErrorMsg "Antigravity directory not found at $AntigravityPath. Adjust the script if needed."
    exit 1
}

Restore-Backups
Remove-PatchFiles

Write-Info "All patches have been removed and original files restored."
Write-Host "You can now run Antigravity without the combined patches."
# End of script
