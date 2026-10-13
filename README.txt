===============================================================================
  USB-VM LINUX MEDIA CENTER  (QEMU + Linux on a USB stick)
===============================================================================

Run the Linux Steam Remote Play client in a window on Windows 11, carried on an
ordinary USB stick. Your gaming PC at home runs the games; the local PC runs
QEMU, Linux, and the stream decoding. It also carries RetroArch for local retro
gaming (8/16-bit consoles and PlayStation 1). Nothing is installed on the host
and everything persists on the stick.

v0.1.0 - experimental prototype. A first Remote Play run was reported as very
smooth by the user. That is not a guarantee of FPS or compatibility on every
PC. See system/docs/TESTS.md.


-------------------------------------------------------------------------------
  HOW TO START  (the short version)
-------------------------------------------------------------------------------

Double-click:   Media Center.cmd

It opens a small menu:

    [1]  Play             - fullscreen, for Remote Play
    [2]  Desktop mode     - windowed, for setup / browsing
    [3]  Paste clipboard into the VM
    [4]  First-time setup - install Linux (run once)
    [5]  Hardware check   - WHPX diagnostic
    [0]  Quit

First time on a new stick: do the one-time preparation below, then choose
[5] Hardware check, then [4] First-time setup. After that, always use [1] Play.


-------------------------------------------------------------------------------
  WHAT'S ON THE STICK
-------------------------------------------------------------------------------

    <stick>/
      Media Center.cmd           <- the only thing you double-click
      README.txt                 <- this file
      system/                    <- everything else lives here
        scripts/                 Launch.ps1, Paste-ToVM.ps1, ...
        config/settings.json     RAM, vCPU, profile, mouse mode
        linux/                   Firefox, Steam and RetroArch install scripts
        docs/                    extra notes (SETUP, CLIPBOARD, MOUSE, ...)
        runtime/qemu/            <- you add QEMU here (not shipped)
        iso/                     <- you add the Linux ISO here (not shipped)
        vm/                      <- created by the launcher; your Linux lives here
        logs/                    local logs

This release is a kit of scripts and docs. It does NOT contain QEMU, the ISO, a
preinstalled Linux disk, or the Firefox/Steam/RetroArch binaries. The preparation below
installs them once; apps and settings persist afterward. No personal VM or
Steam session is published. See system/docs/PREINSTALL.md.


-------------------------------------------------------------------------------
  REQUIREMENTS
-------------------------------------------------------------------------------

- Windows 11 x64 (Intel/AMD); ARM is not supported here.
- About 5-6 GiB of free RAM (VM: 4 GiB, configurable in system/config).
- A fast stick. The trial ran on an ordinary 16 GB stick, capacity was tight.
  No game is installed locally.
- Internet; the gaming PC on, with Steam Remote Play enabled.
- WHPX recommended if Windows Hypervisor Platform and virtualization are already
  available. The TCG fallback may be too slow to play. No Windows activation and
  no automatic driver install.


-------------------------------------------------------------------------------
  1. PREPARE THE STICK  (once)
-------------------------------------------------------------------------------

Do NOT use Rufus: Windows launches the VM from ordinary files. No formatting
needed.

1. Extract the kit onto the stick (you get "Media Center.cmd", "README.txt"
   and "system/").
2. Download "qemu-w64-setup-20260811.exe" and its ".sha512" from the Windows
   build referenced by QEMU: https://qemu.weilnetz.de/w64/
   Verify with:  Get-FileHash -Algorithm SHA512
   Extract the installer with 7-Zip WITHOUT running it, then put its full
   contents into  system/runtime/qemu  : EXE, DLLs, BIOS and data.
   Tested version: QEMU 11.1.0 (v11.1.0-12130-ge470268ff4).
3. Download "xubuntu-24.04.5-minimal-amd64.iso" and "SHA256SUMS" from the
   official images:
   https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/
   Verify SHA256, then put the image into  system/iso/
   Tested hash: 9d47f975696ce496b8be882b6d7cc9079c1ea89fb625ac2c86caa63a4f180033
