#!/usr/bin/env bash

# NixOS Comprehensive Maintenance Script
# Performs updates, cleanup, and optimization

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to print headers
print_header() {
    echo ""
    print_color "${BOLD}${BLUE}" "═══════════════════════════════════════════════════════════════════"
    print_color "${BOLD}${CYAN}" "  $1"
    print_color "${BOLD}${BLUE}" "═══════════════════════════════════════════════════════════════════"
    echo ""
}

# Function to calculate and display disk space saved
calculate_space_saved() {
    local before=$1
    local after=$2
    local saved=$((before - after))
    local saved_gb=$(echo "scale=2; $saved / 1024 / 1024" | bc)

    if [ "$saved" -gt 0 ]; then
        print_color "${GREEN}" "✅ Space freed: ${saved_gb} GB"
    else
        print_color "${YELLOW}" "ℹ️  No additional space freed"
    fi
}

# Start maintenance
print_header "🚀 NixOS System Maintenance Starting"
print_color "${CYAN}" "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"

# Get initial disk usage
INITIAL_SPACE=$(df / --output=used | tail -n 1)
print_color "${CYAN}" "Initial disk usage: $(echo "scale=2; $INITIAL_SPACE / 1024 / 1024" | bc) GB"

# Step 1: Update flake inputs
print_header "1️⃣  Updating Flake Inputs"
if nix flake update; then
    print_color "${GREEN}" "✅ Flake inputs updated successfully"
else
    print_color "${YELLOW}" "⚠️  Flake update completed with warnings"
fi

# Step 2: Rebuild NixOS configuration
print_header "2️⃣  Rebuilding NixOS Configuration"
print_color "${YELLOW}" "This will apply all package updates and configuration changes..."

if sudo nixos-rebuild switch --flake .#default; then
    print_color "${GREEN}" "✅ System rebuild successful"
else
    print_color "${RED}" "❌ System rebuild failed - check the output above"
    exit 1
fi

# Step 3: List and clean old system generations
print_header "3️⃣  Managing System Generations"

# Show current generations
print_color "${CYAN}" "Current system generations:"
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Keep only the last 3 generations
print_color "${YELLOW}" "Keeping only the last 3 system generations..."
sudo nix-env --delete-generations +3 --profile /nix/var/nix/profiles/system 2>/dev/null || true

# Step 4: Clean user profile generations
print_header "4️⃣  Cleaning User Profile Generations"
print_color "${YELLOW}" "Cleaning old user generations..."

# Clean user generations (keep last 3)
nix-env --delete-generations +3 2>/dev/null || true

# Clean home-manager generations if it exists
if command -v home-manager &>/dev/null; then
    print_color "${CYAN}" "Cleaning home-manager generations..."
    home-manager generations | tail -n +4 | awk '{print $5}' | xargs -r home-manager remove-generations 2>/dev/null || true
fi

# Step 5: Run garbage collection
print_header "5️⃣  Running Nix Garbage Collection"
print_color "${YELLOW}" "Removing unreferenced packages and derivations..."

# Run garbage collection with aggressive options
if sudo nix-collect-garbage -d; then
    print_color "${GREEN}" "✅ Garbage collection completed"
else
    print_color "${YELLOW}" "⚠️  Garbage collection completed with warnings"
fi

# Additional user-level garbage collection
nix-collect-garbage -d

# Step 6: Clean build cache and temporary files
print_header "6️⃣  Cleaning Build Cache and Temporary Files"

# Clean Nix build logs
print_color "${CYAN}" "Cleaning old build logs..."
if [ -d "/nix/var/log/nix/drvs" ]; then
    sudo find /nix/var/log/nix/drvs -type f -mtime +7 -delete 2>/dev/null || true
    print_color "${GREEN}" "✅ Old build logs cleaned"
fi

# Clean temporary files
print_color "${CYAN}" "Cleaning system temporary files..."
sudo find /tmp -type f -atime +7 -delete 2>/dev/null || true
sudo find /var/tmp -type f -atime +7 -delete 2>/dev/null || true

# Clean Nix daemon temp files
if [ -d "/nix/var/nix/temproots" ]; then
    sudo find /nix/var/nix/temproots -type f -mtime +1 -delete 2>/dev/null || true
