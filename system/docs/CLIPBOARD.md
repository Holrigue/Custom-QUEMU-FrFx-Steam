# Paste from Windows into the VM

A real two-way clipboard is **not available** with this QEMU-Windows build:

- **GTK + agent (spice-vdagent)**: GTK's clipboard integration is an experimental feature **disabled by default** when QEMU is compiled (risk of hangs). The weilnetz build does not have it, so pasting does nothing even with the agent running inside the VM.
- **SPICE (`-display spice-app`)**: the SPICE server **fails to initialize** on Windows with this build ("Failed to open SPICE sockets").

## The workaround: "Paste into the VM" (Windows -> VM)

Without native sync, the tool **types** the Windows clipboard into the active VM window through a local control channel. One-way (Windows -> VM), which covers the main need: pasting **commands / URLs**.

### Security (work environment)
- The channel is a **`127.0.0.1` (loopback only)** socket, never exposed to the network.
- **No install, no admin rights, no system change, no firewall rule**: just two user processes (QEMU + a script) talking locally.
- Opened by the **Play** and **Desktop mode** launcher options (`-Control`), loopback only.

### How to use
1. Start the VM from **`Media Center.cmd`** (Play or Desktop mode). The local control channel is active in both.
2. In Windows, **copy** the text you want (Ctrl+C).
3. In the VM, **click the target field** (terminal, address bar...) so it has focus.
4. Open **`Media Center.cmd`** again and choose **Paste clipboard into the VM**: the text is typed into the VM.

### Keyboard requirement: US
Typing assumes a **US** layout in the VM (character -> US key mapping). If the VM is set to CA/FR, symbols will be wrong.
- Quick (per session), in a terminal: `setxkbmap us`.
- Permanent: Settings -> Keyboard -> Layout -> add **English (US)** and move it first (keep CA as secondary if you need to type French; switch with the layout shortcut).

### Limits
- **One-way**: no VM -> Windows copy through this tool.
- **Non-ASCII** characters (accents e a ...) are skipped -- rare in commands/URLs.
- The channel is open in **gaming mode** too, but pasting is mostly a desktop need: in SDL fullscreen there is no handy field to paste into. Use **Desktop mode** for the clipboard.
