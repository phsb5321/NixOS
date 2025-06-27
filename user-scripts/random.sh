#!/usr/bin/env bash

set -euo pipefail

# GNOME Diagnostic Script for NixOS
# Comprehensive troubleshooting and log collection

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
  echo -e "${BOLD}${CYAN}===========================================${NC}"
  echo -e "${BOLD}${CYAN}    GNOME Diagnostic Tool for NixOS${NC}"
  echo -e "${BOLD}${CYAN}===========================================${NC}"
  echo
}

print_section() {
  echo -e "${BOLD}${MAGENTA}📋 $1${NC}"
  echo -e "${BLUE}-------------------------------------------${NC}"
}

print_info() {
  echo -e "${CYAN}ℹ️  $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

# Create log directory
LOG_DIR="$HOME/.gnome-diagnostics"
mkdir -p "$LOG_DIR"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="$LOG_DIR/gnome-diagnostic-${TIMESTAMP}.log"

# Redirect all output to both console and log file
exec > >(tee -a "$REPORT_FILE")
exec 2>&1

print_header

# 1. System Information
print_section "System Information"
print_info "Current user: $(whoami)"
print_info "Hostname: $(hostname)"
print_info "Date: $(date)"
print_info "Uptime: $(uptime)"
echo

print_info "NixOS Version:"
nixos-version
echo

print_info "Kernel Version:"
uname -a
echo

# 2. Session Information
print_section "Session Information"
print_info "Desktop Session: ${XDG_CURRENT_DESKTOP:-Not set}"
print_info "Session Type: ${XDG_SESSION_TYPE:-Not set}"
print_info "Wayland Display: ${WAYLAND_DISPLAY:-Not set}"
print_info "X11 Display: ${DISPLAY:-Not set}"
print_info "GDK Backend: ${GDK_BACKEND:-Not set}"
print_info "QT Platform: ${QT_QPA_PLATFORM:-Not set}"
echo

print_info "Running Display Server:"
if pgrep -x "Xwayland" >/dev/null; then
  print_success "XWayland is running"
elif pgrep -x "Xorg" >/dev/null; then
  print_warning "X.Org is running (not Wayland)"
else
  print_error "No display server detected"
fi
echo

# 3. GNOME Process Status
print_section "GNOME Process Status"
processes=("gnome-shell" "gnome-session" "gsd-*" "gdm" "mutter")

for process in "${processes[@]}"; do
  if pgrep -f "$process" >/dev/null; then
    print_success "$process is running"
    pgrep -af "$process"
  else
    print_error "$process is NOT running"
  fi
  echo
done

# 4. Display Manager Status
print_section "Display Manager Status"
print_info "GDM Service Status:"
systemctl status gdm --no-pager -l || print_error "GDM service check failed"
echo

print_info "Display Manager Sessions:"
ls -la /run/user/$(id -u)/ 2>/dev/null || print_warning "Cannot access user runtime directory"
echo

# 5. GNOME Services Status
print_section "GNOME Services Status"
gnome_services=(
  "gnome-keyring-daemon"
  "gnome-settings-daemon"
  "evolution-data-server"
  "gvfs"
  "at-spi-bus-launcher"
)

for service in "${gnome_services[@]}"; do
  if pgrep -x "$service" >/dev/null; then
    print_success "$service is running"
  else
    print_error "$service is NOT running"
  fi
done
echo

# 6. Graphics Information
print_section "Graphics Information"
print_info "Graphics Card Information:"
lspci | grep -E "(VGA|3D|Display)" || print_warning "No graphics card info found"
echo

print_info "OpenGL Information:"
if command -v glxinfo >/dev/null; then
  glxinfo | head -20
else
  print_warning "glxinfo not available"
fi
echo

print_info "Wayland Compositor:"
if command -v weston-info >/dev/null; then
  weston-info | head -10
else
  print_warning "weston-info not available"
fi
echo

# 7. Audio System Status
print_section "Audio System Status"
print_info "PipeWire Status:"
if systemctl --user is-active pipewire >/dev/null 2>&1; then
  print_success "PipeWire is active"
  systemctl --user status pipewire --no-pager -l
else
  print_error "PipeWire is not active"
fi
echo

print_info "Audio Devices:"
if command -v pactl >/dev/null; then
  pactl list short sinks 2>/dev/null || print_warning "Cannot list audio sinks"
else
  print_warning "pactl not available"
fi
echo

# 8. XDG Portal Status
print_section "XDG Portal Status"
print_info "XDG Desktop Portal Status:"
if systemctl --user is-active xdg-desktop-portal >/dev/null 2>&1; then
  print_success "xdg-desktop-portal is active"
else
  print_error "xdg-desktop-portal is not active"
fi

if systemctl --user is-active xdg-desktop-portal-gnome >/dev/null 2>&1; then
  print_success "xdg-desktop-portal-gnome is active"
else
  print_error "xdg-desktop-portal-gnome is not active"
fi
echo

# 9. GNOME Extensions
print_section "GNOME Extensions"
print_info "Enabled Extensions:"
if command -v gnome-extensions >/dev/null; then
  gnome-extensions list --enabled 2>/dev/null || print_warning "Cannot list enabled extensions"
  echo
  print_info "Disabled Extensions:"
  gnome-extensions list --disabled 2>/dev/null || print_warning "Cannot list disabled extensions"
else
  print_warning "gnome-extensions command not available"
fi
echo

# 10. Theme and Settings
print_section "Theme and Settings"
print_info "Current GTK Theme:"
gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || print_warning "Cannot get GTK theme"

print_info "Current Icon Theme:"
gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || print_warning "Cannot get icon theme"

print_info "Current Cursor Theme:"
gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || print_warning "Cannot get cursor theme"
echo

# 11. Recent System Logs
print_section "Recent System Logs (Last 50 GNOME-related entries)"
journalctl --user -u gnome-session --since "1 hour ago" -n 50 --no-pager || print_warning "Cannot get gnome-session logs"
echo

print_section "Recent GDM Logs"
sudo journalctl -u gdm --since "1 hour ago" -n 50 --no-pager || print_warning "Cannot get GDM logs"
echo

# 12. Error Logs
print_section "Error Logs (Last 20 entries)"
journalctl -p err --since "1 hour ago" -n 20 --no-pager || print_warning "Cannot get error logs"
echo

# 13. GNOME Shell Logs
print_section "GNOME Shell Logs"
if [ -f "$HOME/.local/share/gnome-shell/extensions.log" ]; then
  print_info "Extensions Log (last 20 lines):"
  tail -20 "$HOME/.local/share/gnome-shell/extensions.log"
else
  print_warning "No extensions log found"
fi
echo

# 14. Crash Reports
print_section "Crash Reports"
if [ -d "/var/crash" ] && [ "$(ls -A /var/crash 2>/dev/null)" ]; then
  print_warning "Crash reports found:"
  ls -la /var/crash/
else
  print_success "No crash reports found"
fi
echo

# 15. Network and Connectivity
print_section "Network and Connectivity"
print_info "NetworkManager Status:"
systemctl status NetworkManager --no-pager -l || print_warning "NetworkManager status check failed"
echo

# 16. File System Issues
print_section "File System and Permissions"
print_info "Home Directory Permissions:"
ls -ld "$HOME"
print_info "XDG Runtime Directory:"
ls -la "/run/user/$(id -u)/" 2>/dev/null || print_warning "Cannot access XDG runtime directory"
echo

print_info "Disk Space:"
df -h / /home 2>/dev/null || print_warning "Cannot check disk space"
echo

# 17. Environment Variables
print_section "Environment Variables"
print_info "Relevant Environment Variables:"
env | grep -E "(XDG|GNOME|GTK|GDK|WAYLAND|DISPLAY)" | sort
echo

# 18. Hardware Issues
print_section "Hardware Information"
print_info "Memory Usage:"
free -h
echo

print_info "CPU Information:"
lscpu | head -10
echo

print_info "USB Devices:"
lsusb 2>/dev/null || print_warning "Cannot list USB devices"
echo

# 19. Configuration Files
print_section "Configuration Files Check"
config_files=(
  "$HOME/.config/gnome-session"
  "$HOME/.config/gtk-3.0"
  "$HOME/.config/gtk-4.0"
  "/etc/gdm"
)

for config in "${config_files[@]}"; do
  if [ -e "$config" ]; then
    print_success "$config exists"
    ls -la "$config" 2>/dev/null
  else
    print_warning "$config does not exist"
  fi
done
echo

# 20. Quick Fix Suggestions
print_section "Quick Fix Suggestions"
echo "Based on the diagnostic, try these common fixes:"
echo
echo "1. Restart GNOME Shell:"
echo "   Alt+F2 → type 'r' → Enter"
echo
echo "2. Reset GNOME settings:"
echo "   dconf reset -f /org/gnome/"
echo
echo "3. Restart user services:"
echo "   systemctl --user restart gnome-session"
echo
echo "4. Clear GNOME cache:"
echo "   rm -rf ~/.cache/gnome-shell/"
echo
echo "5. Check extensions:"
echo "   gnome-extensions list --enabled"
echo "   gnome-extensions disable <problematic-extension>"
echo
echo "6. Rebuild NixOS (if config issues):"
echo "   sudo nixos-rebuild switch"
echo

# Summary
print_section "Diagnostic Complete"
print_success "Diagnostic report saved to: $REPORT_FILE"
print_info "Please share this report when asking for help."
echo
print_info "To view the full report later:"
echo "cat $REPORT_FILE"
echo
