#!/usr/bin/env fish
# Caelestia unified uninstaller — interactive.
#
# Removes any subset of:
#   1) Shell           — the user-local worktree install (reverses install-user-untagged.fish)
#   2) SDDM theme      — delegates to sddm/scripts/uninstall.sh
#   3) GRUB theme      — delegates to grub/scripts/uninstall.sh
#
# Do NOT run this script with sudo. Each sub-step escalates internally only when needed.
#
# Shell removal covers:
#   - the C++ plugin from ~/.local/lib/qt6/qml/Caelestia/
#   - the QML config from ~/.config/quickshell/caelestia/
#   - the beat lib from ~/.local/lib/caelestia/
#   - the config symlink ~/.config/caelestia (if it points to this worktree)
#   - env blocks from hyprland/env.conf and uwsm/env
#   - kills the running shell
#
# Does NOT touch:
#   - the system caelestia-cli package (/usr/bin/caelestia)
#   - the worktree repo itself (cloned source)
#   - any .bak-* backups that install.fish may have created

set -l script_dir (realpath (dirname (status filename)))
set -l repo "$script_dir"

# --- guards -----------------------------------------------------------------

if test (id -u) -eq 0
    echo "✗ Do not run this script with sudo. Run it normally — sudo is requested only by the steps that need it." >&2
    exit 1
end

# --- banner + main menu -----------------------------------------------------

echo ""
echo "============================================================"
echo "              Caelestia unified uninstaller"
echo "============================================================"
echo ""
echo "  What do you want to uninstall?"
echo "    1) Shell             (user-local worktree install)"
echo "    2) SDDM theme        (sddm/scripts/uninstall.sh, requires sudo)"
echo "    3) GRUB theme        (grub/scripts/uninstall.sh, requires sudo)"
echo ""
read -P "Select items (e.g. '1,2,3' or 'all', 'q' to quit): " choice

if test "$choice" = q -o "$choice" = Q
    echo "Aborted."
    exit 0
end

set -l want_shell 0
set -l want_sddm 0
set -l want_grub 0

if test "$choice" = all -o "$choice" = ALL
    set want_shell 1
    set want_sddm 1
    set want_grub 1
else
    for item in (string split , -- $choice)
        set -l n (string trim $item)
        switch $n
            case 1
                set want_shell 1
            case 2
                set want_sddm 1
            case 3
                set want_grub 1
            case ''
                # ignore stray commas
            case '*'
                echo "✗ Invalid selection: '$n'" >&2
                exit 1
        end
    end
end

if test $want_shell -eq 0 -a $want_sddm -eq 0 -a $want_grub -eq 0
    echo "Nothing selected. Aborted."
    exit 0
end

# --- confirm ----------------------------------------------------------------

echo ""
echo "About to remove:"
if test $want_shell -eq 1
    echo "  • Shell (user-local worktree install from $repo):"
    echo "      - C++ plugin     ~/.local/lib/qt6/qml/Caelestia/"
    echo "      - QML config     ~/.config/quickshell/caelestia/"
    echo "      - Beat lib       ~/.local/lib/caelestia/"
    echo "      - Config symlink ~/.config/caelestia (if pointing here)"
    echo "      - Env entries    hyprland/env.conf + uwsm/env"
    echo "      - Build dir      $repo/build/"
end
test $want_sddm -eq 1; and echo "  • SDDM theme (sudo)"
test $want_grub -eq 1; and echo "  • GRUB theme (sudo)"
echo ""
read -P "Proceed? [y/N]: " confirm
if not string match -qir '^y' -- "$confirm"
    echo "Aborted."
    exit 0
end

# --- run: shell → SDDM → GRUB ------------------------------------------------

