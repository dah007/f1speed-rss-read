<#
.SYNOPSIS
    Builds EXE installers (x64 and ARM64) for the F1Speed Feed Read Command Palette
    extension, for distribution outside the Microsoft Store / WinGet (e.g. GitHub Releases).
.DESCRIPTION
    Publishes the project as an unpackaged, self-contained app for each architecture,
    then runs Inno Setup (setup.iss) to produce a signed-nothing but fully working
    installer/uninstaller EXE for each.
#>

param(
    [string]$Configuration = "Release",
    [string]$Version = "0.0.1"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$projectPath = Join-Path $PSScriptRoot "..\F1RssFeedRead\F1RssFeedRead.csproj"
if (-not (Test-Path $projectPath)) {
    Write-Error "Project file not found at '$projectPath'"
    exit 1
}

$innoCandidates = @(
    "C:\Program Files\Inno Setup 7\ISCC.exe"
    "C:\Program Files (x86)\Inno Setup 7\ISCC.exe"
    "C:\Program Files\Inno Setup 6\ISCC.exe"
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)
$innoCompiler = $innoCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $innoCompiler) {
    Write-Error "Inno Setup not found. Install it from https://jrsoftware.org/isdl.php"
    exit 1
}

# .NET RID -> Inno Setup ArchitecturesAllowed identifier
$architectures = @{
    "x64"   = "x64compatible"
    "arm64" = "arm64"
}

foreach ($rid in $architectures.Keys) {
    $innoArch = $architectures[$rid]
    Write-Host "`n=== Building win-$rid ===" -ForegroundColor Cyan

    Remove-Item -Recurse -Force "publish" -ErrorAction SilentlyContinue

    # -p:WindowsPackageType=None overrides the MSIX packaging used for local
    # Visual Studio Deploy/debug, without touching the .csproj, so day-to-day
    # development against the (Package) launch profile is unaffected.
    dotnet publish $projectPath -c $Configuration -r "win-$rid" -o "publish" `
        -p:WindowsPackageType=None `
        -p:SelfContained=true `
        -p:Version=$Version
    if ($LASTEXITCODE -ne 0) {
        Write-Error "dotnet publish failed for $rid"
        exit 1
    }

    & $innoCompiler /DMyAppVersion="$Version" /DArchitecturesAllowed="$innoArch" "setup.iss"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Inno Setup failed for $rid"
        exit 1
    }

    Write-Host "=== win-$rid complete ===" -ForegroundColor Green
}

Remove-Item -Recurse -Force "publish" -ErrorAction SilentlyContinue

Write-Host "`nInstallers created in '.\Installer':" -ForegroundColor Cyan
Get-ChildItem -Path "Installer" -Filter "*.exe" | ForEach-Object { Write-Host "  $($_.Name)" }
