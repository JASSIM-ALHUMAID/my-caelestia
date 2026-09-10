#!/usr/bin/env bash
set -euo pipefail

# Prevent running with sudo - the script uses sudo internally for some commands
if [ "$(id -u)" -eq 0 ]; then
  echo "ERROR: Do not run this script with sudo. Run it normally." >&2
  exit 1
fi

LOCAL_SHARE="$HOME/.local/share/caelestia-grub"
GRUB_THEME_DIR="/boot/grub/themes/caelestia-nexus"
DEPLOY_SCRIPT="/usr/local/bin/caelestia-grub-deploy"
SUDOERS_FILE="/etc/sudoers.d/caelestia-grub-sync"

echo "============================================================"
echo "         Uninstalling Caelestia GRUB Theme"
echo "============================================================"
if ! sudo -v; then
  echo "✗ Sudo authentication failed. Exiting."
  exit 1
fi

echo "1. Removing GRUB theme files..."
sudo rm -rf "$GRUB_THEME_DIR"

echo "2. Removing deploy helper, sudoers entry and local files..."
sudo rm -f "$DEPLOY_SCRIPT"
sudo rm -f "$SUDOERS_FILE"
rm -rf "$LOCAL_SHARE"

echo "3. Removing Caelestia CLI postHook..."
CLI_JSON="$HOME/.config/caelestia/cli.json"
if [ -f "$CLI_JSON" ] && command -v jq >/dev/null; then
  tmp=$(jq '
    .wallpaper.postHook = ((.wallpaper.postHook // "") | split(" && ")
      | map(select(contains("caelestia-grub/scripts/sync.sh") | not)) | join(" && ")) |
    .theme.postHook = ((.theme.postHook // "") | split(" && ")
      | map(select(contains("caelestia-grub/scripts/sync.sh") | not)) | join(" && ")) |
    if .wallpaper.postHook == "" then .wallpaper |= del(.postHook) else . end |
    if .theme.postHook == "" then .theme |= del(.postHook) else . end |
    if .wallpaper == {} then del(.wallpaper) else . end |
    if .theme == {} then del(.theme) else . end
  ' "$CLI_JSON")
  if [ "$tmp" = "{}" ]; then
    rm -f "$CLI_JSON"
    echo "✓ Removed $CLI_JSON (was empty after cleanup)"
  else
    printf '%s\n' "$tmp" > "$CLI_JSON"
    echo "✓ Posthook entries removed from $CLI_JSON"
  fi
else
  echo "- $CLI_JSON not found or jq missing (skipped)"
fi

echo "4. Reverting GRUB configuration..."
GRUB_BACKUP=/etc/default/grub.caelestia-grub.bak
if grep -q "^GRUB_THEME=\"$GRUB_THEME_DIR" /etc/default/grub; then
  # Put back whatever GRUB_THEME was set to before install.sh ran, rather than
  # blanking it - the machine may well have had a theme before this one.
  PREV=""
  [ -f "$GRUB_BACKUP" ] && PREV=$(grep -m1 '^GRUB_THEME=' "$GRUB_BACKUP" || true)
  if [ -n "$PREV" ]; then
    REPL=${PREV//|/\\|}
    REPL=${REPL//&/\\&}
    sudo sed -i "s|^GRUB_THEME=\"$GRUB_THEME_DIR.*|$REPL|" /etc/default/grub
    echo "  Restored: $PREV"
  else
    sudo sed -i "s|^GRUB_THEME=\"$GRUB_THEME_DIR.*|#GRUB_THEME=|" /etc/default/grub
  fi
  sudo rm -f "$GRUB_BACKUP"
  sudo grub-mkconfig -o /boot/grub/grub.cfg
  echo "✓ GRUB configuration reverted"
else
  echo "✓ No changes needed in /etc/default/grub"
fi
echo "  Note: GRUB_GFXMODE and GRUB_TERMINAL_OUTPUT were left as-is."

echo ""
echo "✅ Uninstallation Complete."
