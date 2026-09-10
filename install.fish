#!/usr/bin/env fish
# Caelestia unified installer — interactive.
#
# Installs any subset of:
#   1) Shell           — delegates to devfiles/install-user.fish or install-system.fish
#   2) Caelestia user configs — symlinks ~/.config/caelestia → repo/caelestia-configs
#   3) SDDM theme      — delegates to sddm/scripts/install.sh
#   4) GRUB theme      — delegates to grub/scripts/install.sh
#
# Do NOT run this script with sudo. Each sub-step escalates internally only when needed,
# so files installed into your home stay owned by you.

set -l script_dir (realpath (dirname (status filename)))
set -l repo "$script_dir"

# --- guards -----------------------------------------------------------------

if test (id -u) -eq 0
    echo "✗ Do not run this script with sudo. Run it normally — sudo is requested only by the steps that need it." >&2
    exit 1
end

if not command -v pacman >/dev/null
    echo "✗ This installer targets Arch Linux (pacman not found)." >&2
    echo "   For other distros, run the individual installers manually:" >&2
    echo "     - devfiles/install-user.fish   (shell, distro-agnostic build)" >&2
    echo "     - sddm/scripts/install.sh      (SDDM theme — uses pacman, Arch-only)" >&2
    echo "     - grub/scripts/install.sh      (GRUB theme — uses pacman, Arch-only)" >&2
    exit 1
end

# --- banner + main menu -----------------------------------------------------

echo ""
echo "============================================================"
echo "              Caelestia unified installer"
echo "============================================================"
echo ""
echo "  What do you want to install?"
echo "    1) Shell             (devfiles/install-user.fish)"
echo "    2) Caelestia configs (~/.config/caelestia → caelestia-configs/)"
echo "    3) SDDM theme        (sddm/scripts/install.sh, requires sudo)"
echo "    4) GRUB theme        (grub/scripts/install.sh, requires sudo)"
echo ""
read -P "Select items (e.g. '1,2,3,4' or 'all', 'q' to quit): " choice

if test "$choice" = q -o "$choice" = Q
    echo "Aborted."
    exit 0
end

set -l want_shell 0
set -l want_configs 0
set -l want_sddm 0
set -l want_grub 0

if test "$choice" = all -o "$choice" = ALL
    set want_shell 1
    set want_configs 1
    set want_sddm 1
    set want_grub 1
else
    for item in (string split , -- $choice)
        set -l n (string trim $item)
        switch $n
            case 1
                set want_shell 1
            case 2
                set want_configs 1
            case 3
                set want_sddm 1
            case 4
                set want_grub 1
            case ''
                # ignore stray commas
            case '*'
                echo "✗ Invalid selection: '$n'" >&2
                exit 1
        end
    end
end

if test $want_shell -eq 0 -a $want_configs -eq 0 -a $want_sddm -eq 0 -a $want_grub -eq 0
    echo "Nothing selected. Aborted."
    exit 0
end

# --- sub-prompts ------------------------------------------------------------

set -l shell_mode ""
if test $want_shell -eq 1
    echo ""
    echo "Shell install:"
    echo "  u) User install — no sudo, into ~/.local + ~/.config (default)"
    echo "  s) System install — uses sudo, into /usr + /etc/xdg"
    read -P "Choice [u]: " sh_choice
    test -z "$sh_choice"; and set sh_choice u
    switch $sh_choice
        case u U
            set shell_mode user
        case s S
            set shell_mode system
        case '*'
            echo "✗ Invalid choice: '$sh_choice'" >&2
            exit 1
    end
end

set -l configs_policy ""
set -l target "$HOME/.config/caelestia"
set -l src_real (realpath -- "$repo/caelestia-configs")
if test $want_configs -eq 1
    if test -L "$target"; and test (realpath -- "$target") = "$src_real"
        set configs_policy already_linked
    else if test -e "$target"
        echo ""
        echo "~/.config/caelestia already exists."
        echo "  s) Skip — leave it untouched"
        echo "  b) Backup, then symlink (default) — rename existing to .bak-<ts>, then symlink"
        echo "  m) Merge — copy existing files INTO repo first (overwrites repo's files), then symlink"
        read -P "Choice [b]: " cfg_choice
        test -z "$cfg_choice"; and set cfg_choice b
        switch $cfg_choice
            case s S
                set configs_policy skip
            case b B
                set configs_policy backup
            case m M
                set configs_policy merge
            case '*'
                echo "✗ Invalid choice: '$cfg_choice'" >&2
                exit 1
        end
    else
        set configs_policy fresh
    end
end

# --- confirm ----------------------------------------------------------------