4. Double-click "Media Center.cmd", choose [5] Hardware check, then
   [4] First-time setup.

Xubuntu 24.04 LTS Minimal: light Xfce, Ubuntu base, and i386 Steam libraries.
Xubuntu support runs to April 2027; plan a migration. The browser is installed
separately.


-------------------------------------------------------------------------------
  2. INSTALL LINUX  (once)
-------------------------------------------------------------------------------

1. Open "Install Xubuntu Minimal" on the VM desktop.
2. Choose "Interactive installation".
3. Choose "Erase disk and install Xubuntu" ONLY for the 10 GiB virtual disk
   (~10.7 GB), usually /dev/vda. The launcher exposes no physical Windows disk.
   If the target differs, stop and check.
4. Create your account and password directly in the installer.
5. When done, shut Linux down, then choose [1] Play. Do not use setup or test
   mode to play.

The VMDK is split for FAT32: keep "linux.vmdk" and ALL "linux-s*.vmdk" together.
Paths are relative; the stick's drive letter can change.

On a 16 GB stick, QEMU (~1.6 GB), the ISO (~3 GB, temporary) and the virtual
disk (up to 10 GiB) are tight. After a successful install and shutdown, you can
keep the ISO on the PC and remove it from the stick. Keep some headroom and also
check "df -h /" in Linux. Do not move an active disk or run it from a
cloud-synced folder.


-------------------------------------------------------------------------------
  3. INSTALL FIREFOX, STEAM AND RETROARCH
-------------------------------------------------------------------------------

In the terminal of the INSTALLED Linux (no browser needed), download the
scripts:

    mkdir -p ~/steam-usb-setup
    cd ~/steam-usb-setup
    wget https://github.com/Holrigue/usb-vm-linux-media-center/releases/download/v0.1.0/SteamUSB-v0.1.0-linux.tar.gz
    wget https://github.com/Holrigue/usb-vm-linux-media-center/releases/download/v0.1.0/SHA256SUMS
    grep 'SteamUSB-v0.1.0-linux.tar.gz' SHA256SUMS | sha256sum -c -

Continue only if the check prints OK:

    tar -xzf SteamUSB-v0.1.0-linux.tar.gz
    bash linux/prepare-persistent.sh

The script refuses a live session, asks for sudo, prepares the fr_CA/en_US
locales, installs Firefox from the Mozilla repo with a key-fingerprint check,
enables i386/multiverse, and installs Steam with its dependencies. It also
installs RetroArch, pre-tuned for this VM (see "Retro gaming" below). It sets
Firefox as the default browser and Steam to start with the Linux session. Steam
downloads its update at first launch; sign in and enter Steam Guard only inside
Steam.

The linux/ scripts can also be copied into the VM together. The Windows/Linux
clipboard sync is not configured (see the paste tool below).


-------------------------------------------------------------------------------
  4. PLAY AND STOP
-------------------------------------------------------------------------------

Enable Remote Play on the host PC. In the VM, use the same account and choose
"Stream" from the remote PC. Do not download games in the VM.

Suggested starting point: 720p, 60 fps, H.264, 10 Mbit/s, with detailed stats in
the Remote Play advanced options. Compare network, decoding and smoothness. Try
1080p/60 and 15-20 Mbit/s only if the measurements allow it. The VGA profile
exposes no hardware GPU decoding.

[1] Play uses fullscreen SDL with a locked relative mouse (best for games):
Ctrl+Alt+G releases the mouse, Ctrl+Alt+F leaves fullscreen. [2] Desktop mode is
windowed GTK, handier for setup and browsing. See system/docs/MOUSE.md.

To remove the stick: shut Linux down, wait for QEMU to close, then eject in
Windows. There is NO protection against yanking it out.


-------------------------------------------------------------------------------
  RETRO GAMING  (RETROARCH)
-------------------------------------------------------------------------------

