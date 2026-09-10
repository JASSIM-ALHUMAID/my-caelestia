#!/usr/bin/env bash
set -euo pipefail

# Called by the Caelestia CLI postHook on wallpaper/theme change.
# Runs as the regular user; only the final deploy step escalates,
# via the passwordless sudoers entry for caelestia-grub-deploy.

LOCAL_SHARE="$HOME/.local/share/caelestia-grub"
DEPLOY_SCRIPT="/usr/local/bin/caelestia-grub-deploy"

echo "Syncing Caelestia GRUB theme..."

# 1. Regenerate assets in the user's local directory
if [ -f "$LOCAL_SHARE/src/generate.py" ]; then
    echo "Regenerating assets..."
    cd "$LOCAL_SHARE/src"
    python3 generate.py
    echo "✓ Assets regenerated locally"
else
    echo "✗ Error: generate.py not found in $LOCAL_SHARE/src" >&2
    exit 1
fi

# 2. Deploy to /boot/grub using the passwordless sudo helper
if [ -f "$DEPLOY_SCRIPT" ]; then
    echo "Deploying to /boot/grub..."
    sudo "$DEPLOY_SCRIPT"
    echo "✓ Deployment complete"
else
    echo "✗ Error: $DEPLOY_SCRIPT not found. Is the theme properly installed?" >&2
    exit 1
fi

echo "✓ Sync complete"
