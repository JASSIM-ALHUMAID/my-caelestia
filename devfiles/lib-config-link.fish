# lib-config-link.fish — shared helpers for repointing ~/.config/caelestia at
# the tree an installer was run from.
#
# Sourced (not executed) by install-user.fish, install-user-untagged.fish, and
# install-system.fish. Callers pass everything explicitly as arguments — these
# functions do not rely on inherited variable scope.
#
# Flow used by each installer:
#   1. cael_link_wanted $argv     — false only if --no-link was passed
#   2. cael_link_detach <conf>    — right before `cmake --install`
#   3. cael_link_apply ...        — right after `cmake --install`
#
# See .claude/worktrees/flavour-presets/scripts/worktree-install.fish for the
# prior art this was lifted from — that script repointed the symlink from
# outside, but every installer needs the same protection, so it belongs here.

function cael_link_wanted
    contains -- --no-link $argv; and return 1
    return 0
end

# cael_link_detach <conf>
# Called after the build, immediately before `cmake --install`, so the running
# shell can't auto-save config into a source tree mid-install.
function cael_link_detach --argument-names conf
    if test -L "$conf"
        mv "$conf" "$conf.bak-install"
        echo ":: Temporarily broke config symlink to protect source tree"
        return 0
    else if test -d "$conf"
        set_color yellow
        echo "!! ~/.config/caelestia is a real directory, not a symlink — not touching it"
        set_color normal
        return 1
    end
    # Doesn't exist: nothing to protect.
    return 0
end

# cael_link_restore <conf>
# Put the stashed symlink back. Every bail-out path in cael_link_apply ends here.
#
# `mv stash conf` looks obvious but is a trap: if $conf has become a real
# DIRECTORY (the shell can recreate it inside the detach window), mv moves the
# stash *inside* it, leaving a stray ~/.config/caelestia/caelestia.bak-install
# and reporting success. So refuse to move onto anything that already exists,
# and say plainly where the stash was left instead of lying about a restore.
#
# Tested with -L, not -e: the stash is always a symlink, and -e would miss it
# once it dangles (e.g. the tree it pointed at was removed mid-install).
function cael_link_restore --argument-names conf
    test -L "$conf.bak-install"; or return 0

    if test -e "$conf"; or test -L "$conf"
        set_color yellow
        echo "!! something else now occupies ~/.config/caelestia — leaving the"
        echo "   previous link stashed at $conf.bak-install; resolve it by hand"
        set_color normal
        return 1
    end

    mv "$conf.bak-install" "$conf"
    echo ":: Restored config symlink"
end

# cael_link_apply <repo> <conf> <relink> <detached>
# Called after `cmake --install` and (for the user scripts) before the shell
# kill/relaunch, so the relaunched shell reads the new link.
function cael_link_apply --argument-names repo conf relink detached
    if test "$relink" -eq 0; or test "$detached" -eq 0
        # --no-link was passed, or cael_link_detach hit the real-directory case
        # (nothing was stashed, and we must not touch a real directory) — just
        # put back whatever was stashed, if anything, and stop.
        cael_link_restore "$conf"
        return 0
    end

    if not test -d "$repo/caelestia-configs"
        # Some branches don't ship caelestia-configs/. Never leave the shell
        # pointing at a dangling link — restore the previous symlink instead.
        set_color yellow
        echo "!! $repo/caelestia-configs does not exist — leaving config link as-is"
        set_color normal
        cael_link_restore "$conf"
        return 0
    end

    # Defensive re-check: the shell can recreate ~/.config/caelestia inside the
    # detach window (e.g. a race with a still-running instance). Only clear it
    # if it's still a symlink or genuinely absent — never rm -rf a real
    # file/directory that appeared here, that could be user data.
    if test -L "$conf"; or not test -e "$conf"
        rm -f "$conf"
    else
        set_color yellow
        echo "!! ~/.config/caelestia is a real path again — not touching it"
        set_color normal
        cael_link_restore "$conf"
        return 0
    end

    ln -s "$repo/caelestia-configs" "$conf"
    # The stash is only ever a symlink (see cael_link_detach), so no data is
    # lost by dropping it here.
    rm -f "$conf.bak-install"
    echo "   - ~/.config/caelestia -> $repo/caelestia-configs"
end