fi

# Step 7: Clean system logs and journals
print_header "7️⃣  Managing System Logs"

# Rotate and vacuum systemd journals
print_color "${CYAN}" "Vacuuming systemd journals (keeping last 2 weeks)..."
sudo journalctl --vacuum-time=2w
sudo journalctl --vacuum-size=500M

# Clean old system logs
print_color "${CYAN}" "Cleaning old system logs..."
sudo find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
sudo find /var/log -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true

# Step 8: Optimize Nix store
print_header "8️⃣  Optimizing Nix Store"
print_color "${YELLOW}" "Deduplicating files in Nix store (this may take a while)..."

if sudo nix-store --optimise; then
    print_color "${GREEN}" "✅ Nix store optimized"
else
    print_color "${YELLOW}" "⚠️  Store optimization completed with warnings"
fi

# Step 9: Clean package caches
print_header "9️⃣  Cleaning Package Caches"

# Clean npm cache if it exists
if command -v npm &>/dev/null; then
    print_color "${CYAN}" "Cleaning npm cache..."
    npm cache clean --force 2>/dev/null || true
fi

# Clean cargo cache if it exists
if [ -d "$HOME/.cargo/registry/cache" ]; then
    print_color "${CYAN}" "Cleaning cargo cache..."
    rm -rf "$HOME/.cargo/registry/cache" 2>/dev/null || true
fi

# Clean pip cache if it exists
if command -v pip &>/dev/null; then
    print_color "${CYAN}" "Cleaning pip cache..."
    pip cache purge 2>/dev/null || true
fi

# Clean flatpak if it exists
if command -v flatpak &>/dev/null; then
    print_color "${CYAN}" "Cleaning flatpak unused runtimes..."
    flatpak uninstall --unused -y 2>/dev/null || true
fi

# Step 10: Final verification and report
print_header "📊 Maintenance Summary"

# Get final disk usage
FINAL_SPACE=$(df / --output=used | tail -n 1)
FINAL_SPACE_GB=$(echo "scale=2; $FINAL_SPACE / 1024 / 1024" | bc)

# Calculate space saved
calculate_space_saved "$INITIAL_SPACE" "$FINAL_SPACE"

# Show current disk usage
print_color "${CYAN}" "Final disk usage: ${FINAL_SPACE_GB} GB"

# Show filesystem usage
print_color "${CYAN}" "\nFilesystem usage summary:"
df -h / /boot /home 2>/dev/null | grep -v "Filesystem" | while read line; do
    echo "  $line"
done

# Show Nix store size
if [ -d "/nix/store" ]; then
    STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1)
    print_color "${CYAN}" "\nNix store size: $STORE_SIZE"
fi

# Show number of store paths
STORE_PATHS=$(find /nix/store -maxdepth 1 -type d | wc -l)
print_color "${CYAN}" "Number of store paths: $STORE_PATHS"

# Show current generation
CURRENT_GEN=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}')
print_color "${CYAN}" "Current system generation: $CURRENT_GEN"

# Final message
print_header "✨ Maintenance Complete!"
print_color "${GREEN}" "Your NixOS system has been updated and optimized."
print_color "${YELLOW}" "\n💡 Tips:"
print_color "${NC}" "  • Reboot if kernel was updated: ${CYAN}sudo reboot${NC}"
print_color "${NC}" "  • Check for errors in journal: ${CYAN}journalctl -p err -b${NC}"
print_color "${NC}" "  • View system changes: ${CYAN}nixos-rebuild list-generations${NC}"

# Check if reboot is recommended (kernel update)
CURRENT_KERNEL=$(uname -r)
CONFIGURED_KERNEL=$(nix eval --raw .#nixosConfigurations.default.config.boot.kernelPackages.kernel.version 2>/dev/null || echo "unknown")

if [ "$CURRENT_KERNEL" != "$CONFIGURED_KERNEL" ] && [ "$CONFIGURED_KERNEL" != "unknown" ]; then
    print_color "${YELLOW}" "\n⚠️  Kernel update detected! Reboot recommended to use new kernel."
fi

exit 0