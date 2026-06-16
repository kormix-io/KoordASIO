# Capture KoordASIOControl window via built-in -screenshot flag (works over SSH).
param(
    [string]$Exe = 'C:\kormix\KoordASIO-dev\build\kdasioconfig\KoordASIOControl.exe',
    [string]$Out = 'C:\kormix\KoordASIO-dev\screenshot.png'
)

$ErrorActionPreference = 'Stop'
Stop-Process -Name KoordASIOControl -Force -ErrorAction SilentlyContinue

Write-Host "Capturing via -screenshot=$Out"
cmd /c "`"$Exe`" -screenshot=$Out"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Test-Path $Out)) { throw "Screenshot not created: $Out" }
Write-Host "Saved $Out"
