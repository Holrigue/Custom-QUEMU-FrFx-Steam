# Observed results -- 2026-09-28

| Test | Dev Windows 11 PC | PC 2 |
|---|---|---|
| QEMU extracted without install, ordinary FAT32 16 GB stick | Desktop reached | Not tested |
| WHPX | Init and desktop validated | Not tested |
| TCG | Live used, heavy slowness; gameplay not measured | Not tested |
| Split disk, writing past 4 GiB | Dedicated write/read-back succeeded | Not tested |
| Linux installed | User desktop reached via Play | Not tested |
| Steam and i386 dependencies | Install completed, Remote Play used | Not tested |
| Remote Play | Very smooth per user; resolution, FPS and network not recorded | Not tested |
| LAN then another Internet network | Separate scenarios not documented | Not tested |
| Firefox | Version 156.0.1 + HTTPS validated live; final system not verified | Not tested |
| Absolute mouse | Desktop normal, in-game camera too fast | Not tested |
| Relative mouse | QMP absolute=false confirmed; gameplay to retest | Not tested |
| Audio, keyboard, gamepad | No separate validation recorded; gamepad not implemented | Not tested |
| Clean shutdown/reboot/full persistence | To confirm; installer restart hang observed | Not tested |
| Timed boot | Live WHPX desktop captured at 110 s, not an exact measure | Not tested |

On each of the two PCs: note CPU/RAM/Windows/medium/profile/network; time the launch to desktop, then Steam ready. Test WHPX and TCG without hiding a show-stopping slowness. Stream the same game for ten minutes at 720p/60 and record stats (bitrate, loss, latency, decode) and feel. Separately check sound, keyboard, camera and gamepad if supported. Repeat from another Internet network; 1080p/60 only if satisfactory. Shut down, eject, re-plug, check persistence. A planned test is not a passed test.