echo ""
echo "About to:"
test $want_shell -eq 1; and echo "  • Install the shell ($shell_mode install)"
if test $want_configs -eq 1
    switch $configs_policy
        case already_linked
            echo "  • Configs: already symlinked correctly — nothing to do"
        case skip
            echo "  • Configs: skip (leave ~/.config/caelestia alone)"
        case fresh
            echo "  • Configs: symlink ~/.config/caelestia → caelestia-configs/"
        case backup
            echo "  • Configs: backup ~/.config/caelestia, then symlink it → caelestia-configs/"
        case merge
            echo "  • Configs: copy existing ~/.config/caelestia INTO caelestia-configs/ (overwrites), backup, then symlink"
    end
end
test $want_sddm -eq 1; and echo "  • Install the SDDM theme (sudo)"
test $want_grub -eq 1; and echo "  • Install the GRUB theme (sudo)"
echo ""
read -P "Proceed? [Y/n]: " confirm
test -z "$confirm"; and set confirm Y
if not string match -qir '^y' -- $confirm
    echo "Aborted."
    exit 0
end

# --- run: shell → configs → SDDM → GRUB -------------------------------------

if test $want_shell -eq 1
    echo ""
    echo "============================================================"
    echo "                       INSTALLING SHELL"
    echo "============================================================"
    if test "$shell_mode" = system
        fish "$repo/devfiles/install-system.fish"; or exit 1
    else
        # Auto-pick tagged vs untagged: if the repo has no reachable tag, the
        # tagged install fails inside cmake; fall back to the -DVERSION=0.0.0 variant.
        if git -C "$repo" describe --tags --abbrev=0 >/dev/null 2>&1
            fish "$repo/devfiles/install-user.fish"; or exit 1
        else
            echo ":: No git tag found — using install-user-untagged.fish"
            fish "$repo/devfiles/install-user-untagged.fish"; or exit 1
        end
    end
end

if test $want_configs -eq 1
    echo ""
    echo "============================================================"
    echo "                      INSTALLING CONFIGS"
    echo "============================================================"
    if not test -d "$repo/caelestia-configs"
        echo "✗ $repo/caelestia-configs does not exist (or is a broken symlink)." >&2
        echo "   The repo's caelestia-configs/ directory is the source of truth." >&2
        exit 1
    end
    set -l ts (date +%Y%m%d-%H%M%S)
    switch $configs_policy
        case already_linked
            echo "✓ $target already symlinked to $src_real (nothing to do)."
        case skip
            echo "✓ Skipped configs (user choice)."
        case fresh
            mkdir -p (dirname "$target")
            ln -s "$src_real" "$target"
            echo "✓ Symlinked $target → $src_real"
        case backup
            set -l backup "$target.bak-$ts"
            mv "$target" "$backup"
            echo "✓ Moved $target → $backup"
            ln -s "$src_real" "$target"
            echo "✓ Symlinked $target → $src_real"
        case merge
            echo ":: Copying existing $target/* INTO $src_real/ ..."
            cp -aR "$target/." "$src_real/"
            set -l backup "$target.bak-$ts"
            mv "$target" "$backup"
            echo "✓ Existing files copied into repo; original moved → $backup"
            ln -s "$src_real" "$target"
            echo "✓ Symlinked $target → $src_real"
            echo "   Hint: review the diff with"
            echo "     git -C $repo status caelestia-configs/"
            echo "   and 'git checkout' any unwanted overrides."
    end
end

if test $want_sddm -eq 1
    echo ""
    echo "============================================================"
    echo "                       INSTALLING SDDM"
    echo "============================================================"
    bash "$repo/sddm/scripts/install.sh"; or exit 1
end

if test $want_grub -eq 1
    echo ""
    echo "============================================================"
    echo "                       INSTALLING GRUB"
    echo "============================================================"
    bash "$repo/grub/scripts/install.sh"; or exit 1
end

# --- summary ----------------------------------------------------------------

echo ""
echo "============================================================"
echo "                            DONE"
echo "============================================================"
test $want_shell -eq 1; and echo "  ✓ Shell installed ($shell_mode)"
if test $want_configs -eq 1
    switch $configs_policy
        case already_linked
            echo "  ✓ Configs: already linked"
        case skip
            echo "  • Configs: skipped"
        case '*'
            echo "  ✓ Configs: $target → $src_real"
    end
end
test $want_sddm -eq 1; and echo "  ✓ SDDM theme installed"
test $want_grub -eq 1; and echo "  ✓ GRUB theme installed"
echo ""
if test $want_shell -eq 1 -a "$shell_mode" = user
    echo "  Reminder: log out and back in once so QML2_IMPORT_PATH / CAELESTIA_LIB_DIR"
    echo "  are set for every future session. The shell is running now with the env applied."
end
