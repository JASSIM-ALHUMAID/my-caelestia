#!/usr/bin/env bash

set -o pipefail

if [[ $# -ne 1 || ! -f "$1" ]]; then
    echo "usage: $0 /path/to/video"
    exit 2
fi

SCREENSAVER_TEST_VIDEO="$1" timeout 15 qs -p ScreensaverVideoCheck.qml --no-color 2>&1 | awk '
    { print }
    /SCREENSAVER_VIDEO_CHECK: PASS/ { passed = 1 }
    END { exit passed ? 0 : 1 }
'
