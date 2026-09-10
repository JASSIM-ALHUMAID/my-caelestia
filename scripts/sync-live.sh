#!/usr/bin/env bash
set -euo pipefail

# Sync the repo's QML into the live shell and restart it.
# The C++ plugin is NOT built or installed here — use scripts/install.sh for that.
# Usage: ./scripts/sync-live.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LIVE_DIR="$HOME/.config/quickshell/caelestia"

cd "$REPO_ROOT"

if [ -n "$(git status --porcelain -- plugin CMakeLists.txt)" ]; then
    echo "WARNING: plugin/ or CMakeLists.txt has pending changes."
    echo "         The C++ plugin is NOT updated by this script; run scripts/install.sh --skip-sddm to rebuild and install it."
fi

echo "Syncing QML to $LIVE_DIR ..."
# same dir set as the cmake install; config/ is runtime-generated, leave it alone
for d in assets components modules services utils; do
    rsync -a --delete "$REPO_ROOT/$d/" "$LIVE_DIR/$d/"
done
# the installed copy must not watch files (matches cmake install rewrite)
sed 's/settings.watchFiles: true/settings.watchFiles: false/' "$REPO_ROOT/shell.qml" > "$LIVE_DIR/shell.qml"
rsync -a "$REPO_ROOT/LICENSE" "$LIVE_DIR/"
mkdir -p "$LIVE_DIR/scripts"
rsync -a "$REPO_ROOT/scripts/sync-live.sh" "$LIVE_DIR/scripts/"
echo "Live shell synced."

echo "Restarting shell ..."
# Target only the Caelestia instance, including one launched on another display.
qs -c caelestia kill --any-display 2>/dev/null || true
sleep 1
# QML2_IMPORT_PATH must point at this repo's installed plugin: the packaged
# Caelestia module in /usr/lib is older and misses types like LogindManager,
# so the shell dies with "Failed to load configuration". Hyprland only applies
# its own `env` at startup, so a session started before that never has it.
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    QT_QPA_PLATFORM=wayland qs -c caelestia -n -d >/dev/null 2>&1 &
    disown
else
    # Detached agents and TTYs do not inherit the graphical environment. Let
    # Hyprland launch the shell instead of allowing Qt to fall back to XCB.
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hypr_dir="$(ls -1dt "${XDG_RUNTIME_DIR:?}/hypr/"*/ 2>/dev/null | head -n1 || true)"
        [[ -n "$hypr_dir" ]] && export HYPRLAND_INSTANCE_SIGNATURE="$(basename "$hypr_dir")"
    fi

    if ! command -v hyprctl >/dev/null || [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        echo "ERROR: no Wayland display or reachable Hyprland instance; shell was not restarted." >&2
        exit 1
    fi

    launch_command="env QT_QPA_PLATFORM=wayland QML2_IMPORT_PATH=$(printf '%q' "$QML2_IMPORT_PATH") qs -c caelestia -n -d"
    launch_command="${launch_command//\\/\\\\}"
    launch_command="${launch_command//\"/\\\"}"
    hyprctl dispatch "hl.dsp.exec_cmd(\"$launch_command\")" >/dev/null
fi
hyprctl reload
echo "Shell restarted."
