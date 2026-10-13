# Retro gaming with RetroArch

The setup script `linux/install-retroarch.sh` (run by `prepare-persistent.sh`)
installs **RetroArch** and a small set of **libretro cores**, pre-configured for
this VM. It ships the **player only** — no games, no BIOS. You add your own,
legally obtained content.

## What works here (and what does not)

The VM renders in **software (llvmpipe)**: there is **no GPU**. That decides what
is playable:

| Systems | Verdict |
|---|---|
| NES, SNES, Game Boy / GBC / GBA, Genesis / Mega Drive / Master System / Game Gear | Smooth (2D, CPU only) |
| PlayStation 1 (`pcsx_rearmed`) | Usually playable |
| N64, PSP, Saturn, Dreamcast | Often too slow |
| PS2, GameCube, Wii, Switch (PCSX2, Dolphin...) | Not playable (needs a real GPU) |

Cores installed by default: `fceumm` (NES), `snes9x` (SNES), `gambatte` (GB/GBC),
`mgba` (GBA), `genesis_plus_gx` (Genesis/MD/SMS/GG), `pcsx_rearmed` (PS1).

## Pre-tuned settings (why)

Written to `~/.config/retroarch/retroarch.cfg` before first launch:

- `menu_driver = "rgui"` — a **software-drawn** menu. The default XMB menu is
  GPU-heavy and crawls in llvmpipe; rgui is light and instant.
- `video_driver = "sdl2"` — a pure software blit. The default `gl` driver does
  NOT work in this VM: with no GPU (llvmpipe) it fails to create a GL context
  (`GLX BadAccess` on `X_GLXMakeContextCurrent`) and RetroArch exits instantly.
  SDL2 avoids GL entirely.
- `video_threaded = "true"` — decouples emulation from the video thread.
- `video_shader_enable = "false"`, `video_smooth = "false"` — no shaders, crisp
  nearest-neighbour pixels; both save CPU.
- `rewind_enable = "false"`, `run_ahead_enabled = "false"` — these are expensive
  and would hurt a CPU-bound VM.
- `video_fullscreen = "true"` — launches fullscreen (toggle with **F**).
- Paths point at `~/Games`: `roms`, `saves`, `states`, `bios`.

## Simple menu and game lists (for newcomers)

`linux/make-playlists.sh` turns RetroArch into a one-click experience:

- **Kiosk menu** (`kiosk_mode_enable`): the technical options are hidden, so a
  new user cannot break the setup. To unlock it, set
  `kiosk_mode_enable = "false"` in `~/.config/retroarch/retroarch.cfg`.
- **One list per system**, each game launching with the right core in a single
  click (no core picking).

Run it once after adding games (it is safe to re-run any time):

    bash make-playlists.sh

It also runs automatically at the end of the install.

## Adding games (ROMs)

The Windows USB stick is **not mounted inside the VM** (the VM's storage is the
virtual disk `vm/linux.vmdk`). So games are added **from inside Linux**:

1. In the VM, download your legally-owned ROM with **Firefox**, or copy it in by
   any means available inside Linux.
2. Put the file in the matching sub-folder of `~/Games/roms`:
   `nes/ snes/ gb/ gbc/ gba/ genesis/ sms/ psx/`
3. Run `bash make-playlists.sh`, then open RetroArch: the game is in its list.
   (You can still use **Load Content** to browse manually.)

Mind the disk: the virtual disk is about **10 GiB**, shared with the OS and
Steam. Small cartridge ROMs are nothing; a few PS1 discs add up fast. Check free
space with `df -h /`.

> Want ROMs to live on the stick and be filled from Windows? That needs a
> host↔VM shared folder (9p/virtiofs), which is unreliable on QEMU-Windows and
> is not set up here. It is a candidate for a later version.

## BIOS

Some systems need a BIOS file **you own** (PlayStation 1 does). Put it in
`~/Games/bios`. RetroArch names the exact file it expects in the core's log and
in *Information → Core Information*.

## Controls

- **Keyboard** works out of the box. In RetroArch, defaults: arrows = D-pad,
  `X`/`Z` = main buttons, `Enter`/`Shift` = Start/Select, `F1` = in-game menu,
  `F` = fullscreen, `Esc` = quit. Remap under *Settings → Input*.
- **Gamepad**: automatic USB pass-through from Windows is **not implemented** in
  this kit, so a controller plugged into the Windows host is not seen by the VM
  yet. Keyboard play works meanwhile.

## Adding more cores

RetroArch → **Online Updater → Core Downloader** pulls any core from the libretro
buildbot (already set as the source). Remember the no-GPU limit before grabbing
heavy ones.

## Legal

RetroArch and the cores are free and open source. Games (ROMs) and console BIOS
files are copyrighted: this kit never ships or downloads them. Use only content
you are legally entitled to.
