#!/usr/bin/env bash
set -euo pipefail
if [ "$EUID" -eq 0 ]; then echo 'Executer comme utilisateur du bureau, sans sudo devant le script.'; exit 1; fi
sudo dpkg --add-architecture i386
# The amd64 live ISO has no i386 package index; use online repositories instead.
if findmnt -n -o FSTYPE / | grep -qx overlay && [ -f /etc/apt/sources.list ]; then
    sudo sed -i.steam-usb-backup '/^deb cdrom:/s/^/#/' /etc/apt/sources.list
fi
sudo add-apt-repository -y multiverse
sudo apt-get update
sudo apt-get install -y steam-installer mesa-utils vainfo sysstat
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/steam.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Steam Remote Play
Exec=steam -silent
Terminal=false
X-GNOME-Autostart-enabled=true
EOF
echo 'Steam installe. Connexion et Steam Guard uniquement dans Steam.'
echo 'Choisir Remote Play: 720p, 60 i/s, 10 Mbit/s, H.264 et statistiques detaillees.'
steam &
