# Unified KoordASIO Windows build for CI and local use.
#
# CI stages:
#   setup         - install Qt, build tools, cache deps
#   build         - compile, package installer, sign
#   get-artifacts - expose installer path to the workflow
#
# Local example:
#   $env:koordasio_buildversionstring = '2.2.0'
#   .\.github\autobuild\build.ps1 setup
#   .\.github\autobuild\build.ps1 build
#
# Environment (CI):
#   koordasio_buildversionstring  - required for build/get-artifacts
#   WINDOWS_CODESIGN_CERT         - base64 pfx (optional; skips signing if unset)
#   WINDOWS_CODESIGN_PWD          - pfx password

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('setup', 'build', 'get-artifacts')]
    [string]$Stage
)

$ErrorActionPreference = 'Stop'

# --- toolchain versions ---
$QtVersion = '6.8.2'
$QtArch = 'win64_msvc2022_64'
$QtCompileSubdir = 'msvc2022_64'
$AqtinstallVersion = '3.1.18'
$JomVersion = '1.1.2'

$QtDir = 'C:\Qt'
$ChocoCacheDir = 'C:\ChocoCache'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$BuildPath = Join-Path $RepoRoot 'build'
$DeployPath = Join-Path $RepoRoot 'deploy'
$WindowsPath = Join-Path $RepoRoot 'windows'
$AppName = 'KoordASIO'

$AsioSdkName = 'asiosdk_2.3.3_2019-06-14'
$AsioSdkUrl = 'https://download.steinberg.net/sdk_downloads/asiosdk_2.3.3_2019-06-14.zip'

function Get-BuildVersion {
    if (-not $env:koordasio_buildversionstring) {
        throw 'Environment variable koordasio_buildversionstring must be set'
    }
    if ($env:koordasio_buildversionstring -notmatch '^\d+\.\d+\.\d+') {
        throw "Invalid koordasio_buildversionstring: $($env:koordasio_buildversionstring)"
    }
    return $env:koordasio_buildversionstring
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @()
    )
    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Command $($Arguments -join ' ')"
    }
}

function Install-Qt {
    $args = @(
        '--outputdir', $QtDir,
        'windows', 'desktop', $QtVersion, $QtArch,
        '--modules', 'qtmultimedia',
        '--archives', 'qtbase', 'qtdeclarative', 'qtsvg', 'qttools'
    )
    aqt install-qt @args
    if ($LASTEXITCODE -ne 0) {
        Write-Output 'Retrying Qt install via Berkeley mirror...'
        aqt install-qt -b https://mirrors.ocf.berkeley.edu/qt/ @args
        if ($LASTEXITCODE -ne 0) {
            throw "Qt install failed with exit code $LASTEXITCODE"
        }
    }
    aqt install-tool windows desktop --outputdir $QtDir tools_vcredist qt.tools.vcredist_msvc2022_x64
    aqt install-tool windows desktop --outputdir $QtDir tools_cmake qt.tools.cmake
    aqt install-tool windows desktop --outputdir $QtDir tools_ninja qt.tools.ninja
}

function Ensure-Qt {
    if (Test-Path $QtDir) {
        Write-Output 'Using cached Qt installation'
        return
    }
    python -m pip install --upgrade pip
    pip install "aqtinstall==$AqtinstallVersion"
    Install-Qt
}

function Get-RedirectedUrl {
    param([Parameter(Mandatory = $true)][string]$Url)
    $request = [System.Net.WebRequest]::Create($Url)
    $request.AllowAutoRedirect = $false
    $response = $request.GetResponse()
    if ($response.StatusCode -eq [System.Net.HttpStatusCode]::Found) {
        return $response.GetResponseHeader('Location')
    }
    return $Url
}

function Install-DependencyZip {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Destination
    )
    $destPath = Join-Path $WindowsPath $Destination
    if (Test-Path $destPath) { return }

    $uriToUse = $Uri
    if ($Uri -match 'downloads\.sourceforge\.net') {
        $uriToUse = Get-RedirectedUrl -Url $Uri
    }

    $tempZip = [System.IO.Path]::GetTempFileName() + '.zip'
    $tempDir = [System.IO.Path]::GetTempPath()
    Invoke-WebRequest -Uri $uriToUse -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
    Move-Item -Path (Join-Path $tempDir $Name) -Destination $destPath -Force
    Remove-Item $tempZip -Force
}

