#!/usr/bin/env bash
# Makes RetroArch newcomer-friendly and builds the game lists (playlists).
# Run as the desktop user, any time (especially after adding ROMs):
#   bash make-playlists.sh
#
# It does three things, all idempotent and offline:
#   1) sets a simple "kiosk" menu that hides the technical options;
#   2) ensures ~/Games/roms/<system>/ folders exist (drop your ROMs there);
#   3) builds one list per system; each game launches in a single click with
#      the right core (no core picking).
# It ships NO games and NO BIOS files: add only content you legally own.
set -euo pipefail
if [ "$EUID" -eq 0 ]; then echo 'Run as the desktop user, without sudo: bash make-playlists.sh'; exit 1; fi

cfgdir="$HOME/.config/retroarch"
cfg="$cfgdir/retroarch.cfg"
cores="$cfgdir/cores"
pl="$cfgdir/playlists"
roms="$HOME/Games/roms"
mkdir -p "$cfgdir" "$cores" "$pl" "$HOME/Games/saves" "$HOME/Games/states" "$HOME/Games/bios"
[ -f "$cfg" ] || : > "$cfg"

# 1) Simple "kiosk" menu. cfgset replaces a key if present, else appends it.
cfgset(){ local k="$1" v="$2"
    if grep -q "^$k = " "$cfg"; then sed -i "s|^$k = .*|$k = \"$v\"|" "$cfg"
    else printf '%s = "%s"\n' "$k" "$v" >> "$cfg"; fi; }
cfgset kiosk_mode_enable true
cfgset menu_show_load_core false
cfgset menu_show_online_updater false
cfgset menu_show_core_updater false
cfgset menu_show_information false
cfgset menu_show_configurations false
cfgset menu_show_help false
cfgset content_show_netplay false
cfgset content_show_images false
cfgset content_show_music false
cfgset content_show_video false
cfgset content_show_favorites true
cfgset content_show_history true

# 2) + 3) Per-system folders and lists.
# Fields:  official system name | sub-folder | core | file extensions
systems=(
"Nintendo - Nintendo Entertainment System|nes|fceumm|nes fds unif unf"
"Nintendo - Super Nintendo Entertainment System|snes|snes9x|sfc smc snes"
"Nintendo - Game Boy|gb|gambatte|gb"
"Nintendo - Game Boy Color|gbc|gambatte|gbc"
"Nintendo - Game Boy Advance|gba|mgba|gba"
"Sega - Mega Drive - Genesis|genesis|genesis_plus_gx|md smd gen bin"
"Sega - Master System - Mark III|sms|genesis_plus_gx|sms"
"Sony - PlayStation|psx|pcsx_rearmed|cue chd pbp"
)

# Minimal JSON string escaping (handles backslash and double-quote).
jesc(){ printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

built=0
for row in "${systems[@]}"; do
    IFS='|' read -r name sub core exts <<< "$row"
    dir="$roms/$sub"
    mkdir -p "$dir"
    corepath="$cores/${core}_libretro.so"
    lpl="$pl/$name.lpl"
    # Gather matching files (case-insensitive extensions).
    files=()
    while IFS= read -r f; do [ -n "$f" ] && files+=("$f"); done < <(
        for e in $exts; do find "$dir" -maxdepth 1 -type f -iname "*.$e" 2>/dev/null; done | sort -u )
    if [ "${#files[@]}" -eq 0 ]; then
        rm -f "$lpl"   # no empty lists, keep the menu clean
        continue
    fi
    {
        printf '{\n'
        printf '  "version": "1.5",\n'
        printf '  "default_core_path": "%s",\n' "$(jesc "$corepath")"
        printf '  "default_core_name": "%s",\n' "$(jesc "$name")"
        printf '  "label_display_mode": 0,\n'
        printf '  "right_thumbnail_mode": 3,\n'
        printf '  "left_thumbnail_mode": 0,\n'
        printf '  "sort_mode": 0,\n'
        printf '  "items": [\n'
        last=$(( ${#files[@]} - 1 )); i=0
        for f in "${files[@]}"; do
            label=$(basename "$f"); label="${label%.*}"
            printf '    {\n'
            printf '      "path": "%s",\n' "$(jesc "$f")"
            printf '      "label": "%s",\n' "$(jesc "$label")"
            printf '      "core_path": "DETECT",\n'
            printf '      "core_name": "DETECT",\n'
            printf '      "crc32": "DETECT",\n'
            printf '      "db_name": "%s.lpl"\n' "$(jesc "$name")"
            if [ "$i" -eq "$last" ]; then printf '    }\n'; else printf '    },\n'; fi
            i=$((i+1))
        done
        printf '  ]\n'
        printf '}\n'
    } > "$lpl"
    echo "  list: $name (${#files[@]} game(s))"
    built=$((built+1))
done

echo
if [ "$built" -eq 0 ]; then
    echo 'Simple menu ready. No games found yet.'
    echo "Drop your ROMs into the matching folder under: $roms"
    echo '  nes/  snes/  gb/  gbc/  gba/  genesis/  sms/  psx/'
    echo 'then run this again:  bash make-playlists.sh'
else
    echo "$built game list(s) built. Launch RetroArch and pick a game from the list."
fi
echo 'Reminder: this ships no games and no BIOS; add only content you legally own.'
