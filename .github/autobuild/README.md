# KoordASIO autobuild

Unified Windows build scripts for CI and local development.

## CI

GitHub Actions workflow: `.github/workflows/autobuild.yml`

Stages are implemented in `build.ps1`:

- `setup` — Qt 6.8.2 (MSVC 2022), JOM, Inno Setup
- `build` — compile driver + control app, create installer, optional signing
- `get-artifacts` — rename installer for upload

Version and release metadata: `version.ps1`

## Local build

```powershell
$env:koordasio_buildversionstring = '2.2.0'
.\.github\autobuild\build.ps1 setup
.\.github\autobuild\build.ps1 build
```

Installer output: `Output\KoordASIO-<version>.exe`

Signing is skipped unless `WINDOWS_CODESIGN_CERT` and `WINDOWS_CODESIGN_PWD` are set.

## Release tags

Push a tag like `r2_2_0` (must match `kdASIOVersion.txt`) to publish a draft GitHub release.
