#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║   FIX SYMLINKS — chạy 1 lần để sửa hết                 ║
# ╚══════════════════════════════════════════════════════════╝

DOT="$HOME/CyberDotfiles"

echo "▸ XÓA symlink sai bên trong dotfiles..."
rm -f "$DOT/config/hypr/hypr"
rm -f "$DOT/config/kitty/kitty"
rm -f "$DOT/config/rofi/rofi"
rm -f "$DOT/config/wlogout/wlogout"

echo "▸ TẠO symlink đúng vào ~/.config/..."
ln -sfn "$DOT/config/hypr"    "$HOME/.config/hypr"
ln -sfn "$DOT/config/kitty"   "$HOME/.config/kitty"
ln -sfn "$DOT/config/rofi"    "$HOME/.config/rofi"
ln -sfn "$DOT/config/wlogout" "$HOME/.config/wlogout"

echo "▸ TẠO thư mục nano + symlink nanorc..."
mkdir -p "$HOME/.config/nano"
ln -sf "$DOT/config/nano/nanorc" "$HOME/.config/nano/nanorc"

echo "▸ KIỂM TRA kết quả:"
for d in hypr kitty rofi wlogout; do
    target=$(readlink "$HOME/.config/$d" 2>/dev/null)
    if [[ "$target" == "$DOT/config/$d" ]]; then
        echo "  ✅ ~/.config/$d -> $target"
    else
        echo "  ❌ ~/.config/$d — SAI hoặc chưa tạo"
    fi
done

nanorc=$(readlink "$HOME/.config/nano/nanorc" 2>/dev/null)
if [[ -n "$nanorc" ]]; then
    echo "  ✅ ~/.config/nano/nanorc -> $nanorc"
else
    echo "  ❌ nanorc symlink lỗi"
fi

echo ""
echo "✅ Xong! Chạy: hyprctl reload"
