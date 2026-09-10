#!/usr/bin/env fish
# Launch the worktree shell with the freshly-built Caelestia plugin (the one that has bar.edge)
cd (dirname (status filename))
pkill -x qs 2>/dev/null; sleep 0.6
set -x QML2_IMPORT_PATH "$PWD/build/qml:$QML2_IMPORT_PATH"
exec qs -p .
