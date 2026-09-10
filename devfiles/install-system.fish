#!/usr/bin/env fish
# Install the Caelestia shell system-wide — requires sudo.
#
# Layout (matches the caelestia-shell package):
#   QML config -> /etc/xdg/quickshell/caelestia
#   C++ plugin -> /usr/lib/qt6/qml/Caelestia   (Qt's default path; no env var needed)
#   beat lib   -> /usr/lib/caelestia
#
# Uses a separate build dir (build-system) so it never clobbers the user build in build/.
#
# NOTE: this writes into files owned by the pacman `caelestia-shell` package. pacman will
# see them as modified and a future package upgrade will overwrite this install. For a
# pacman-tracked system install, build the PKGBUILD with `makepkg -si` instead.

set -l script_dir (realpath (dirname (status filename)))
set -l repo (realpath "$script_dir/..")
set -l build "$repo/build-system"

source "$script_dir/lib-config-link.fish"
set -l cael_conf "$HOME/.config/caelestia"
set -l relink 1
cael_link_wanted $argv; or set relink 0

echo ":: Configuring (system prefix=/) ..."
cmake -B "$build" -S "$repo" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/; or exit 1

echo ":: Building ..."
cmake --build "$build"; or exit 1

# If ~/.config/caelestia is a symlink (into this tree or any other), temporarily
# break it so the shell can't auto-save config into a source tree on restart.
set -l detached 1
cael_link_detach "$cael_conf"; or set detached 0

echo ":: Installing system-wide (sudo) ..."
sudo cmake --install "$build"; or exit 1

# Repoint ~/.config/caelestia at THIS tree. install-system.fish has no restart
# block, but the link should still be correct the next time the shell (re)starts.
cael_link_apply "$repo" "$cael_conf" $relink $detached

# Warn if user-local overrides will shadow this system install.
set -l shadowed
test -d "$HOME/.config/quickshell/caelestia"; and set -a shadowed "~/.config/quickshell/caelestia (QML overrides /etc/xdg)"
test -d "$HOME/.local/lib/qt6/qml/Caelestia"; and set -a shadowed "~/.local/lib/qt6/qml/Caelestia (plugin, if QML2_IMPORT_PATH is set)"
grep -rqsF "QML2_IMPORT_PATH" "$HOME/.config/uwsm/env" 2>/dev/null
and set -a shadowed "QML2_IMPORT_PATH in uwsm env (points qs back at ~/.local)"

if set -q shadowed[1]
    echo ""
    echo ":: WARNING — user-local overrides still exist and will hide the system install:"
    for s in $shadowed
        echo "     - $s"
    end
    echo "   Remove them (and re-login) to actually use the system version:"
    echo "     rm -rf ~/.config/quickshell/caelestia ~/.local/lib/qt6/qml/Caelestia ~/.local/lib/caelestia"
    echo "     and delete the Caelestia env lines from ~/.config/uwsm/env"
    echo ""
end

echo ":: Restarting shell (without user env, to use the system build) ..."
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
    # Normal terminal: inherit the session env directly (system build, no user paths).
    env -u QML2_IMPORT_PATH -u CAELESTIA_LIB_DIR QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none \
        caelestia shell -d >/dev/null 2>&1 &
else if type -q hyprctl; and set -q HYPRLAND_INSTANCE_SIGNATURE
    # Env-less shell (e.g. herdr): hand the launch to Hyprland so the shell inherits
    # the full graphical env — otherwise Hyprland-dependent widgets like the bar's
    # workspaces stay dead. System build, so unset the user import paths.
    echo "   - no session env detected; launching through Hyprland"
    hyprctl dispatch 'hl.dsp.exec_cmd("env -u QML2_IMPORT_PATH -u CAELESTIA_LIB_DIR QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none caelestia shell -d")'
else
    echo "   - WARNING: no session env and hyprctl unavailable; shell may not work correctly"
    env -u QML2_IMPORT_PATH -u CAELESTIA_LIB_DIR QT_FFMPEG_DECODING_HW_DEVICE_TYPES=none \
        caelestia shell -d >/dev/null 2>&1 &
end

echo ":: Done."
