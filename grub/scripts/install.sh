#!/usr/bin/env bash
set -euo pipefail

# Prevent running with sudo - the script uses sudo internally for some commands
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: Do not run this script with sudo. Run it normally." >&2
  exit 1
fi

# Dynamically find the project root regardless of where this script is called from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

LOCAL_SHARE="$HOME/.local/share/caelestia-grub"
GRUB_THEME_DIR="/boot/grub/themes/caelestia-nexus"
DEPLOY_SCRIPT="/usr/local/bin/caelestia-grub-deploy"
SUDOERS_FILE="/etc/sudoers.d/caelestia-grub-sync"

# --- Sudo check ---
echo "Caelestia GRUB Theme Installer"
echo "This script requires sudo privileges to deploy the theme to /boot."
echo ""
if ! sudo -v; then
  echo "✗ Sudo authentication failed. Exiting."
  exit 1
fi
echo "✓ Sudo authenticated"
# -----------------

# --- Dependency Check ---
echo ""
echo "============================================================"
echo "                   INSTALL GRUB THEME"
echo "============================================================"

DEPENDENCIES=(
  "grub"
  "python"
  "python-pillow"
  "python-pyqt6"
  "jq"
  # generate.py shells out to ffmpeg to pull a frame from video wallpapers
  "ffmpeg"
)

echo "Checking dependencies..."
MISSING_PKGS=()

# pacman -T reports exactly the targets that are not satisfied. Do not use
# `pacman -Qs`: it is a substring search across package names *and*
# descriptions ("python" alone matches 150+ installed packages), so it can
# report a genuinely missing dependency as present.
for pkg in "${DEPENDENCIES[@]}"; do
  if [ -n "$(pacman -T "$pkg" 2>/dev/null)" ]; then
    MISSING_PKGS+=("$pkg")
  fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
  echo "📦 Missing packages found: ${MISSING_PKGS[*]}"
  echo "Installing missing dependencies..."
  sudo pacman -S --noconfirm "${MISSING_PKGS[@]}"
else
  echo "✓ All dependencies met."
fi
# ------------------------

# 1. Stage files to local share (assets are regenerated here on every sync,
#    so they are copied rather than symlinked to keep the repo clean)
echo ""
echo "1. Staging files to $LOCAL_SHARE..."
mkdir -p "$LOCAL_SHARE/scripts"
rm -rf "$LOCAL_SHARE/src" "$LOCAL_SHARE/theme"
cp -r "$PROJECT_ROOT/src" "$LOCAL_SHARE/src"
cp -r "$PROJECT_ROOT/theme" "$LOCAL_SHARE/theme"
cp "$SCRIPT_DIR/sync.sh" "$LOCAL_SHARE/scripts/"
chmod +x "$LOCAL_SHARE/scripts/sync.sh"
echo "✓ Local files staged"

# 2. Deploy helper in a root-owned directory. Do NOT place this in ~/.local/bin:
#    the sudoers entry below grants passwordless root for this exact path, so it
#    must not live anywhere the user can replace it.
echo "2. Creating deploy helper at $DEPLOY_SCRIPT..."
#    sharp.png/blur.png/composite_bg.png are generator intermediates and
#    preview.png is a --preview artefact; GRUB reads none of them, so they are
#    skipped rather than parked on the boot partition.
cat <<EOF | sudo tee "$DEPLOY_SCRIPT" >/dev/null
#!/usr/bin/env bash
set -e
mkdir -p "$GRUB_THEME_DIR"
for entry in "$LOCAL_SHARE/theme/"*; do
  case "\$(basename "\$entry")" in
    sharp.png|blur.png|composite_bg.png|preview.png) continue ;;
  esac
  cp -r "\$entry" "$GRUB_THEME_DIR/"
done
EOF
sudo chown root:root "$DEPLOY_SCRIPT"
sudo chmod 755 "$DEPLOY_SCRIPT"
echo "✓ Deploy helper created"

# 3. Passwordless sudoers entry so the posthook can deploy without a prompt
echo "3. Creating sudoers entry for passwordless deploy..."
SUDOERS_LINE="$USER ALL=(root) NOPASSWD: $DEPLOY_SCRIPT"
echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" >/dev/null
sudo chmod 440 "$SUDOERS_FILE"
if sudo visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
  echo "✓ Sudoers entry created at $SUDOERS_FILE"
