#!/usr/bin/env bash

set -o pipefail

timeout 25 qs -p ScreensaverEffectsCheck.qml --no-color 2>&1 | awk '
    { print }
    /SCREENSAVER_EFFECT: PASS/ { passed++ }
    /SCREENSAVER_EFFECTS_CHECK: PASS total=9/ { complete = 1 }
    END { exit complete && passed == 9 ? 0 : 1 }
'
