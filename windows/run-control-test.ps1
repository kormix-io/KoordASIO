# Launch KoordASIOControl and print exit code + tail of log file.
param(
    [string]$Exe = 'C:\kormix\KoordASIO-dev\build\kdasioconfig\KoordASIOControl.exe',
    [string[]]$Args = @()
)

$log = Join-Path $env:TEMP 'KoordASIOControl.log'
if (Test-Path $log) { Remove-Item $log -Force }

Write-Host "Running: $Exe $($Args -join ' ')"
if ($Args.Count -gt 0) {
    $p = Start-Process -FilePath $Exe -ArgumentList $Args -Wait -PassThru
} else {
    $p = Start-Process -FilePath $Exe -Wait -PassThru
}
Write-Host "EXIT: $($p.ExitCode)"

if (Test-Path $log) {
    Write-Host '--- log ---'
    Get-Content $log -Tail 40
} else {
    Write-Host "No log at $log"
}
