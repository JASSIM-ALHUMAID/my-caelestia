#!/usr/bin/env bash

set -o pipefail

qs -p MatrixVisualCheck.qml --no-color 2>&1 | awk '
    { print }
    /MATRIX_VISUAL_CHECK: PASS/ { passed = 1 }
    END { exit passed ? 0 : 1 }
'
