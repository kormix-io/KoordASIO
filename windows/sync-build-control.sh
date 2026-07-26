#!/bin/bash
# Mirror the control-app source to the Windows box and build it there, so UI
# changes can be tried without spending a CI run.
#
#   windows/sync-build-control.sh                  # sync + build + deploy
#   windows/sync-build-control.sh --run            # ...and launch it
#   windows/sync-build-control.sh --shot out.png   # ...and fetch a screenshot
#
# Only the control app is built. The ASIO driver itself comes from the installer,
# so a real CI build is still what gets released.

set -euo pipefail

HOST="${KOORDASIO_WIN_HOST:-kormix-win}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RUN=""
SHOT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --run)  RUN="-Run"; shift ;;
        --shot) SHOT="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
done

TAR=$(mktemp -t koordasio-src)
trap 'rm -f "$TAR"' EXIT
# The control app, the root CMakeLists it reads the version from, and the builder.
# COPYFILE_DISABLE keeps macOS from adding ._* resource-fork stubs, which
# qmlimportscanner then tries to parse as QML.
COPYFILE_DISABLE=1 tar -czf "$TAR" -C "$ROOT" CMakeLists.txt src/kdasioconfig windows/dev-build-control.ps1

echo "==> mirroring source to $HOST"
ssh "$HOST" 'New-Item -ItemType Directory -Force -Path C:\koordasio-dev\src | Out-Null' >/dev/null
scp -q "$TAR" "$HOST:C:/koordasio-dev/src.tgz"
# Wipe the mirrored trees first so deletions propagate instead of leaving stale files.
ssh "$HOST" 'Remove-Item -Recurse -Force C:\koordasio-dev\src\src, C:\koordasio-dev\src\windows -ErrorAction SilentlyContinue; tar -xzf C:\koordasio-dev\src.tgz -C C:\koordasio-dev\src' >/dev/null

echo "==> building on $HOST"
ssh "$HOST" "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\koordasio-dev\\src\\windows\\dev-build-control.ps1 $RUN"

if [ -n "$SHOT" ]; then
    echo "==> screenshot"
    # Start-Process -Wait, not &: it is a GUI subsystem exe, so PowerShell would
    # otherwise return before the screenshot had been written.
    ssh "$HOST" 'Get-Process KoordASIOControl -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Milliseconds 500; Start-Process "C:\Program Files\KoordASIO\KoordASIOControl.exe" -ArgumentList "-screenshot=C:\koordasio-dev\shot.png" -Wait' >/dev/null
    scp -q "$HOST:C:/koordasio-dev/shot.png" "$SHOT"
    echo "saved $SHOT"
fi

echo done
