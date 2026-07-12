param(
    [string]$AddOnsDir = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

$satellites = @("OffBeat_Evoker", "OffBeat_Mage", "OffBeat_Monk", "OffBeat_DeathKnight", "OffBeat_Paladin")

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

Read-Host "Press Enter to exit"
