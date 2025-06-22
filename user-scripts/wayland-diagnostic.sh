#!/usr/bin/env bash
# NixOS 25.05 Wayland Diagnostic Script
# Comprehensive system diagnosis for Wayland and GPU configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions for colored output
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo -e "${BLUE}=== NixOS 25.05 Wayland Diagnostic Script ===${NC}"
echo

# System Information
info "System Information"
echo "NixOS Version: $(nixos-version 2>/dev/null || echo 'Unknown')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Session Type: ${XDG_SESSION_TYPE:-not set}"
echo "Desktop Environment: ${XDG_CURRENT_DESKTOP:-not set}"
echo "Wayland Display: ${WAYLAND_DISPLAY:-not set}"
echo

# GPU Information
info "GPU Information"
if command -v lspci &>/dev/null; then
  echo "Graphics Cards:"
  lspci | grep -E "(VGA|3D|Display)" || echo "No graphics cards found"
else
  warning "lspci not available"
fi
echo

# Driver Information
info "Graphics Driver Information"
if [ -d "/sys/class/drm" ]; then
  echo "DRM devices:"
  ls -la /sys/class/drm/ | grep -E "card[0-9]" || echo "No DRM devices found"
  echo

  echo "Active connectors:"
  for connector in /sys/class/drm/*/status; do
    if [ -f "$connector" ]; then
      status=$(cat "$connector")
      name=$(basename "$(dirname "$connector")")
      if [ "$status" = "connected" ]; then
        success "$name: $status"
      else
        echo "$name: $status"
      fi
    fi
  done
else
  error "No DRM subsystem found"
fi
echo

# Wayland Session Check
info "Wayland Session Status"
if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
  success "Running Wayland session"
  echo "Environment variables:"
  echo "  WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"
  echo "  GDK_BACKEND: ${GDK_BACKEND:-not set}"
  echo "  QT_QPA_PLATFORM: ${QT_QPA_PLATFORM:-not set}"
  echo "  MOZ_ENABLE_WAYLAND: ${MOZ_ENABLE_WAYLAND:-not set}"
  echo "  NIXOS_OZONE_WL: ${NIXOS_OZONE_WL:-not set}"
  echo "  SDL_VIDEODRIVER: ${SDL_VIDEODRIVER:-not set}"
else
  error "Not running Wayland session (current: ${XDG_SESSION_TYPE:-unknown})"
fi
echo

# VAAPI Check
info "VAAPI (Video Acceleration) Status"
if command -v vainfo &>/dev/null; then
  if vainfo 2>/dev/null | head -10; then
    success "VAAPI available"
  else
    error "VAAPI not working"
  fi
else
  warning "vainfo not available (install libva-utils)"
fi
echo

# Vulkan Check
info "Vulkan Status"
if command -v vulkaninfo &>/dev/null; then
  vulkan_devices=$(vulkaninfo 2>/dev/null | grep -c "deviceName" || echo "0")
  if [ "$vulkan_devices" -gt 0 ]; then
    success "Vulkan available ($vulkan_devices device(s))"
    vulkaninfo 2>/dev/null | grep -E "(deviceName|driverInfo)" | head -4
  else
    error "No Vulkan devices found"
  fi
else
  warning "vulkaninfo not available (install vulkan-tools)"
fi
echo

# OpenGL Check
info "OpenGL Status"
if command -v glxinfo &>/dev/null; then
  if renderer=$(glxinfo 2>/dev/null | grep "OpenGL renderer"); then
    success "OpenGL available"
    echo "$renderer"
    glxinfo 2>/dev/null | grep "OpenGL version" || true
  else
    error "OpenGL not working"
  fi
else
  warning "glxinfo not available"
fi
echo

# GNOME Session Check
info "GNOME Session Status"
if pgrep -x gnome-shell >/dev/null; then
  success "GNOME Shell running"

  # Check for corrupted session files
  session_dir="$HOME/.config/gnome-session/saved-session"
  if [ -d "$session_dir" ]; then
    if find "$session_dir" -name "*.desktop" -exec grep -l "Exec.*-l" {} \; 2>/dev/null | head -1 >/dev/null; then
      error "Corrupted GNOME session files found (contains '-l' flag)"
      echo "  Run: gnome-session-cleanup.sh to fix"
    else
      success "No corrupted session files found"
    fi
  fi

  # Check GNOME version
  if command -v gnome-shell &>/dev/null; then
    gnome_version=$(gnome-shell --version 2>/dev/null || echo "Unknown")
    echo "GNOME version: $gnome_version"
  fi
else
  warning "GNOME Shell not running"
fi
echo

# Display Manager Check
info "Display Manager Status"
if systemctl is-active --quiet gdm; then
  success "GDM is active"

  # Check GDM Wayland support
  if systemctl show gdm -p ExecStart | grep -q wayland; then
    success "GDM configured for Wayland"
  else
    warning "GDM Wayland configuration unclear"
  fi
else
  if systemctl is-active --quiet sddm; then
    info "SDDM is active (KDE)"
  else
    error "No known display manager active"
  fi
fi
echo

# Audio System Check
info "Audio System Status"
if command -v pactl &>/dev/null; then
  if pactl info &>/dev/null; then
    audio_server=$(pactl info 2>/dev/null | grep "Server Name" | cut -d: -f2 | xargs)
    success "Audio system active: $audio_server"

    if echo "$audio_server" | grep -q "PipeWire"; then
      success "Using PipeWire (optimal for Wayland)"
    elif echo "$audio_server" | grep -q "PulseAudio"; then
      warning "Using PulseAudio (consider switching to PipeWire)"
    fi
  else
    error "Audio system not responding"
  fi
else
  warning "pactl not available"
fi
echo

# XDG Portal Check
info "XDG Portal Status"
if command -v busctl &>/dev/null; then
  portals=$(busctl --user list | grep "xdg.desktop.portal" | wc -l)
  if [ "$portals" -gt 0 ]; then
    success "XDG Portals active ($portals found)"
    busctl --user list | grep "xdg.desktop.portal" | head -5
  else
    error "No XDG Portals found"
  fi
else
  warning "busctl not available"
fi
echo

# Flatpak Check
info "Flatpak Status"
if command -v flatpak &>/dev/null; then
  if flatpak --version &>/dev/null; then
    success "Flatpak available"
    runtime_count=$(flatpak list --runtime 2>/dev/null | wc -l)
    app_count=$(flatpak list --app 2>/dev/null | wc -l)
    echo "  Runtimes: $runtime_count, Apps: $app_count"
  else
    error "Flatpak not working"
  fi
else
  info "Flatpak not installed"
fi
echo

# Performance Check
info "Performance Indicators"
if [ -f "/sys/kernel/mm/transparent_hugepage/enabled" ]; then
  thp_status=$(cat /sys/kernel/mm/transparent_hugepage/enabled)
  echo "Transparent Huge Pages: $thp_status"
fi

if command -v systemctl &>/dev/null; then
  failed_services=$(systemctl --failed --no-pager -q --no-legend | wc -l)
  if [ "$failed_services" -eq 0 ]; then
    success "No failed systemd services"
  else
    warning "$failed_services failed systemd services"
    echo "Run 'systemctl --failed' for details"
  fi
fi
echo

# Recommendations
info "Recommendations"
if [ "${XDG_SESSION_TYPE:-}" != "wayland" ]; then
  echo "• Switch to Wayland session at login screen"
fi

if ! command -v vainfo &>/dev/null; then
  echo "• Install libva-utils for video acceleration support"
fi

if ! command -v vulkaninfo &>/dev/null; then
  echo "• Install vulkan-tools for Vulkan diagnostics"
fi

if [ -d "$HOME/.config/gnome-session/saved-session" ]; then
  if find "$HOME/.config/gnome-session/saved-session" -name "*.desktop" -exec grep -l "Exec.*-l" {} \; 2>/dev/null | head -1 >/dev/null; then
    echo "• Run gnome-session-cleanup.sh to fix corrupted session files"
  fi
fi

echo
success "Diagnostic complete! Use this information to troubleshoot issues."
echo "For detailed logs, check: journalctl -xb -u gdm"
