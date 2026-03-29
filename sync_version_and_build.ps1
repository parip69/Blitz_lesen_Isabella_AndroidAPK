[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$versionFile = Join-Path $scriptRoot "version.properties"
$indexFile = Join-Path $scriptRoot "app\src\main\assets\index.html"
$gradlewBat = Join-Path $scriptRoot "gradlew.bat"
$privatDir = Join-Path $scriptRoot "Privat"
$apkOutputDir = Join-Path $scriptRoot "app\build\outputs\apk"

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Get-CurrentVersionCode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Versionsdatei nicht gefunden: $Path"
    }

    $match = Select-String -Path $Path -Pattern '^\s*VERSION_CODE\s*=\s*(\d+)\s*$'
    if (-not $match) {
        throw "In '$Path' wurde kein gueltiger VERSION_CODE gefunden."
    }

    return [int]$match.Matches[0].Groups[1].Value
}

function Get-CurrentVersionName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Versionsdatei nicht gefunden: $Path"
    }

    $match = Select-String -Path $Path -Pattern '^\s*VERSION_NAME\s*=\s*(.+?)\s*$'
    if (-not $match) {
        throw "In '$Path' wurde kein gueltiger VERSION_NAME gefunden."
    }

    return $match.Matches[0].Groups[1].Value.Trim()
}

function Set-VersionProperties {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [int]$VersionCode,
        [Parameter(Mandatory = $true)]
        [string]$VersionName
    )

    $content = @(
        "# Zentrale App-Version"
        "VERSION_CODE=$VersionCode"
        "VERSION_NAME=$VersionName"
        ""
    ) -join "`n"

    Write-Utf8NoBom -Path $Path -Content $content
}

function Set-IndexVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$VersionName
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "index.html nicht gefunden: $Path"
    }

    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)

    if ($content -notmatch 'data-app-version="') {
        throw "In index.html wurde kein data-app-version-Attribut gefunden."
    }

    $content = [regex]::Replace(
        $content,
        '(<footer\b[^>]*\bdata-app-version=")[^"]*(")',
        ('${1}' + $VersionName + '${2}'),
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if ($content -match 'id="appVersion"') {
        $content = [regex]::Replace(
            $content,
            '(<span\b[^>]*\bid="appVersion"[^>]*>)[^<]*(</span>)',
            ('${1}' + $VersionName + '${2}'),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
    }

    Write-Utf8NoBom -Path $Path -Content $content
}

function Find-VersionedApk {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$VersionName
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    Get-ChildItem -Path $Path -Recurse -File -Filter "*.apk" |
        Where-Object { $_.Name -eq "BlitzLesen-v$VersionName.apk" } |
        Select-Object -First 1
}

Push-Location $scriptRoot
try {
    if ($SkipBuild) {
        $currentVersionCode = Get-CurrentVersionCode -Path $versionFile
        $nextVersionCode = $currentVersionCode + 1
        $nextVersionName = $nextVersionCode.ToString()

        Set-VersionProperties -Path $versionFile -VersionCode $nextVersionCode -VersionName $nextVersionName
        Set-IndexVersion -Path $indexFile -VersionName $nextVersionName

        Write-Host "Version auf $nextVersionName synchronisiert."
        Write-Host "Build wurde mit -SkipBuild uebersprungen."
        return
    }

    if (-not (Test-Path -LiteralPath $gradlewBat)) {
        throw "gradlew.bat nicht gefunden: $gradlewBat"
    }

    & $gradlewBat assembleDebug
    if ($LASTEXITCODE -ne 0) {
        throw "Gradle-Build fehlgeschlagen."
    }

    $builtVersionName = Get-CurrentVersionName -Path $versionFile
    Write-Host "Build hat Version $builtVersionName erstellt."

    New-Item -ItemType Directory -Force -Path $privatDir | Out-Null

    $htmlArchivePath = Join-Path $privatDir "Blitzlesen_v$builtVersionName.html"
    Copy-Item -LiteralPath $indexFile -Destination $htmlArchivePath -Force

    $apkFile = Find-VersionedApk -Path $apkOutputDir -VersionName $builtVersionName
    if (-not $apkFile) {
        throw "Es wurde keine APK mit dem Namen 'BlitzLesen-v$builtVersionName.apk' gefunden."
    }

    $apkArchivePath = Join-Path $privatDir $apkFile.Name
    Copy-Item -LiteralPath $apkFile.FullName -Destination $apkArchivePath -Force

    Write-Host "Archivkopien erstellt:"
    Write-Host " - $htmlArchivePath"
    Write-Host " - $apkArchivePath"
}
finally {
    Pop-Location
}
