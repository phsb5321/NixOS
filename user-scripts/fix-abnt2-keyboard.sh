#!/usr/bin/env bash

# Quick fix script for ABNT2 keyboard layout
# Run this script if your keyboard layout gets reset to US

echo "🔧 Fixing ABNT2 keyboard layout..."

# Apply X11 keyboard layout
setxkbmap -layout br -variant abnt2 -option "grp:alt_shift_toggle,compose:ralt"

# Apply GNOME settings
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br+abnt2')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle', 'compose:ralt']"

echo "✅ ABNT2 keyboard layout applied!"
echo ""

# Show current status
echo "Current keyboard layout:"
setxkbmap -query | grep -E "(layout|variant|options)"
echo ""

echo "🧪 Test your keyboard now:"
echo "- Try typing: Ç ã õ á é í ó ú"
echo "- Try AltGr+c for ç"
echo "- Use dead keys: ´a=á, ~a=ã, ^e=ê"
