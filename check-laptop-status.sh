#!/usr/bin/env bash

echo "=== NixOS Laptop Configuration Status ==="
echo

echo "1. System Information:"
echo "   Hostname: $(hostname)"
echo "   NixOS Version: $(nixos-version)"
echo "   Current Generation: $(nix-env --list-generations | tail -1)"
echo

echo "2. Desktop Environment:"
echo "   Display Manager: $(systemctl is-active gdm)"
echo "   GNOME Session: $(pgrep gnome-session > /dev/null && echo "Running" || echo "Not Running")"
echo

echo "3. Home Manager Status:"
echo "   User: $(whoami)"
echo "   Home Directory: $HOME"
echo "   ZSH Available: $(which zsh 2>/dev/null || echo "Not in PATH")"
echo "   Starship Available: $(which starship 2>/dev/null || echo "Not in PATH")"
echo "   Kitty Available: $(which kitty 2>/dev/null || echo "Not in PATH")"
echo

echo "4. Core Services:"
echo "   SSH: $(systemctl is-active sshd)"
echo "   NetworkManager: $(systemctl is-active NetworkManager)"
echo "   PipeWire: $(systemctl --user is-active pipewire)"
echo "   Bluetooth: $(systemctl is-active bluetooth)"
echo

echo "5. Module Status (checking if modules are loaded):"
echo "   Flatpak: $(which flatpak > /dev/null && echo "Available" || echo "Not Available")"
echo "   Firefox: $(which firefox > /dev/null && echo "Available" || echo "Not Available")"
echo

echo "6. Home Manager Files:"
ls -la ~/.config/ | head -10
echo

echo "=== Status Check Complete ==="
