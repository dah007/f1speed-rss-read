<#
.SYNOPSIS
    Builds signed, sideloadable MSIX packages (x64 and ARM64) for the F1Speed Feed
    Read Command Palette extension, for distribution via GitHub Releases.
.DESCRIPTION
    Command Palette only discovers extensions through Windows' AppExtensionCatalog,
    which enumerates *installed packages* that declare the com.microsoft.commandpalette
    app extension in their manifest — it does not scan COM registry entries. So unlike
    a typical Win32 app, this extension has to ship as a real MSIX package, not a plain
    EXE installer, even outside the Store.

    This script:
      1. Finds (or creates) a self-signed code-signing certificate whose Subject
         matches the Identity/Publisher in Package.appxmanifest.
      2. Publishes + packages the app as a signed, sideload-only MSIX for each
         architecture, using the project's single-project MSIX packaging tooling.
      3. Exports the certificate's public half (.cer, no private key) so end users
         can trust it before installing — see README.md for the install steps.
#>

param(
    [string]$Configuration = "Release",
    [string]$Version = "0.0.1",
    [string]$CertSubject = "CN=dah007"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$projectPath = Join-Path $PSScriptRoot "..\F1RssFeedRead\F1RssFeedRead.csproj"
if (-not (Test-Path $projectPath)) {
    Write-Error "Project file not found at '$projectPath'"
    exit 1
}

$outDir = Join-Path $PSScriptRoot "Release"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# --- Certificate: reuse one already in the store, or create one ---
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert |
    Where-Object { $_.Subject -eq $CertSubject } |
    Sort-Object NotAfter -Descending |
    Select-Object -First 1

if (-not $cert) {
    Write-Host "No existing signing certificate found for '$CertSubject' — creating one." -ForegroundColor Yellow
    $cert = New-SelfSignedCertificate -Type Custom -Subject $CertSubject `
        -KeyUsage DigitalSignature -FriendlyName "F1Speed Feed Read Code Signing" `
        -CertStoreLocation "Cert:\CurrentUser\My" `
        -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3", "2.5.29.19={text}")
}

Write-Host "Using signing certificate: $($cert.Thumbprint) ($($cert.Subject))" -ForegroundColor Cyan

$cerPath = Join-Path $outDir "F1SpeedFeedRead.cer"
Export-Certificate -Cert $cert -FilePath $cerPath -Force | Out-Null

# --- Build a signed MSIX per architecture ---
# MSBuild's Platform moniker for MSIX packaging is "ARM64" (uppercase), not the
# .NET RID "arm64" used elsewhere (e.g. RuntimeIdentifiers in the .csproj).
$architectures = @{
    "x64"   = "x64"
    "ARM64" = "arm64"
}

foreach ($platform in $architectures.Keys) {
    Write-Host "`n=== Packaging $platform ===" -ForegroundColor Cyan

    dotnet publish $projectPath -c $Configuration `
        -p:Platform=$platform `
        -p:SelfContained=true `
        -p:Version=$Version `
        -p:GenerateAppxPackageOnBuild=true `
        -p:AppxPackageSigningEnabled=true `
        -p:PackageCertificateThumbprint=$($cert.Thumbprint) `
        -p:UapAppxPackageBuildMode=SideloadOnly `
        -p:AppxBundle=Never `
        -p:AppxPackageDir="$outDir\$platform\"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "dotnet publish/package failed for $platform"
        exit 1
    }

    Write-Host "=== $platform complete ===" -ForegroundColor Green
}

Write-Host "`nSigned packages and certificate in '$outDir':" -ForegroundColor Cyan
Get-ChildItem -Path $outDir -Filter "*.msix" -Recurse | ForEach-Object { Write-Host "  $($_.FullName.Substring($outDir.Length + 1))" }
Write-Host "  F1SpeedFeedRead.cer  (give this to users to trust before installing)"
