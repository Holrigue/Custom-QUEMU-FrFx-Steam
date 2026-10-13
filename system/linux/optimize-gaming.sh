#!/usr/bin/env bash
# Light optimizations for Remote Play inside the VM (llvmpipe software rendering, CPU-bound).
# Run once in the user's Xfce session:  bash optimize-gaming.sh
# - disables xfwm4 compositing: frees CPU and reduces stream latency/tearing;
# - prevents the screen from blanking/sleeping while playing;
# - makes these settings permanent through an autostart entry.
set -euo pipefail
if [ "$EUID" -eq 0 ]; then
    echo 'Run as the desktop user, without sudo: bash optimize-gaming.sh'; exit 1
fi

# Apply immediately.
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true
xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/dpms-enabled -s false 2>/dev/null || true
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true

# Make it permanent at each login.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/steam-usb-gaming-tweaks.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Steam USB gaming tweaks
Comment=Compositing off + no screen sleep for Remote Play
Exec=sh -c "xfconf-query -c xfwm4 -p /general/use_compositing -s false; xset s off; xset -dpms"
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo 'Optimizations applied and made permanent:'
echo ' - xfwm4 compositing disabled (frees CPU, less tearing)'
echo ' - screen sleep/blanking disabled'
echo 'Tip: close Windows apps before playing to free up RAM.'
