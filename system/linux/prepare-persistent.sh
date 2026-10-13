#!/usr/bin/env bash
set -euo pipefail
if [ "$EUID" -eq 0 ]; then
    echo 'Run with "bash prepare-persistent.sh", without sudo in front.'; exit 1
fi
if findmnt -n -o FSTYPE / | grep -qx overlay; then
    echo 'STOP: live session. Install Linux onto the virtual disk first, then use Play from Media Center.cmd.'; exit 1
fi
base=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
sudo -v
# Keep a recovery copy and generate only the two requested locales.
if [ -f /etc/locale.gen ]; then
    sudo cp -n /etc/locale.gen /etc/locale.gen.steam-usb-original
    printf '%s\n' 'en_US.UTF-8 UTF-8' 'fr_CA.UTF-8 UTF-8' | sudo tee /etc/locale.gen >/dev/null
    sudo locale-gen
fi
bash "$base/install-firefox.sh"
bash "$base/install-retroarch.sh"
bash "$base/install-steam.sh"
mkdir -p "$HOME/.local/share/steam-usb"
date -Iseconds > "$HOME/.local/share/steam-usb/prepared-at"
echo 'Setup complete. Shut down Linux, choose Play again from Media Center.cmd, and check Firefox, Steam and RetroArch.'