function Import-VcVars {
    param([Parameter(Mandatory = $true)][string]$VcVarsBin)
    $envDump = [System.IO.Path]::GetTempFileName()
    Invoke-NativeCommand -Command 'cmd' -Arguments @('/c', "`"$VcVarsBin`" && set > `"$envDump`"")
    Get-Content $envDump | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            Set-Item -Path "Env:$($Matches[1])" -Value $Matches[2]
        }
    }
    Remove-Item $envDump -Force
}

function Initialize-BuildEnvironment {
    $qtInstallPath = Join-Path $QtDir $QtVersion
    $qtBinPath = Join-Path $qtInstallPath "$QtCompileSubdir\bin"

    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Scope CurrentUser -Force
    }
    if (-not (Get-Module -ListAvailable -Name VSSetup)) {
        Install-Module -Name VSSetup -Scope CurrentUser -Force
    }
    Import-Module VSSetup

    $vsInstallPath = (Get-VSSetupInstance |
        Select-VSSetupInstance -Product '*' -Version '17.0' -Latest |
        Select-Object -ExpandProperty InstallationPath)
    if (-not $vsInstallPath) {
        throw 'Visual Studio 2022 Build Tools not found'
    }

    $vcVarsBin = Join-Path $vsInstallPath 'VC\Auxiliary\Build\vcvars64.bat'
    if (-not (Test-Path $vcVarsBin)) {
        throw "vcvars64.bat not found at $vcVarsBin"
    }
    Import-VcVars -VcVarsBin $vcVarsBin

    $cmakePath = Join-Path $QtDir 'Tools\CMake_64\bin\cmake.exe'
    $qmakePath = Join-Path $qtBinPath 'qmake.exe'
    $windeployPath = Join-Path $qtBinPath 'windeployqt.exe'
    foreach ($tool in @($cmakePath, $qmakePath, $windeployPath)) {
        if (-not (Test-Path $tool)) {
            throw "Required Qt tool not found: $tool"
        }
    }

    $env:QtCmakePath = $cmakePath
    $env:QtQmakePath = $qmakePath
    $env:QtWinDeployPath = $windeployPath
    return $qtInstallPath
}

function Copy-VcRuntime {
    param([Parameter(Mandatory = $true)][string]$Destination)
    $redistRoot = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2022\Enterprise\VC\Redist\MSVC'
    if (-not (Test-Path $redistRoot)) {
        $redistRoot = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\2022\BuildTools\VC\Redist\MSVC'
    }
    if (-not (Test-Path $redistRoot)) {
        Write-Output 'Skipping VC runtime copy; redist folder not found'
        return
    }
    $crtDir = Get-ChildItem -Path $redistRoot -Directory |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\Microsoft.VC143.CRT' } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1
    if ($crtDir) {
        Copy-Item -Path (Join-Path $crtDir '*') -Destination $Destination
    }
}

function Build-App {
    param([Parameter(Mandatory = $true)][string]$QtInstallPath)

    $buildArch = 'x86_64'
    $buildConfig = 'release'
    $archDeploy = Join-Path $DeployPath $buildArch
    $flexasioBuild = Join-Path $BuildPath "$buildConfig\flexasio"
    $kdasioconfigBuild = Join-Path $BuildPath "$buildConfig\kdasioconfig"

    Invoke-NativeCommand -Command $env:QtCmakePath -Arguments @(
        "-DCMAKE_PREFIX_PATH=$QtInstallPath\$QtCompileSubdir\lib\cmake",
        '-DCMAKE_BUILD_TYPE=Release',
        '-S', (Join-Path $RepoRoot 'src\kdasioconfig'),
        '-B', $kdasioconfigBuild,
        '-G', 'NMake Makefiles'
    )
    Push-Location $kdasioconfigBuild
    Invoke-NativeCommand -Command 'nmake'
    Pop-Location

    Invoke-NativeCommand -Command $env:QtCmakePath -Arguments @(
        '-S', (Join-Path $RepoRoot 'src'),
        '-B', $flexasioBuild,
        '-G', 'Ninja',
        '-DCMAKE_BUILD_TYPE=Release'
    )
    Invoke-NativeCommand -Command $env:QtCmakePath -Arguments @('--build', $flexasioBuild)

    Push-Location $flexasioBuild
    Invoke-NativeCommand -Command $env:QtWinDeployPath -Arguments @(
        "--$buildConfig",
        '--no-compiler-runtime',
        "--dir=$archDeploy",
        '--no-system-d3d-compiler',
        '--no-opengl-sw',
        (Join-Path $kdasioconfigBuild 'KoordASIOControl.exe')
    )
    Pop-Location

    Copy-VcRuntime -Destination $archDeploy

    $installBin = Join-Path $flexasioBuild 'install\bin'
    Move-Item -Path (Join-Path $kdasioconfigBuild 'KoordASIOControl.exe') -Destination $archDeploy -Force
    foreach ($file in @('KoordASIO.dll', 'portaudio.dll', 'ASIOTest.dll', 'sndfile.dll', 'FlexASIOTest.exe', 'PortAudioDevices.exe')) {
        Move-Item -Path (Join-Path $installBin $file) -Destination $archDeploy -Force
    }
}

