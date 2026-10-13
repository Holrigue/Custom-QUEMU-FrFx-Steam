#!/usr/bin/env bash
# Installs RetroArch and a lightweight set of libretro cores, pre-tuned for THIS
# VM (llvmpipe software rendering, no GPU, CPU-bound). Run as the desktop user:
#   bash install-retroarch.sh
#
# What it sets up for the USB/VM constraint:
# - rgui menu (software-drawn) instead of the GPU-heavy XMB menu;
# - a curated set of light cores (NES, SNES, GB/GBC, GBA, Genesis/MD/SMS, PS1);
# - fullscreen, no shaders, nearest-neighbour scaling, rewind/run-ahead off;
# - ROMs / saves / BIOS folders under ~/Games.
# It installs NO ROMs and NO BIOS files (copyrighted): you add your own, legally.
set -euo pipefail
if [ "$EUID" -eq 0 ]; then echo 'Run as the desktop user, without sudo: bash install-retroarch.sh'; exit 1; fi
if findmnt -n -o FSTYPE / | grep -qx overlay; then
    echo 'STOP: live session. Install Linux onto the virtual disk first, then run this.'; exit 1
fi
sudo -v

# 1. Frontend from the Ubuntu universe repository.
sudo add-apt-repository -y universe
sudo apt-get update
sudo apt-get install -y --no-install-recommends retroarch unzip wget
sudo apt-get install -y retroarch-assets 2>/dev/null || true   # nice-to-have, not required by rgui

# 2. Folders: cores/info in the config dir, games/saves/BIOS under ~/Games.
cfg="$HOME/.config/retroarch"
mkdir -p "$cfg/cores" "$cfg/info"
mkdir -p "$HOME/Games/roms" "$HOME/Games/saves" "$HOME/Games/states" "$HOME/Games/bios"

# 3. Curated lightweight cores from the libretro nightly buildbot (x86_64 Linux).
#    These run acceptably in software rendering. Heavier cores (N64/PSP/PS2/GC)
#    are intentionally left out; add them later via Online Updater if you wish.
bb='https://buildbot.libretro.com/nightly/linux/x86_64/latest'
cores='fceumm snes9x gambatte mgba genesis_plus_gx pcsx_rearmed'
work=$(mktemp -d); trap 'rm -rf -- "$work"' EXIT
for c in $cores; do
    if wget -q --tries=3 -O "$work/$c.zip" "$bb/${c}_libretro.so.zip"; then
        unzip -oq "$work/$c.zip" -d "$cfg/cores" && echo "  core installed: $c"
    else
        echo "  WARN: could not download core '$c' (add it later via Online Updater)"
    fi
done
# Core info files (readable core names + content scanning).
if wget -q --tries=3 -O "$work/info.zip" 'https://buildbot.libretro.com/assets/frontend/info.zip'; then
    unzip -oq "$work/info.zip" -d "$cfg/info" || true
fi

# 4. Pre-tuned configuration for software rendering (written before first launch).
#    video_driver=sdl2 on purpose: the "gl" driver fails here with a GLX
#    BadAccess (X_GLXMakeContextCurrent) because the VM has no GPU (llvmpipe).
#    SDL2 does a pure software blit and works.
cat > "$cfg/retroarch.cfg" <<EOF
menu_driver = "rgui"
video_driver = "sdl2"
video_threaded = "true"
video_vsync = "true"
video_max_swapchain_images = "2"
video_smooth = "false"
video_shader_enable = "false"
video_fullscreen = "true"
video_windowed_fullscreen = "true"
audio_driver = "pulse"
audio_latency = "96"
rewind_enable = "false"
run_ahead_enabled = "false"
input_autodetect_enable = "true"
libretro_directory = "$cfg/cores"
libretro_info_path = "$cfg/info"
rgui_browser_directory = "$HOME/Games/roms"
savefile_directory = "$HOME/Games/saves"
savestate_directory = "$HOME/Games/states"
system_directory = "$HOME/Games/bios"
core_updater_buildbot_cores_url = "$bb/"
EOF

# 5. A note in the ROMs folder (how to add games + the legal boundary).
cat > "$HOME/Games/roms/READ-ME-FIRST.txt" <<'EOF'
Put your own, legally-obtained game files (ROMs) in the matching sub-folder:
  nes/  snes/  gb/  gbc/  gba/  genesis/  sms/  psx/
This kit ships the RetroArch player only - no games and no BIOS files.

Add games from INSIDE this Linux VM (e.g. download them with Firefox),
because the Windows USB stick is not directly visible from inside the VM.

After adding games, build the game lists by running:
  bash make-playlists.sh
(each game then launches in one click from its system's list).

Some systems (e.g. PlayStation 1) also need a BIOS file you legally own:
put it in ~/Games/bios . Then open RetroArch -> Load Content.
EOF

# 6. Desktop shortcut for quick access.
mkdir -p "$HOME/Desktop"
cat > "$HOME/Desktop/RetroArch.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=RetroArch (emulators)
Exec=retroarch
Icon=retroarch
Terminal=false
Categories=Game;
EOF
chmod +x "$HOME/Desktop/RetroArch.desktop" || true

# 7. Newcomer-friendly setup: simple "kiosk" menu, per-system folders, game lists.
here="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$here/make-playlists.sh" ]; then
    bash "$here/make-playlists.sh" || true
fi

echo
echo 'RetroArch installed and pre-configured for this VM:'
echo ' - Light cores ready: NES, SNES, GB/GBC, GBA, Genesis/MD/SMS, PlayStation 1.'
echo ' - Heavy systems (N64, PSP, PS2, GameCube...) are NOT set up: no GPU in the VM.'
echo ' - Simple menu (kiosk) + one game list per system.'
echo ' - Add your ROMs in ~/Games/roms/<system>/ then run: bash make-playlists.sh'
echo 'Open it from the "RetroArch (emulators)" Desktop icon or the Games menu.'
