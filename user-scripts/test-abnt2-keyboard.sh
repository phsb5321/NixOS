#!/usr/bin/env bash

# Test script for ABNT2 keyboard functionality
# This script helps verify that the Brazilian ABNT2 keyboard layout is working correctly

echo "🇧🇷 Brazilian ABNT2 Keyboard Test Script"
echo "========================================"
echo ""

# Check current keyboard layout
echo "Current X11 keyboard layout:"
setxkbmap -query | grep -E "(layout|variant|options)"
echo ""

# Check GNOME settings
echo "GNOME input sources:"
gsettings get org.gnome.desktop.input-sources sources
echo ""

echo "GNOME XKB options:"
gsettings get org.gnome.desktop.input-sources xkb-options
echo ""

echo "🧪 Manual Testing Instructions:"
echo "==============================="
echo ""
echo "Please test the following ABNT2-specific features:"
echo ""
echo "1. 🔤 Ç key: Press the Ç key (should produce: Ç)"
echo "2. 🔤 Dead acute: Press ´ then a (should produce: á)"
echo "3. 🔤 Dead tilde: Press ~ then a (should produce: ã)"
echo "4. 🔤 AltGr+c: Press Right Alt + c (should produce: ç)"
echo "5. 🔢 Numeric pad: Press . on numpad (should produce: ,)"
echo "6. 🔤 Other accents: Try ´e=é, \`a=à, ^e=ê, ~o=õ, ¨u=ü"
echo ""

echo "✅ If all tests pass, your ABNT2 keyboard is working correctly!"
echo "❌ If any test fails, run: setxkbmap -layout br -variant abnt2"
echo ""

echo "🔄 To apply keyboard layout immediately:"
echo "setxkbmap -layout br -variant abnt2 -option 'grp:alt_shift_toggle,compose:ralt'"