function Build-Installer {
    param([Parameter(Mandatory = $true)][string]$Version)
    $issSource = Join-Path $WindowsPath 'kdinstaller.iss'
    $issTarget = Join-Path $RepoRoot 'kdinstaller.iss'
    Copy-Item -Path $issSource -Destination $issTarget -Force
    Invoke-NativeCommand -Command 'ISCC.exe' -Arguments @(
        $issTarget,
        "/F$AppName-$Version",
        "/DApplicationVersion=$Version"
    )
}

function Sign-Installer {
    param([Parameter(Mandatory = $true)][string]$Version)
    if (-not $env:WINDOWS_CODESIGN_CERT) {
        Write-Output 'WINDOWS_CODESIGN_CERT not set; skipping code signing'
        return
    }
    if (-not $env:WINDOWS_CODESIGN_PWD) {
        throw 'WINDOWS_CODESIGN_PWD must be set when WINDOWS_CODESIGN_CERT is provided'
    }

    [IO.File]::WriteAllBytes('C:\KoordOVCert.pfx', [Convert]::FromBase64String($env:WINDOWS_CODESIGN_CERT))
    Set-Content -Path 'C:\KoordOVCertPwd' -Value $env:WINDOWS_CODESIGN_PWD -NoNewline

    $signtool = Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin') -Recurse -Filter 'signtool.exe' |
        Where-Object { $_.FullName -match '\\x64\\' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1
    if (-not $signtool) {
        throw 'signtool.exe not found in Windows Kits'
    }

    $installer = Join-Path $RepoRoot "Output\$AppName-$Version.exe"
    Invoke-NativeCommand -Command $signtool.FullName -Arguments @(
        'sign', '/f', 'C:\KoordOVCert.pfx',
        '/p', (Get-Content 'C:\KoordOVCertPwd' -Raw),
        '/fd', 'SHA256', '/td', 'SHA256',
        '/tr', 'http://timestamp.sectigo.com',
        $installer
    )
}

function Publish-Artifact {
    $version = Get-BuildVersion
    $artifactName = "${AppName}_${version}.exe"
    $artifactPath = Join-Path $RepoRoot "deploy\$artifactName"
    $installerPath = Join-Path $RepoRoot "Output\$AppName-$version.exe"

    New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot 'deploy') | Out-Null
    Move-Item -Path $installerPath -Destination $artifactPath -Force
    Write-Output "artifact_1=$artifactName"
    if ($env:GITHUB_OUTPUT) {
        Add-Content -Path $env:GITHUB_OUTPUT -Value "artifact_1=$artifactName"
    }
}

switch ($Stage) {
    'setup' {
        choco config set cacheLocation $ChocoCacheDir
        choco install --no-progress -y jom --version $JomVersion
        choco install --no-progress -y innosetup
        Ensure-Qt
    }
    'build' {
        $version = Get-BuildVersion
        Push-Location $RepoRoot
        try {
            if (Test-Path $BuildPath) { Remove-Item $BuildPath -Recurse -Force }
            if (Test-Path $DeployPath) { Remove-Item $DeployPath -Recurse -Force }
            if (Test-Path (Join-Path $RepoRoot 'Output')) { Remove-Item (Join-Path $RepoRoot 'Output') -Recurse -Force }
            New-Item -ItemType Directory -Force -Path $BuildPath, $DeployPath | Out-Null

            Install-DependencyZip -Uri $AsioSdkUrl -Name $AsioSdkName -Destination 'ASIOSDK2'
            $qtInstallPath = Initialize-BuildEnvironment
            Build-App -QtInstallPath $qtInstallPath
            Build-Installer -Version $version
            Sign-Installer -Version $version
        } finally {
            Pop-Location
        }
    }
    'get-artifacts' {
        Push-Location $RepoRoot
        try {
            Publish-Artifact
        } finally {
            Pop-Location
        }
    }
    default {
        throw "Unknown stage: $Stage"
    }
}
