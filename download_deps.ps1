$ErrorActionPreference = "Stop"

foreach ($cmd in @("svn", "git")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd is required but not found."
        exit 1
    }
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
