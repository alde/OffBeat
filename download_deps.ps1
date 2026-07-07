$ErrorActionPreference = "Stop"

if (-not (Get-Command svn -ErrorAction SilentlyContinue)) {
    Write-Host "svn not found, installing via Chocolatey..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Error "Chocolatey is not installed. Install it from https://chocolatey.org/install then re-run this script."
        exit 1
    }
    choco install svn -y
    refreshenv
}

New-Item -ItemType Directory -Force -Path Libs | Out-Null

$inExternals = $false
$currentPath = ""
$currentUrl = ""

function Invoke-Checkout {
    if ($currentPath -and $currentUrl) {
        $localPath = $currentPath -replace "/", "\"
        Write-Host "Fetching ${currentPath}..."
        if ($currentUrl -match "github\.com") {
            if (Test-Path $localPath) { Remove-Item -Recurse -Force $localPath }
            git clone --depth 1 $currentUrl $localPath
        } else {
            svn checkout $currentUrl $localPath
        }
        Write-Host "Done."
    }
}

foreach ($raw in Get-Content .pkgmeta) {
    $line = ($raw -replace "#.*", "").TrimEnd()

    if ($line -match "^externals:") {
        $inExternals = $true
        continue
    }

    if (-not $inExternals) { continue }

    if ($line -and $line -notmatch "^\s") { break }

    if ($line -match "^  \S" -and $line -match ":") {
        Invoke-Checkout
        $currentPath = $line.Trim().TrimEnd(":")
        $currentUrl = ""
    }

    if ($line -match "^\s+url:\s*(.+)") {
        $currentUrl = $Matches[1]
    }
}

Invoke-Checkout
