#!/usr/bin/env bash
# Remove yubikey-askpass for the current user.
set -euo pipefail

rm -f "$HOME/.local/bin/yubikey-askpass" \
      "$HOME/.local/share/icons/hicolor/scalable/apps/yubikey-security-key.svg" \
      "$HOME/.config/environment.d/50-yubikey-askpass.conf"

echo "Removed yubikey-askpass. Log out and back in to clear SSH_ASKPASS."
