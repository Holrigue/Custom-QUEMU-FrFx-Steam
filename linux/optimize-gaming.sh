#!/usr/bin/env bash
# Optimisations legeres pour le Remote Play dans la VM (rendu logiciel llvmpipe, CPU-bound).
# A lancer une fois dans la session Xfce de l'utilisateur :  bash optimize-gaming.sh
# - desactive le compositing xfwm4 : libere du CPU et reduit latence/tearing du flux ;
# - empeche l'extinction/veille de l'ecran pendant le jeu ;
# - rend ces reglages permanents via une entree d'autostart.
set -euo pipefail
if [ "$EUID" -eq 0 ]; then
    echo 'Executer comme utilisateur du bureau, sans sudo : bash optimize-gaming.sh'; exit 1
fi

# Appliquer immediatement.
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

# Rendre permanent a chaque ouverture de session.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/steam-usb-gaming-tweaks.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Steam USB gaming tweaks
Comment=Compositing off + pas de veille ecran pour le Remote Play
Exec=sh -c "xfconf-query -c xfwm4 -p /general/use_compositing -s false; xset s off; xset -dpms"
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo 'Optimisations appliquees et rendues permanentes :'
echo ' - compositing xfwm4 desactive (CPU libere, moins de tearing)'
echo ' - veille/extinction ecran desactivee'
echo 'Astuce : fermer les applications Windows avant de jouer pour liberer de la RAM.'
