# Build KoordASIOControl.exe on this machine and drop it into the installed
# KoordASIO folder, so control-app changes can be tried without a CI round trip.
#
#   powershell -ExecutionPolicy Bypass -File windows\dev-build-control.ps1 [-Run] [-Deploy] [-Clean]
#
# Qt lives in its own prefix and is the same version CI builds with. Do not point
# this at a Qt belonging to another project on the box: a static Qt produces an
# exe that cannot load the dynamic Qt DLLs sitting beside the installed app, and
# would not resemble the binary that actually ships.
#
# -Deploy re-runs windeployqt, needed only when the QML gains an import from a Qt
# module that is not already deployed next to the installed exe. The .qml files
# are compiled into the exe via app.qrc, so an ordinary UI edit needs nothing
# beyond the default build-and-copy.

param(
    [switch]$Run,
    [switch]$Deploy,
    [switch]$Clean,
    [string]$QtPrefix   = 'C:\koordasio-dev\Qt\6.8.2\msvc2022_64',
    [string]$SourceRoot = 'C:\koordasio-dev\src',
    [string]$BuildDir   = 'C:\koordasio-dev\build',
    [string]$InstallDir = 'C:\Program Files\KoordASIO'
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not (Test-Path (Join-Path $QtPrefix 'lib\cmake\Qt6\Qt6Config.cmake'))) {
    throw "Qt not found at $QtPrefix. Install it with: python -m pip install aqtinstall; python -m aqt install-qt windows desktop 6.8.2 win64_msvc2022_64 -m qtmultimedia -O C:\koordasio-dev\Qt"
}
if (-not (Test-Path (Join-Path $SourceRoot 'src\kdasioconfig\CMakeLists.txt'))) {
    throw "No source mirror at $SourceRoot. Run windows/sync-build-control.sh from the Mac."
}

$vswhere = 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { throw 'vswhere not found - install VS 2022 with the C++ workload' }
$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) { throw 'No VS 2022 C++ toolchain found' }
$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvars64.bat'
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat not found under $vsPath" }

if ($Clean -and (Test-Path $BuildDir)) {
    Write-Host "==> clean $BuildDir"
    Remove-Item -Recurse -Force $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$srcDir = Join-Path $SourceRoot 'src\kdasioconfig'

Write-Host '==> configure'
cmd /c "`"$vcvars`" >nul && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=`"$QtPrefix`" -S `"$srcDir`" -B `"$BuildDir`""
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed ($LASTEXITCODE)" }

Write-Host '==> build'
cmd /c "`"$vcvars`" >nul && cmake --build `"$BuildDir`""
if ($LASTEXITCODE -ne 0) { throw "build failed ($LASTEXITCODE)" }

$exe = Join-Path $BuildDir 'KoordASIOControl.exe'
if (-not (Test-Path $exe)) { throw "expected $exe, not found" }

# Replace the installed copy: that is the one the Start menu and ASIO hosts launch.
Get-Process KoordASIOControl -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 500

$target = Join-Path $InstallDir 'KoordASIOControl.exe'
Copy-Item $exe $target -Force
Write-Host "==> deployed to $target"

if ($Deploy) {
    Write-Host '==> windeployqt'
    & (Join-Path $QtPrefix 'bin\windeployqt.exe') --release --no-compiler-runtime `
        --qmldir $srcDir --no-system-d3d-compiler --no-opengl-sw $target
    if ($LASTEXITCODE -ne 0) { throw "windeployqt failed ($LASTEXITCODE)" }
}

if ($Run) {
    Write-Host '==> launching'
    Start-Process $target
}

Write-Host 'OK'
