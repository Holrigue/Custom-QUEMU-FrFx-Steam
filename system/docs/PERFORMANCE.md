# Remote Play performance inside the VM

The VM has no GPU: rendering is **software (llvmpipe)** and, above all, the Remote Play stream's **H.264 decoding runs on the CPU**. That is the real bottleneck. "thread starvation" warnings in the Steam console mean the CPU is short on time.

## Applied / recommended settings

### 1. More vCPUs (config)
`config/settings.json`: `"cpus": 8` (was 4). Software decoding and llvmpipe are multi-threaded and benefit from cores. Tested on a 16-core / 24-thread host (i7-13700F). Takes effect at the **next start** (Play / Desktop mode), not live.

Do not raise `memoryMiB` above 4096 if the host has little free RAM: Windows-side swapping would slow everything down. **Closing Windows apps before playing** is often the easiest win.

### 2. In-guest optimizations -- `linux/optimize-gaming.sh`
Run once in the VM's Xfce session:
```bash
bash optimize-gaming.sh
```
- disables **xfwm4 compositing** (frees CPU, reduces tearing/latency);
- disables **screen sleep/blanking** while playing;
- makes these settings **permanent** through an autostart entry.

Live equivalent (without the script), in a VM terminal:
```bash
xfconf-query -c xfwm4 -p /general/use_compositing -s false; xset s off; xset -dpms
```

### 3. Steam Remote Play settings
Starting point: **720p, 60 fps, H.264, 10 Mbit/s**, with detailed stats (advanced options). Go up to 1080p only if CPU decoding keeps up (watch the stats: decode time, dropped frames). A lower resolution = less decoding load.

### 4. On the Windows host
- Close heavy apps (RAM/CPU) before a session.
- If the camera feels too fast: disable "Enhance pointer precision" (Control Panel -> Mouse -> Pointer Options).
