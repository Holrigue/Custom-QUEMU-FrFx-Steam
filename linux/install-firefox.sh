#!/usr/bin/env bash
# Source: https://support.mozilla.org/en-US/kb/install-firefox-linux
set -euo pipefail
if [ "$EUID" -eq 0 ]; then
    echo 'Executer comme utilisateur du bureau : bash install-firefox.sh'; exit 1
fi
if findmnt -n -o FSTYPE / | grep -qx overlay; then
    echo 'Session LIVE : cette installation disparaitra apres extinction.'
fi
sudo -v
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
wget -qO "$work/mozilla.asc" https://packages.mozilla.org/apt/repo-signing-key.gpg
fingerprint=$(gpg --batch --show-keys --with-colons "$work/mozilla.asc" | awk -F: '$1=="fpr" {print $10; exit}')
if [ "$fingerprint" != 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3 ]; then
    echo 'Empreinte de signature Mozilla inattendue : arret.'; exit 1
fi
sudo install -d -m 0755 /etc/apt/keyrings
sudo install -m 0644 "$work/mozilla.asc" /etc/apt/keyrings/steam-usb-mozilla.asc
printf '%s\n' 'deb [signed-by=/etc/apt/keyrings/steam-usb-mozilla.asc] https://packages.mozilla.org/apt mozilla main' |
    sudo tee /etc/apt/sources.list.d/steam-usb-mozilla.list >/dev/null
printf '%s\n' 'Package: firefox firefox-l10n-*' 'Pin: origin packages.mozilla.org' 'Pin-Priority: 1000' |
    sudo tee /etc/apt/preferences.d/steam-usb-firefox >/dev/null
sudo apt-get update
sudo apt-get install -y --no-install-recommends firefox firefox-l10n-fr
xdg-settings set default-web-browser firefox.desktop
for mime in text/html x-scheme-handler/http x-scheme-handler/https; do
    xdg-mime default firefox.desktop "$mime"
done
firefox --version
printf 'Navigateur par defaut : '
xdg-settings get default-web-browser
echo 'Installation terminee. Lancer Firefox depuis le menu Internet.'
