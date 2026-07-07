$ErrorActionPreference = "Stop"

# Symlinks satellite addons into the same AddOns directory as the core
# so WoW can discover them during development.
#
# Usage: run from the OffBeat repo root, or pass the AddOns path:
#   .\dev_install.ps1
#   .\dev_install.ps1 -AddOnsDir "C:\...\Interface\AddOns"

param(
    [string]$AddOnsDir = (Split-Path -Parent $PSScriptRoot)
)

$satellites = @("OffBeat_Evoker", "OffBeat_Monk", "OffBeat_DeathKnight", "OffBeat_Paladin")

foreach ($sat in $satellites) {
    $src = Join-Path $PSScriptRoot $sat
    $dest = Join-Path $AddOnsDir $sat

    if (-not (Test-Path $src)) {
        Write-Host "$sat`: not found, skipping"
        continue
    }

    if (Test-Path $dest) {
        $item = Get-Item $dest
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
            Write-Host "$sat`: symlink exists"
        } else {
            Write-Host "$sat`: directory exists (not a symlink), skipping"
        }
        continue
    }

    New-Item -ItemType Junction -Path $dest -Target $src | Out-Null
    Write-Host "$sat`: linked"
}
