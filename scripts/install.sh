#!/usr/bin/env bash
set -euo pipefail

# Caelestia full installer — shell + SDDM theme + wallpaper sync
# Usage: ./scripts/install.sh [--skip-shell] [--skip-sddm]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_ROOT="$(dirname "$SCRIPT_DIR")"
SDDM_DIR="$SHELL_ROOT/sddm"

SKIP_SHELL=false
SKIP_SDDM=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-shell) SKIP_SHELL=true ;;
        --skip-sddm)  SKIP_SDDM=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run this script with sudo. Run it normally." >&2
    exit 1
fi

echo "╔══════════════════════════════════════╗"
echo "║    Caelestia Shell + SDDM Installer  ║"
echo "╚══════════════════════════════════════╝"
echo ""

# Only the SDDM theme needs root (it writes /usr/share/sddm and /etc/sudoers.d).
# The shell itself installs entirely under ~/.local and ~/.config now, so
# `--skip-sddm` runs without sudo at all.
if [ "$SKIP_SDDM" = false ]; then
    if ! sudo -v; then
        echo "✗ Sudo authentication failed." >&2
        exit 1
    fi
    echo "✓ Sudo authenticated"
fi

# ── 1. Shell install ─────────────────────────────────────────────────────────
if [ "$SKIP_SHELL" = true ]; then
    echo ""
    echo "[Shell] Skipping (--skip-shell)"
else
    echo ""
    echo "════════════════════════════════════════"
    echo " Installing shell"
    echo "════════════════════════════════════════"

    # Install everything under the user's home, never /usr. A prefix=/ install
    # would overwrite the caelestia-shell package's own files in
    # /usr/lib/qt6/qml, which pacman then reverts on every upgrade (and needs
    # sudo). ~/.local/lib/qt6/qml is picked up first via QML2_IMPORT_PATH, so the
    # fork's plugin overrides the packaged one and survives package upgrades.
    #
    # INSTALL_QMLDIR/QSCONFDIR/LIBDIR default to *relative* paths (usr/lib/...),
    # so passing them as absolute is what makes CMAKE_INSTALL_PREFIX irrelevant.
    # Setting only the prefix is the trap: it installs to ~/.local/usr/lib/...
    # Same three vars as devfiles/install-user.fish — keep them in sync.
    #
    # The target name in plugin/src/Caelestia/CMakeLists.txt MUST stay
    # `caelestia-core` (matching upstream) so the built artifact names are
    # identical to the package's. Two differently-named .so files both declaring
    # `module Caelestia` makes Qt abort with "Cannot add multiple registrations
    # for Caelestia" under quickshell-git.
    BUILD_DIR="$SHELL_ROOT/build"
    QSCONF="$HOME/.config/quickshell/caelestia"
    QMLDIR="$HOME/.local/lib/qt6/qml"
    LIBDIR="$HOME/.local/lib/caelestia"

    cmake -B "$BUILD_DIR" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$HOME/.local" \
        -DINSTALL_QMLDIR="$QMLDIR" \
        -DINSTALL_QSCONFDIR="$QSCONF" \
        -DINSTALL_LIBDIR="$LIBDIR" \
        "$SHELL_ROOT"
    cmake --build "$BUILD_DIR"

    # Wipe the plugin dirs first. cmake --install only overwrites the files it
    # knows about, so a stale .so from an older build survives inside a module
    # dir — and there it beats the fresh one in ../lib for the plugin's $ORIGIN
    # rpath, silently loading outdated types ("ButtonRow is not a type"). These
    # dirs are pure build output, so deleting them is safe. $QSCONF is NOT wiped:
    # config/ inside it is runtime state (same reasoning as scripts/sync-live.sh).
    rm -rf "$QMLDIR/Caelestia" "$QMLDIR/M3Shapes" "$LIBDIR"

    cmake --install "$BUILD_DIR"
    echo "✓ Shell QML installed to $QSCONF"
    echo "✓ Plugins installed to $QMLDIR (overrides the packaged copy)"
fi

# ── 2. SDDM theme install ────────────────────────────────────────────────────
if [ "$SKIP_SDDM" = true ]; then
    echo ""
    echo "[SDDM] Skipping (--skip-sddm)"
else
    echo ""
    echo "════════════════════════════════════════"
    echo " Installing SDDM theme"
    echo "════════════════════════════════════════"

    bash "$SDDM_DIR/scripts/install.sh"
    echo "✓ SDDM theme installed"

    # ── 3. Wallpaper sync (cli.json posthook) ────────────────────────────────
    echo ""
    echo "════════════════════════════════════════"
    echo " Configuring wallpaper auto-sync"
    echo "════════════════════════════════════════"

    CLI_JSON="$HOME/.config/caelestia/cli.json"
    mkdir -p "$(dirname "$CLI_JSON")"

    SYNC_SCRIPT="/usr/share/sddm/themes/caelestia/scripts/sync.sh"

    if command -v python3 &>/dev/null && [ -f "$CLI_JSON" ]; then
        python3 - "$CLI_JSON" "$SYNC_SCRIPT" <<'PYEOF'
import sys, json
path, sync = sys.argv[1], sys.argv[2]
hook = f"sudo {sync} --posthook"
with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("wallpaper", {})["postHook"] = hook
cfg.setdefault("theme", {})["postHook"] = hook
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PYEOF
    else
        cat > "$CLI_JSON" <<JSONEOF
{
  "wallpaper": {
    "postHook": "sudo $SYNC_SCRIPT --posthook"
  },
  "theme": {
    "postHook": "sudo $SYNC_SCRIPT --posthook"
  }
}
JSONEOF
    fi
    echo "✓ $CLI_JSON configured with postHook"

    # ── 4. Sudoers entry ──────────────────────────────────────────────────────
    SUDOERS_FILE="/etc/sudoers.d/caelestia-sddm-sync"
    SUDOERS_LINE="$USER ALL=(root) NOPASSWD: $SYNC_SCRIPT"

    if [ -f "$SUDOERS_FILE" ] && grep -qF "$SUDOERS_LINE" "$SUDOERS_FILE" 2>/dev/null; then
        echo "✓ Sudoers entry already present"
    else
        echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" > /dev/null
        sudo chmod 440 "$SUDOERS_FILE"
        echo "✓ Created $SUDOERS_FILE"
    fi

    # ── 5. Initial sync ───────────────────────────────────────────────────────
    echo "Running initial SDDM sync..."
    sudo "$SYNC_SCRIPT"
    echo "✓ Initial sync complete"
fi

echo ""
echo "╔══════════════════════════════════════╗"
echo "║         Installation complete!       ║"
echo "╚══════════════════════════════════════╝"
