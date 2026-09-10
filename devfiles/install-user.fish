#!/usr/bin/env fish
# Install the Caelestia shell for the current user only — no root required.
#
# Layout:
#   QML config -> ~/.config/quickshell/caelestia
#   C++ plugin -> ~/.local/lib/qt6/qml/Caelestia
#   beat lib   -> ~/.local/lib/caelestia
#
# Because ~/.local/lib/qt6/qml is NOT on Qt's default import path, this script also
# makes the session export QML2_IMPORT_PATH + CAELESTIA_LIB_DIR (Hyprland env + uwsm
# env) so `qs -c caelestia` loads this user plugin instead of the system one.
#
# Re-runnable: rebuilds, reinstalls, and only appends env lines if missing.

set -l script_dir (realpath (dirname (status filename)))
set -l repo (realpath "$script_dir/..")
set -l build "$repo/build"

source "$script_dir/lib-config-link.fish"
set -l cael_conf "$HOME/.config/caelestia"
set -l relink 1
cael_link_wanted $argv; or set relink 0

set -l qmldir "$HOME/.local/lib/qt6/qml"
set -l qsconfdir "$HOME/.config/quickshell/caelestia"
set -l libdir "$HOME/.local/lib/caelestia"

# --- idempotent "append block once" helper -------------------------------------
# usage: ensure_block <file> <marker> <content...>
function ensure_block --argument-names file marker
    set -l content $argv[3..-1]
    if test -f "$file"; and grep -qF -- "$marker" "$file"
        echo "   - env already present in $file (skipped)"
        return 0
    end
    mkdir -p (dirname "$file")
    printf '\n%s\n' $content >> "$file"
    echo "   - appended env block to $file"
end

echo ":: Configuring (user prefix ~/.local) ..."
cmake -B "$build" -S "$repo" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
    -DINSTALL_QMLDIR="$qmldir" \
    -DINSTALL_QSCONFDIR="$qsconfdir" \
    -DINSTALL_LIBDIR="$libdir"; or exit 1

echo ":: Building ..."
cmake --build "$build"; or exit 1

# If ~/.config/caelestia is a symlink (into this tree or any other), temporarily
# break it so the shell can't auto-save config into a source tree on restart.
set -l detached 1
cael_link_detach "$cael_conf"; or set detached 0

# Wipe the plugin dirs first. cmake --install only overwrites the files it knows
# about, so a stale .so from an older build survives inside a module dir — and
# there it beats the fresh one in ../lib for the plugin's $ORIGIN rpath, silently
# loading outdated types ("ButtonRow is not a type"). These dirs are pure build
# output, so deleting them is safe. $qsconfdir is NOT wiped: config/ inside it is
# runtime state (same reasoning as scripts/sync-live.sh).
echo ":: Clearing previous plugin install ..."
rm -rf "$qmldir/Caelestia" "$qmldir/M3Shapes" "$libdir"

echo ":: Installing to user dirs ..."
cmake --install "$build"; or exit 1

# Repoint ~/.config/caelestia at THIS tree, before the shell restarts below —
# otherwise the relaunched shell would come back up reading whatever tree was
# live before, defeating the point of running this installer from here.
cael_link_apply "$repo" "$cael_conf" $relink $detached

# uwsm/env is the only writer here: the Hyprland config is Lua now, and hypr-user.conf was
# never sourced by it, so the `env =` block this used to write was inert.
echo ":: Ensuring session env (so qs finds the user plugin) ..."
set -l uwsm_env "$HOME/.config/uwsm/env"
ensure_block "$uwsm_env" 'QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml' \
    "# ###### Caelestia shell (devfiles/install-user.fish) ######" \
    'export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"' \
    'export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"'

echo ":: Restarting shell ..."
# Were we started inside a proper graphical session? (A normal wezterm tab has these;
# a TTY or a detached shell server like herdr does not.)
set -l had_graphical_env 0
set -q HYPRLAND_INSTANCE_SIGNATURE; and set -q WAYLAND_DISPLAY; and set had_graphical_env 1

# qs -c caelestia kill is display-scoped: with no WAYLAND_DISPLAY it matches nothing
# and the old shell survives. Discover the socket so the kill works from any context.
if not set -q WAYLAND_DISPLAY
    for s in $XDG_RUNTIME_DIR/wayland-*
        test -S "$s"; and set -gx WAYLAND_DISPLAY (basename "$s"); and break
    end
end
# hyprctl needs the instance signature; discover it when unset.
if not set -q HYPRLAND_INSTANCE_SIGNATURE
    for d in (command ls -1dt $XDG_RUNTIME_DIR/hypr/*/ 2>/dev/null)
        set -gx HYPRLAND_INSTANCE_SIGNATURE (basename "$d"); and break
    end
end

qs -c caelestia kill 2>/dev/null
sleep 0.5

if test "$had_graphical_env" = 1
    # Normal terminal: inherit the session env directly.
    QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none QML2_IMPORT_PATH="$qmldir:$QML2_IMPORT_PATH" CAELESTIA_LIB_DIR="$libdir" \
        caelestia shell -d >/dev/null 2>&1 &
else if type -q hyprctl; and set -q HYPRLAND_INSTANCE_SIGNATURE
    # Env-less shell (e.g. herdr): hand the launch to Hyprland so the shell inherits
    # the full graphical env (WAYLAND_DISPLAY, HYPRLAND_INSTANCE_SIGNATURE,
    # XDG_CURRENT_DESKTOP, portals, env-keywords) — otherwise Hyprland-dependent
    # widgets like the bar's workspaces stay dead. Pass build vars explicitly (a fresh
    # install predates the Hyprland env reload) and force software AV1 decode.
    echo "   - no session env detected; launching through Hyprland"
    hyprctl dispatch "hl.dsp.exec_cmd(\"env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none QML2_IMPORT_PATH=$qmldir:$QML2_IMPORT_PATH CAELESTIA_LIB_DIR=$libdir caelestia shell -d\")"
else
    echo "   - WARNING: no session env and hyprctl unavailable; shell may not work correctly"
    QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none QML2_IMPORT_PATH="$qmldir:$QML2_IMPORT_PATH" CAELESTIA_LIB_DIR="$libdir" \
        caelestia shell -d >/dev/null 2>&1 &
end

echo ":: Done."
echo "   The shell is running now with the user build."
echo "   Log out/in once to make the env permanent for every launch."