else
  echo "✗ Sudoers validation failed, removing entry"
  sudo rm -f "$SUDOERS_FILE"
  echo "  Manual setup: add '$SUDOERS_LINE' to $SUDOERS_FILE"
  exit 1
fi

# 4. Initial generation and sync
echo "4. Running initial generation and sync..."
STAMP=$(mktemp)
bash "$LOCAL_SHARE/scripts/sync.sh"
# The generator is the one step that can leave a valid-looking but stale theme
# behind, so confirm this run actually rewrote the background before declaring
# success and pointing GRUB at it.
if [ ! "$LOCAL_SHARE/theme/background.png" -nt "$STAMP" ]; then
  rm -f "$STAMP"
  echo "✗ Generation did not produce a new background.png - aborting." >&2
  exit 1
fi
rm -f "$STAMP"
echo "✓ Initial sync completed"

# 5. Point GRUB at the theme and regenerate its config
echo "5. Updating GRUB configuration..."
# Step 4 can run for a while; refresh the sudo timestamp so the remaining
# root commands do not stop for a password prompt halfway through.
sudo -v

GRUB_BACKUP=/etc/default/grub.caelestia-grub.bak
[ -f "$GRUB_BACKUP" ] || sudo cp /etc/default/grub "$GRUB_BACKUP"

set_grub_default() {
  local key="$1" val="$2"
  if grep -q "^${key}=" /etc/default/grub; then
    sudo sed -i "s|^${key}=.*|${key}=${val}|" /etc/default/grub
  elif grep -q "^#\s*${key}=" /etc/default/grub; then
    sudo sed -i "s|^#\s*${key}=.*|${key}=${val}|" /etc/default/grub
  else
    echo "${key}=${val}" | sudo tee -a /etc/default/grub >/dev/null
  fi
}

# theme.txt places every element at absolute 1920x1080 pixel coordinates, so
# pin the gfx mode instead of letting GRUB negotiate one.
set_grub_default GRUB_THEME "\"$GRUB_THEME_DIR/theme.txt\""
set_grub_default GRUB_GFXMODE "1920x1080,auto"
set_grub_default GRUB_TERMINAL_OUTPUT "gfxterm"

if grep -qE '^GRUB_TERMINAL=.*console' /etc/default/grub; then
  echo "  ! GRUB_TERMINAL is set to console in /etc/default/grub - the theme will not render."
  echo "    Comment that line out to use the graphical menu."
fi

sudo grub-mkconfig -o /boot/grub/grub.cfg
echo "✓ GRUB updated"

# 6. Hook into cli.json for automatic sync on wallpaper/theme change.
#    Unlike the SDDM installer this APPENDS to existing postHooks (SDDM, wezterm,
#    starship, ...) instead of replacing them; stale caelestia-grub entries from
#    older installs are stripped first.
echo "6. Configuring Caelestia CLI postHook..."
CLI_JSON="$HOME/.config/caelestia/cli.json"
SYNC_CMD="bash $LOCAL_SHARE/scripts/sync.sh"
mkdir -p "$(dirname "$CLI_JSON")"
[ -f "$CLI_JSON" ] || echo '{}' > "$CLI_JSON"
tmp=$(jq --arg cmd "$SYNC_CMD" '
  .wallpaper.postHook = ((.wallpaper.postHook // "") | split(" && ")
    | map(select((. == "") or (contains("caelestia-grub/scripts/sync.sh")) | not))
    + [$cmd] | join(" && ")) |
  .theme.postHook = ((.theme.postHook // "") | split(" && ")
    | map(select((. == "") or (contains("caelestia-grub/scripts/sync.sh")) | not))
    + [$cmd] | join(" && "))
' "$CLI_JSON")
printf '%s\n' "$tmp" > "$CLI_JSON"
echo "✓ Posthook configured in $CLI_JSON"

echo ""
echo "============================================================"
echo "✅ Installation Complete!"
echo "The theme has been applied to GRUB."
echo "Whenever you change your theme or wallpaper in Caelestia, the"
echo "GRUB background and assets will regenerate and sync automatically."
echo "============================================================"
