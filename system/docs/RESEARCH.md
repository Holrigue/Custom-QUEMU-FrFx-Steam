# Technical choices -- reviewed 28 September 2026

| Project | Relevant capability | Limit for this prototype |
|---|---|---|
| [QEMU](https://www.qemu.org/download/) and [docs](https://www.qemu.org/docs/master/system/invocation.html) | TCG emulation, Windows WHPX acceleration, persistent disk image, user-mode NAT and virtual devices | CPU acceleration does not guarantee GPU/video decoding; Windows binaries provided by an officially referenced third party. Real portability must be tested on each PC. |
| [dockerportable](https://github.com/knockshore/dockerportable) | Useful idea: self-contained tree, local paths, portable QEMU and Linux disk | Docker/Alpine example, not a graphical Steam station. The repo reviewed is not a complete Remote Play deliverable. No code reused. |
| [TinyUSB](https://docs.tinyusb.org/en/latest/) | HID keyboard and MSC storage classes, examples and wide microcontroller support | A USB stack does not provide memory large/fast enough for a VM. The mount's capacity, throughput and firmware must be measured. |
| [Portable-VirtualBox](https://github.com/vboxme/Portable-VirtualBox) | Portable packaging of VirtualBox | Its README mentions NAT issues and a rollback to 7.0.20. Host drivers and privileges remain a concern; not chosen for a guaranteed install-free launch on every PC. No VirtualBox test performed. |

Distribution: [Xubuntu 24.04 LTS](https://xubuntu.org/release/24.04/) with [Steam multiverse](https://packages.ubuntu.com/noble/steam-installer). [Official images](https://cdimage.ubuntu.com/xubuntu/releases/24.04/release/). Intended use: [Steam Remote Play](https://store.steampowered.com/remoteplay).

Extracted Windows version: QEMU 11.1.0, package `v11.1.0-12130-ge470268ff4`, installer `qemu-w64-setup-20260811.exe`. The selected version is available from [Stefan Weil](https://qemu.weilnetz.de/w64/); this is not a claim that all upstream QEMU patches are included. SHA512 checksum verified before extraction.

## Phase 3: deferred

FAT32 storage: [QEMU documents the split VMDK format](https://qemu-project.gitlab.io/qemu/system/images.html). The prototype uses `twoGbMaxExtentSparse` to avoid reformatting the test medium. Keep all segments together.

No keyboard injection, no firmware, no launch-on-plug enabled. Precondition: phase 1 validated with usable streaming, persistence and clean shutdown.

Preliminary comparison only: A (storage + HID on a single microcontroller) concentrates storage throughput, capacity and robustness constraints; B (a single-socket hub with standard storage and a separate HID controller) splits these functions and seems more reliable. The final choice and the hardware list wait for phase 1 results, per the mandate. The ordinary USB stick stays the first medium.

After validation: detect volumes and look for a unique project marker (`STEAM-USB-ID.txt`), require a single match, then resolve the launcher relative to the marker. Never rely on the volume name or D: alone. A physical arming switch, a cancelable delay and a disable file will be needed. Account for the Quebec keyboard layout. No bypassing of a locked screen, corporate policy or UAC.
