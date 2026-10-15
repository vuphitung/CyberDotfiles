#!/bin/bash
# ============================================================
# wall-picker.sh — PRISM TUI v4
# ============================================================

WALL_DIR="${CYBER_WALL_DIR:-$HOME/Pictures/Wallpapers}"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
THUMB_DIR="$HOME/.cache/prism-thumbs"
THUMB_SIZE="600x400"

# ── Deps ──────────────────────────────────────────────────
for dep in fzf kitty magick identify; do
    command -v "$dep" &>/dev/null || {
        echo "❌ Thiếu: $dep  (sudo pacman -S imagemagick fzf)"
        exit 1
    }
done

mkdir -p "$THUMB_DIR"

# ── Quét ảnh ─────────────────────────────────────────────
mapfile -t FILES < <(find "$WALL_DIR" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" \
       -o -iname "*.png" -o -iname "*.webp" \) | sort)

[ ${#FILES[@]} -eq 0 ] && { echo "❌ Kho ảnh trống: $WALL_DIR"; exit 1; }

# ── Gen thumbnail lần đầu ─────────────────────────────────
NEED_GEN=0
for f in "${FILES[@]}"; do
    HASH=$(md5sum <<< "$f" | cut -d' ' -f1)
    [ ! -f "$THUMB_DIR/$HASH.jpg" ] && (( NEED_GEN++ ))
done

if (( NEED_GEN > 0 )); then
    echo -e "\033[1;35m◆ PRISM\033[0m  gen $NEED_GEN thumbnails..."
    for f in "${FILES[@]}"; do
        HASH=$(md5sum <<< "$f" | cut -d' ' -f1)
        THUMB="$THUMB_DIR/$HASH.jpg"
        [ -f "$THUMB" ] && continue
        magick "$f" \
            -thumbnail "${THUMB_SIZE}^" \
            -gravity center -extent "$THUMB_SIZE" \
            -quality 88 "$THUMB" 2>/dev/null
    done
    echo -e "\033[1;32m✓ Done\033[0m"
fi

# ── List: "HASH\tNAME\tFULLPATH" (dùng tab, không dùng | ) ──
LIST_FILE=$(mktemp /tmp/prism-list.XXXXXX)
for f in "${FILES[@]}"; do
    HASH=$(md5sum <<< "$f" | cut -d' ' -f1)
    printf '%s\t%s\t%s\n' "$HASH" "$(basename "$f")" "$f"
done > "$LIST_FILE"

# ── Preview script ────────────────────────────────────────
PREVIEW_SCRIPT=$(mktemp /tmp/prism-prev.XXXXXX.sh)
cat > "$PREVIEW_SCRIPT" << PREVEOF
#!/bin/bash
LINE="\$1"
HASH="\$(cut -f1 <<< "\$LINE")"
NAME="\$(cut -f2 <<< "\$LINE")"
FULL="\$(cut -f3 <<< "\$LINE")"
THUMB="$THUMB_DIR/\${HASH}.jpg"
[ -f "\$THUMB" ] || THUMB="\$FULL"

W=\${FZF_PREVIEW_COLUMNS:-100}
H=\${FZF_PREVIEW_LINES:-40}

# Fill toàn bộ vùng preview — trừ 3 dòng info bên dưới
kitty icat \
    --clear \
    --transfer-mode=memory \
    --unicode-placeholder \
    --stdin=no \
    --scale-up \
    --place="\${W}x\$((H-3))@0x0" \
    "\$THUMB" 2>/dev/null

# Info bar — căn dưới
printf "\n"
RES=\$(identify "\$FULL" 2>/dev/null | grep -oP '\d+x\d+' | head -1)
SIZE=\$(du -h "\$FULL" 2>/dev/null | cut -f1)
printf "  \033[1;35m%-50s\033[0m \033[38;5;240m%s  %s\033[0m\n" "\$NAME" "\$RES" "\$SIZE"
PREVEOF
chmod +x "$PREVIEW_SCRIPT"

# ── fzf ──────────────────────────────────────────────────
TOTAL="${#FILES[@]}"
SELECTED=$(
    cat "$LIST_FILE" \
    | fzf \
        --prompt="  ◆  " \
        --pointer="▶" \
        --marker=" ◆" \
        --height=100% \
        --layout=reverse \
        --border=sharp \
        --border-label="  PRISM  ·  wallpapers: ${TOTAL}  " \
        --border-label-pos=top \
        --preview="bash $PREVIEW_SCRIPT {}" \
        --preview-window="right:70%:border-left:nowrap" \
        --color="bg:#0a0010,bg+:#200030,fg:#aa88cc,fg+:#ffffff" \
        --color="hl:#cc00ff,hl+:#ff66ff,border:#3d0060,label:#cc00ff" \
        --color="prompt:#cc00ff,pointer:#ff66ff,marker:#cc00ff,spinner:#cc00ff" \
        --color="preview-bg:#050008,preview-border:#3d0060" \
        --color="header:#440066,separator:#1a0028,info:#660099" \
        --with-nth=2 \
        --delimiter=$'\t' \
        --bind="ctrl-p:toggle-preview" \
        --bind="ctrl-r:reload(cat $LIST_FILE)" \
        --bind="alt-r:execute-silent(rm -rf $THUMB_DIR && mkdir -p $THUMB_DIR)+reload(cat $LIST_FILE)" \
        --header=$'  ctrl-p: preview  ·  enter: apply  ·  esc: quit\n' \
        --info=inline \
        --separator="─" \
        --scrollbar="▌"
)

# ── Cleanup ───────────────────────────────────────────────
rm -f "$PREVIEW_SCRIPT" "$LIST_FILE"
kitty icat --clear 2>/dev/null

# ── Apply ─────────────────────────────────────────────────
if [ -n "$SELECTED" ]; then
    FULL_PATH=$(cut -f3 <<< "$SELECTED")
    NAME=$(cut -f2 <<< "$SELECTED")
    echo -e "\033[1;35m◆ PRISM\033[0m  →  \033[0;37m$NAME\033[0m"
    "$SCRIPT_DIR/wallpaper.sh" "$FULL_PATH"
else
    echo -e "\033[38;5;240m  cancelled\033[0m"
fi
