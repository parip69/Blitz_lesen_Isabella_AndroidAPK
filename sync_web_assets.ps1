[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$gradlewBat = Join-Path $scriptRoot "gradlew.bat"

if (-not (Test-Path -LiteralPath $gradlewBat)) {
    throw "gradlew.bat nicht gefunden: $gradlewBat"
}

Push-Location $scriptRoot
try {
    & $gradlewBat syncGitHubPagesDocs
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle-Sync fuer Web-Assets fehlgeschlagen."
    }

    Write-Host "Web-Assets und docs/ wurden synchronisiert."
}
finally {
    Pop-Location
}
