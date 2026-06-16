# Local dev build for KoordASIOControl (control app only).
# Usage: powershell -ExecutionPolicy Bypass -File windows\dev-build-control.ps1 [-Debug] [-Deploy]
param(
    [switch]$Debug,
    [switch]$Deploy
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BuildDir = Join-Path $Root 'build\kdasioconfig'
$QtPrefix = 'C:\kormix\kormix-app\qt6-static-build'
$FfmpegDir = Join-Path $QtPrefix 'ffmpeg'

$vcvars = @(
    'C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat',
    'C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat',
    'C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat',
    'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $vcvars) {
    throw 'vcvars64.bat not found - install VS 2022 C++ workload'
}
if (-not (Test-Path (Join-Path $QtPrefix 'lib\cmake\Qt6\Qt6Config.cmake'))) {
    throw "Qt not found at $QtPrefix"
}

$BuildType = if ($Debug) { 'Debug' } else { 'Release' }
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

Write-Host "==> cmake configure ($BuildType)"
$src = Join-Path $Root 'src\kdasioconfig'
$cmakeLine = "cmake -DCMAKE_PREFIX_PATH=`"$QtPrefix`" -DFFMPEG_DIR=`"$FfmpegDir`" -DCMAKE_BUILD_TYPE=$BuildType -G `"NMake Makefiles`" -S `"$src`" -B `"$BuildDir`""
if ($Debug) {
    $cmakeLine += ' -DCMAKE_CXX_FLAGS=/DCONSOLE_DEBUG'
}
cmd /c "`"$vcvars`" && $cmakeLine"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> nmake'
cmd /c "`"$vcvars`" && cd /d `"$BuildDir`" && nmake"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exe = Join-Path $BuildDir 'KoordASIOControl.exe'
if (-not (Test-Path $exe)) {
    throw "Build failed - $exe not found"
}

if ($Deploy) {
    $windeployqt = Join-Path $QtPrefix 'bin\windeployqt.exe'
    if (-not (Test-Path $windeployqt)) {
        throw "windeployqt not found at $windeployqt (static Qt may not need deploy)"
    }
    Write-Host '==> windeployqt'
    & $windeployqt --$($BuildType.ToLower()) --qmldir (Join-Path $Root 'src\kdasioconfig') $exe
}

Write-Host "OK: $exe"
