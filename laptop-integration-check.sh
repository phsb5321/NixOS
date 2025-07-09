#!/usr/bin/env bash
# Laptop Integration Status Check
# This script verifies that the laptop configuration is properly integrated

echo "============================================================================"
echo "LAPTOP NIXOS INTEGRATION STATUS CHECK"
echo "============================================================================"
echo

# System Information
echo "🖥️  SYSTEM INFORMATION"
echo "──────────────────────"
echo "Hostname: $(hostname)"
echo "NixOS Version: $(nixos-version)"
echo "Kernel: $(uname -r)"
echo "Desktop: $XDG_CURRENT_DESKTOP"
echo "Session: $XDG_SESSION_DESKTOP"
echo

# Flake Configuration
echo "📦 FLAKE CONFIGURATION"
echo "──────────────────────"
cd /home/notroot/NixOS
if nix flake check --no-build &>/dev/null; then
    echo "✅ Flake validation: PASSED"
else
    echo "❌ Flake validation: FAILED"
fi

if nix flake show | grep -q "nixosConfigurations.laptop"; then
    echo "✅ Laptop configuration: EXISTS"
else
    echo "❌ Laptop configuration: MISSING"
fi
echo

# Module Status
echo "🔧 MODULE STATUS"
echo "────────────────"

# Core modules
echo "Core Modules:"
if systemctl is-active pipewire &>/dev/null; then
    echo "  ✅ PipeWire: ACTIVE"
else
    echo "  ❌ PipeWire: INACTIVE"
fi

if fc-list | grep -q "JetBrainsMono"; then
    echo "  ✅ Fonts: CONFIGURED"
else
    echo "  ❌ Fonts: MISSING"
fi

if flatpak --version &>/dev/null; then
    echo "  ✅ Flatpak: AVAILABLE"
else
    echo "  ❌ Flatpak: MISSING"
fi

# Desktop modules
echo "Desktop Modules:"
if systemctl --user is-active gnome-session-manager &>/dev/null; then
    echo "  ✅ GNOME: ACTIVE"
else
    echo "  ⚠️  GNOME: CHECK REQUIRED"
fi

if pgrep gdm &>/dev/null; then
    echo "  ✅ GDM: RUNNING"
else
    echo "  ❌ GDM: NOT RUNNING"
fi

# Networking
echo "Network Modules:"
if systemctl is-active NetworkManager &>/dev/null; then
    echo "  ✅ NetworkManager: ACTIVE"
else
    echo "  ❌ NetworkManager: INACTIVE"
fi

echo

# Home Manager Integration
echo "🏠 HOME MANAGER INTEGRATION"
echo "───────────────────────────"

HM_GENERATION=$(home-manager generations | head -n1 | awk '{print $5}' 2>/dev/null)
if [[ -n "$HM_GENERATION" ]]; then
    echo "✅ Home Manager: ACTIVE (Generation: $HM_GENERATION)"
else
    echo "⚠️  Home Manager: No generations found"
fi

# Check critical programs
echo "User Programs:"
programs=("zsh" "starship" "kitty" "nvim" "git" "eza" "bat" "fzf" "ripgrep")
for prog in "${programs[@]}"; do
    if command -v "$prog" &>/dev/null; then
        echo "  ✅ $prog: $(which "$prog")"
    else
        echo "  ❌ $prog: NOT FOUND"
    fi
done

echo

# Configuration Files
echo "📄 CONFIGURATION FILES"
echo "──────────────────────"

config_files=(
    "$HOME/.zshrc"
    "$HOME/.config/kitty/kitty.conf" 
    "$HOME/.config/starship.toml"
    "$HOME/.gitconfig"
)

for file in "${config_files[@]}"; do
    if [[ -L "$file" ]]; then
        echo "  ✅ $file: LINKED"
    elif [[ -f "$file" ]]; then
        echo "  ⚠️  $file: EXISTS (not symlinked)"
    else
        echo "  ❌ $file: MISSING"
    fi
done

echo

# Services Status
echo "🔄 SERVICES STATUS"
echo "─────────────────"

services=("NetworkManager" "gdm" "pipewire" "polkit")
for service in "${services[@]}"; do
    if systemctl is-active "$service" &>/dev/null; then
        echo "  ✅ $service: ACTIVE"
    else
        echo "  ❌ $service: INACTIVE"
    fi
done

echo

# User Environment
echo "🌍 USER ENVIRONMENT"
echo "──────────────────"
echo "SHELL: $SHELL"
echo "PATH: $PATH" | head -c 100 && echo "..."
echo "EDITOR: ${EDITOR:-Not set}"
echo "Home Directory: $HOME"

echo

# Integration Summary
echo "📊 INTEGRATION SUMMARY"
echo "─────────────────────"

total_checks=0
passed_checks=0

# Count successful integrations
if nix flake check --no-build &>/dev/null; then ((passed_checks++)); fi
((total_checks++))

if command -v zsh &>/dev/null && [[ "$SHELL" == *"zsh"* ]]; then ((passed_checks++)); fi
((total_checks++))

if [[ -L "$HOME/.zshrc" ]]; then ((passed_checks++)); fi
((total_checks++))

if systemctl is-active NetworkManager &>/dev/null; then ((passed_checks++)); fi
((total_checks++))

if [[ "$XDG_CURRENT_DESKTOP" == "GNOME" ]]; then ((passed_checks++)); fi
((total_checks++))

percentage=$((passed_checks * 100 / total_checks))

echo "Integration Status: $passed_checks/$total_checks checks passed ($percentage%)"

if [[ $percentage -ge 90 ]]; then
    echo "🎉 EXCELLENT: Laptop integration is working perfectly!"
elif [[ $percentage -ge 70 ]]; then
    echo "✅ GOOD: Laptop integration is mostly working"
elif [[ $percentage -ge 50 ]]; then
    echo "⚠️  FAIR: Laptop integration needs attention"
else
    echo "❌ POOR: Laptop integration has major issues"
fi

echo
echo "============================================================================"
