#!/usr/bin/env bash
# Install yubikey-askpass for the current user.
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
ENV_DIR="$HOME/.config/environment.d"
ENV_FILE="$ENV_DIR/50-yubikey-askpass.conf"

python3 -c 'import gi; gi.require_version("Gtk", "4.0"); gi.require_version("Adw", "1")' 2>/dev/null || {
  echo "Missing dependencies: Python 3 with PyGObject, GTK 4 and libadwaita." >&2
  echo "  Arch/Manjaro:  sudo pacman -S python-gobject gtk4 libadwaita" >&2
  echo "  Debian/Ubuntu: sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1" >&2
  echo "  Fedora:        sudo dnf install python3-gobject gtk4 libadwaita" >&2
  exit 1
}

install -Dm755 "$SRC/yubikey-askpass" "$BIN_DIR/yubikey-askpass"
install -Dm644 "$SRC/assets/yubikey-security-key.svg" "$ICON_DIR/yubikey-security-key.svg"

mkdir -p "$ENV_DIR"
cat > "$ENV_FILE" <<CONF
# Ask for the security key PIN / touch in a desktop window (yubikey-askpass)
SSH_ASKPASS=$BIN_DIR/yubikey-askpass
SSH_ASKPASS_REQUIRE=prefer
CONF

echo "Installed yubikey-askpass."
echo "Log out and back in (or reboot) so SSH_ASKPASS is set in every terminal."
echo "To try it right away in this terminal:"
echo "  export SSH_ASKPASS=$BIN_DIR/yubikey-askpass SSH_ASKPASS_REQUIRE=prefer"
