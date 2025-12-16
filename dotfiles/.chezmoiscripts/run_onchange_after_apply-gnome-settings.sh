#!/bin/bash
# Apply GNOME dconf settings from dotfiles
# This script runs whenever GNOME config files change

CONFIG_DIR="${HOME}/.config/gnome"

echo "Applying GNOME settings from dotfiles..."

# Check if running in a GNOME session
if [ "$XDG_CURRENT_DESKTOP" != "GNOME" ]; then
  echo "Not running in GNOME session, skipping..."
  exit 0
fi

# Apply mutter performance settings (VRR, frame pacing)
if [ -f "${CONFIG_DIR}/mutter-performance.dconf" ]; then
  echo "→ Applying mutter performance settings..."
  dconf load /org/gnome/mutter/ < "${CONFIG_DIR}/mutter-performance.dconf"
fi

# Apply desktop power settings
if [ -f "${CONFIG_DIR}/desktop-power.dconf" ]; then
  echo "→ Applying desktop power settings..."
  dconf load / < "${CONFIG_DIR}/desktop-power.dconf"
fi

# Apply keyboard shortcuts
if [ -f "${CONFIG_DIR}/keybindings.dconf" ]; then
  echo "→ Applying keyboard shortcuts..."
  dconf load / < "${CONFIG_DIR}/keybindings.dconf"
fi

# Apply theme settings
if [ -f "${CONFIG_DIR}/theming.dconf" ]; then
  echo "→ Applying theme settings..."
  dconf load /org/gnome/desktop/interface/ < "${CONFIG_DIR}/theming.dconf"
fi

echo "✓ GNOME settings applied successfully!"
echo "Note: Some changes may require logging out and back in to take full effect."
echo "To restart GNOME Shell: Press Alt+F2, type 'r', and press Enter"
