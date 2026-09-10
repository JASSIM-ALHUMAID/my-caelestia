# devfiles — install helpers

Two fish scripts to install this shell build from the current checkout, plus the
config snippet the user install needs.

> For installing the shell **plus** the Caelestia user configs and/or the SDDM theme in
> one go, use the unified installer at the repo root: `./install.fish`. The scripts
> here remain usable directly for per-piece installs.

| File | What it does |
|------|--------------|
| `install-user.fish` | Installs for the current user only — **no sudo**. |
| `install-system.fish` | Installs system-wide — **needs sudo**. |
| `install-user-untagged.fish` | Variant of `install-user.fish` that passes `VERSION=0.0.0`, for checkouts without git tags. |
| `lib-config-link.fish` | Shared helper, sourced by the three installers above — not run directly. |
| `hypr-caelestia-env.conf` | Reference copy of the Hyprland env lines the user install adds. |

## `~/.config/caelestia` follows the tree you install from

All three installers repoint `~/.config/caelestia` at the `caelestia-configs/` of
whichever checkout/worktree they were run from, right after `cmake --install` (before
`install-user*.fish` restart the shell, so the relaunched shell reads the new link).
This makes any branch or worktree fully self-activating — build it, install it, and
the running shell both reads and auto-saves into that tree's config.

- If `~/.config/caelestia` is a real directory (not a symlink), the installers leave it
  completely alone and just warn — they never move or delete what could be user data.
- If a checkout has no `caelestia-configs/` directory at all, the installers warn and
  leave the existing link untouched rather than pointing at something that doesn't exist.
- Pass `--no-link` to any of the three scripts to skip the repoint and leave
  `~/.config/caelestia` exactly as it was (e.g. `./devfiles/install-user.fish --no-link`).

## Background: why the user install needs an env var

The install has two halves that live in different places:

- **QML config** → resolved by XDG dirs: `~/.config/quickshell/caelestia` (user) wins over `/etc/xdg/quickshell/caelestia` (system).
- **C++ plugin** (`Caelestia.*`) → resolved by Qt's QML import path, which by default only includes `/usr/lib/qt6/qml`.

A **system** install puts the plugin in `/usr/lib/qt6/qml`, so it's found automatically.
A **user** install puts it in `~/.local/lib/qt6/qml`, which is *not* on the default path —
so the user script also exports `QML2_IMPORT_PATH` (and `CAELESTIA_LIB_DIR` for the beat
detector) via `~/.config/hypr/hyprland/env.conf` and `~/.config/uwsm/env`. Without that you
get the classic symptom: new QML config + stale system plugin → `Config.bar.edge`/`tray`
undefined → **no bar**.

## User install

```sh
./devfiles/install-user.fish
```

- Configures + builds into `build/`, installs to `~/.local` + `~/.config`.
- Appends the env lines (idempotent — safe to re-run).
- Restarts the shell immediately with the env set.
- **Log out and back in once** to make the env permanent for every future launch.

Nothing requires root, and the pacman `caelestia-shell` package stays intact — your user
copy simply overrides it.

## System install

```sh
./devfiles/install-system.fish
```

- Configures + builds into a separate `build-system/` (leaves your user `build/` alone),
  installs to `/usr` + `/etc/xdg` via `sudo`. No env var needed.
- Warns if user-local overrides still exist (they would hide the system install) and tells
  you what to remove.

> **Heads-up:** this overwrites files owned by the `caelestia-shell` pacman package without
> pacman tracking them — a future package upgrade will overwrite your build. For a clean,
> pacman-tracked system install, build the `PKGBUILD` with `makepkg -si` instead.

## Switching back

- Remove the user override: delete the Caelestia env lines from `~/.config/hypr/hyprland/env.conf`
  and `~/.config/uwsm/env`, then `rm -rf ~/.config/quickshell/caelestia ~/.local/lib/qt6/qml/Caelestia ~/.local/lib/caelestia`, re-login.
- The shell then falls back to whatever is installed system-wide (the pacman package, or your
  `install-system.fish` build).