The setup also installs RetroArch, pre-configured for this no-GPU VM: a light
software menu (rgui), fullscreen, and no shaders. Ready-to-use cores cover NES,
SNES, Game Boy / GBC / GBA, Genesis / Mega Drive / Master System, and
PlayStation 1. Heavier systems (N64, PSP, PS2, GameCube...) are left out on
purpose: software rendering has no GPU to drive them.

It is set up for newcomers: a simple "kiosk" menu (no technical options) and one
game list per system, each game launching in a single click.

This ships the PLAYER only: no games and no BIOS files (those are copyrighted).
Add your own, legally, from INSIDE the VM (e.g. download them with Firefox) into
the matching sub-folder of ~/Games/roms (nes, snes, gb, gbc, gba, genesis, sms,
psx); a PlayStation BIOS you own goes in ~/Games/bios . The Windows stick is not
visible from inside the VM, so games are added from Linux. After adding games,
run "bash make-playlists.sh" to build the lists.

Open it from the "RetroArch (emulators)" desktop icon, or the Games menu. Full
notes: system/docs/EMULATION.md.


-------------------------------------------------------------------------------
  PASTE FROM WINDOWS INTO THE VM
-------------------------------------------------------------------------------

A native two-way clipboard is not available with this QEMU-Windows build. The
kit works around it: it TYPES the Windows clipboard into the VM through a local
loopback channel (127.0.0.1 only, no network, no admin).

1. Start the VM (Play or Desktop mode).
2. In Windows, copy the text (Ctrl+C).
3. In the VM, click the target field (terminal, address bar).
4. Open "Media Center.cmd" again and choose [3] Paste clipboard into the VM.

Keyboard must be US inside the VM. One-way only (Windows -> VM); non-ASCII
characters are skipped. Full details: system/docs/CLIPBOARD.md.


-------------------------------------------------------------------------------
  TROUBLESHOOTING AND LIMITS
-------------------------------------------------------------------------------

- WHPX missing: check UEFI virtualization, Windows Hypervisor Platform and a
  reboot. "profile" accepts auto, whpx or tcg in system/config/settings.json.
- Steam dependencies: close Synaptic, then
  sudo dpkg --add-architecture i386; sudo add-apt-repository -y multiverse;
  sudo apt update; sudo apt install steam-installer . Stop if the repo update
  fails. The script does these steps.
- Black screen after install: a hang was seen on the installer's restart. Prefer
  shutdown, then [1] Play without the ISO. Ctrl+Alt+2 opens the QEMU monitor;
  "system_powerdown" requests a clean stop. "quit" is a last resort (not clean).
  Ctrl+Alt+1 returns to the display.
- Gamepad: automatic pass-through from Windows is not implemented or validated;
  RetroArch is playable on the keyboard meanwhile.
- RetroArch ROMs: add them from inside the VM (the Windows stick is not mounted
  there); heavy systems need a real GPU. See system/docs/EMULATION.md.
- Network: user-mode NAT without TAP; LAN discovery by broadcast may be limited.
  No inbound Windows port is opened by the scripts.
- Launch-on-plug: not included. A plain storage stick does not auto-run.
- Personal data: never publish your VM, your sessions, or screenshots/logs that
  contain accounts.
- Performance (CPU-bound decoding): see system/docs/PERFORMANCE.md.


-------------------------------------------------------------------------------
  VERSION TRACKING
-------------------------------------------------------------------------------

The workflow (.github/workflows/upstream-versions.yml) reads the official
Firefox/Steam versions every Monday at 10:23 UTC, updates
system/versions/upstream.json and proposes a PR on change. No auto-merge, no
image rebuild, no automatic VM update. Details: system/docs/GITHUB.md.

Scanner tests: python -m unittest discover -s system/tests
Manual scan:   python system/scripts/scan-upstream.py

Independent project, not affiliated with Valve, Mozilla, Canonical or QEMU.
Projects reviewed and technical choices: system/docs/RESEARCH.md.