if test $want_shell -eq 1

    # --- kill -----------------------------------------------------------------

    echo ""
    echo ":: Killing running Caelestia shell ..."
    qs -c caelestia kill 2>/dev/null
    sleep 0.5
    pkill -x qs 2>/dev/null
    echo "   ✓ Done"

    # --- C++ plugin -------------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                     REMOVING C++ PLUGIN"
    echo "============================================================"

    set -l plugin "$HOME/.local/lib/qt6/qml/Caelestia"
    if test -d "$plugin"
        rm -rf "$plugin"
        echo "   ✓ Removed $plugin"
    else
        echo "   - Not found (skipped)"
    end

    # --- QML config -------------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                     REMOVING QML CONFIG"
    echo "============================================================"

    set -l qsconf "$HOME/.config/quickshell/caelestia"
    if test -d "$qsconf"
        rm -rf "$qsconf"
        echo "   ✓ Removed $qsconf"
    else
        echo "   - Not found (skipped)"
    end

    # --- Beat lib ---------------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                      REMOVING BEAT LIB"
    echo "============================================================"

    set -l libdir "$HOME/.local/lib/caelestia"
    if test -d "$libdir"
        rm -rf "$libdir"
        echo "   ✓ Removed $libdir"
    else
        echo "   - Not found (skipped)"
    end

    # --- Config symlink ---------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                    REMOVING CONFIG SYMLINK"
    echo "============================================================"

    set -l target "$HOME/.config/caelestia"
    set -l src_real (realpath -- "$repo/caelestia-configs" 2>/dev/null)
    if test -L "$target"
        set -l link_target (realpath -- "$target" 2>/dev/null)
        if test "$link_target" = "$src_real"
            rm "$target"
            echo "   ✓ Removed symlink $target → $link_target"
        else
            echo "   - $target is a symlink, but points elsewhere (not this worktree) — skipped"
            echo "     Points to: $link_target"
        end
    else if test -e "$target"
        echo "   - $target is a real directory (not a symlink) — skipped"
    else
        echo "   - Not found (skipped)"
    end

    # --- Env entries ------------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                    REMOVING ENV ENTRIES"
    echo "============================================================"

    set -l hypr_env "$HOME/.config/hypr/hyprland/env.conf"
    if test -f "$hypr_env"
        if grep -q "Caelestia shell" "$hypr_env" 2>/dev/null
            sed -i '/####### Caelestia shell/,/CAELESTIA_LIB_DIR/d' "$hypr_env"
            echo "   ✓ Removed Caelestia block from $hypr_env"
        else
            echo "   - No Caelestia block found in $hypr_env (skipped)"
        end
    else
        echo "   - $hypr_env not found (skipped)"
    end

    set -l uwsm_env "$HOME/.config/uwsm/env"
    if test -f "$uwsm_env"
        if grep -q "Caelestia shell" "$uwsm_env" 2>/dev/null
            sed -i '/####### Caelestia shell/,/CAELESTIA_LIB_DIR/d' "$uwsm_env"
            echo "   ✓ Removed Caelestia block from $uwsm_env"
        else
            echo "   - No Caelestia block found in $uwsm_env (skipped)"
        end
    else
        echo "   - $uwsm_env not found (skipped)"
    end

    # --- Build dir --------------------------------------------------------------

    echo ""
    echo "============================================================"
    echo "                     REMOVING BUILD DIR"
    echo "============================================================"

    set -l build "$repo/build"
    if test -d "$build"
        rm -rf "$build"
        echo "   ✓ Removed $build"
    else
        echo "   - Not found (skipped)"
    end
end

if test $want_sddm -eq 1
    echo ""
    echo "============================================================"
    echo "                      REMOVING SDDM THEME"
    echo "============================================================"
    bash "$repo/sddm/scripts/uninstall.sh"; or exit 1
end

if test $want_grub -eq 1
    echo ""
    echo "============================================================"
    echo "                      REMOVING GRUB THEME"
    echo "============================================================"
    bash "$repo/grub/scripts/uninstall.sh"; or exit 1
end

# --- done -------------------------------------------------------------------

echo ""
echo "============================================================"
echo "                       UNINSTALL DONE"
echo "============================================================"
test $want_shell -eq 1; and echo "  ✓ Shell removed"
test $want_sddm -eq 1; and echo "  ✓ SDDM theme removed"
test $want_grub -eq 1; and echo "  ✓ GRUB theme removed"
echo ""
if test $want_shell -eq 1
    echo "The next time you log in, the system Caelestia (if installed)"
    echo "will be used instead of the worktree build."
    echo ""
    echo "If you had backup configs from a previous install (caelestia.bak-*),"
    echo "you can restore them manually:"
    echo "    mv ~/.config/caelestia.bak-<timestamp> ~/.config/caelestia"
    echo ""
end
