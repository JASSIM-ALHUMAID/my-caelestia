#!/bin/sh
# Compile shell shaders to .qsb.
#
# The shell QML runs uncompiled (no qrc), so the .qsb files are committed
# alongside their .frag sources. Whenever a shader changes, rerun this script
# and commit the regenerated .qsb with it.
#
# qsb ships with qt6-shadertools; it is typically not on PATH.
set -eu

cd "$(dirname "$0")/.."

QSB=${QSB:-/usr/lib/qt6/bin/qsb}

for f in modules/background/shaders/*.frag modules/screensaver/effects/shaders/*.frag; do
    if [ ! -f "$f" ]; then
        continue
    fi
    "$QSB" --glsl "300es,330" --hlsl 50 --msl 12 -O -o "$f.qsb" "$f"
    echo "compiled $f.qsb"
done
