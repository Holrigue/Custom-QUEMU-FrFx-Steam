# Relative-mouse trial for Steam Remote Play

Reported symptom: the desktop feels normal, but the in-game camera is far too fast. Hypothesis: the USB-tablet absolute device being converted through QEMU/Steam. Cause unconfirmed until the same game is retested.

`config/settings.json` now uses `"mouseMode": "relative"`: QEMU exposes `usb-mouse` instead of `usb-tablet`. Do not change Windows/Linux/in-game sensitivity during the first trial, to isolate this change.

1. Shut down Linux from its menu, wait for QEMU to close.
2. Start **Play** again from `Media Center.cmd`. A plain internal Linux reboot does not change the QEMU devices.
3. Click inside the VM display; use **Ctrl+Alt+G** to grab input if needed (View > Grab Input).
4. Try the same game over Remote Play and compare slow turns, fast turns, and continuous movement.
5. **Ctrl+Alt+G** releases mouse and keyboard back to Windows.

Rollback: change `"relative"` back to `"absolute"` in `mouseMode`, shut down Linux, then start Play again. The desktop gets its integrated absolute pointer back. This change does not touch the Linux disk or Steam settings.

## Gaming mode (confirmed)

Trial result: with a normal start (Desktop mode, **GTK** display), even with `Ctrl+Alt+G` grab, the mouse **escaped the window on the left/right edges** and moved to the second monitor. This is a known limit of QEMU's GTK grab on multi-monitor Windows (`ClipCursor` does not hold).

Confirmed fix: use the **Play** option (the launcher's `-Gaming` switch). This mode:

- uses the **SDL** display (`-display sdl,gl=off`) instead of GTK: SDL uses Windows' native *pointer lock* (a relative mode that continuously recenters the cursor), which **confines the mouse reliably**, including on multi-monitor setups;
- starts in **fullscreen** (`-full-screen`) on the current monitor;
- forces the **relative mouse** (`usb-mouse`) whatever `mouseMode` is set to.

Workflow:

1. Shut down Linux cleanly, wait for QEMU to close.
2. Choose **Play**. Steam starts on its own (autostart `steam -silent`).
3. Launch the game in Remote Play, **click inside the window** to engage the grab (the cursor disappears = locked).
4. Check: the mouse stays confined, even on fast moves toward the edges.
5. **Ctrl+Alt+G** releases the mouse; **Ctrl+Alt+F** leaves fullscreen.

Reported result: side escape **fixed**, camera controllable. For desktop use (browsing Steam, settings), Desktop mode (GTK) is still handier because the pointer integrates without a grab.

Still to tune if the camera feels too fast: disable "Enhance pointer precision" on the Windows side (stacked acceleration) and lower in-game sensitivity.

### Fullscreen sharpness (resolution)

In gaming mode, the VGA exposes an EDID forcing **1920x1080** as the preferred mode (`-device VGA,edid=on,xres=1920,yres=1080`), so a fresh guest boots straight into 1080p: **crisp 1:1** fullscreen, without the blurry upscaling of a stretched 1280x800. A `-vga virtio` trial was dropped: it did not fix sharpness (Xfce does not reapply the resize) and caused the **cursor to stick in the corner** (coordinate offset). `std` + EDID is more reliable.

Limit: a guest that has **already remembered** a lower resolution (e.g. 1280x800 from a first session) keeps it despite the EDID. One-time, persistent fix: **Settings -> Display -> 1920x1080 -> Apply**. Adjust the value if the monitor is not 1080p.

Sources: https://www.qemu.org/docs/master/system/devices/usb.html and https://www.qemu.org/docs/master/system/keys.html .
