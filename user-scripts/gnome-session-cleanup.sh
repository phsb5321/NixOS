#!/usr/bin/env bash
# GNOME Session Cleanup Script for NixOS 25.05
# Fixes the gnome-session wrapper "-l" flag error

set -euo pipefail

echo "=== GNOME Session Cleanup Script ==="
echo "This script fixes corrupted GNOME session files that cause the '-l' flag error"
echo

# Function to backup and clean saved session
cleanup_saved_session() {
  local session_dir="$HOME/.config/gnome-session/saved-session"
  local backup_dir="$HOME/.config/gnome-session/saved-session.backup-$(date +%Y%m%d-%H%M%S)"

  if [ -d "$session_dir" ]; then
    echo "📁 Found saved session directory: $session_dir"

    # Check for problematic entries
    if find "$session_dir" -name "*.desktop" -exec grep -l "Exec.*-l" {} \; 2>/dev/null | head -1 >/dev/null; then
      echo "⚠️  Found corrupted session files with '-l' flag"

      # Create backup
      echo "💾 Creating backup: $backup_dir"
      cp -r "$session_dir" "$backup_dir"

      # Remove corrupted session
      echo "🧹 Removing corrupted saved session"
      rm -rf "$session_dir"

      echo "✅ Corrupted session cleaned up"
    else
      echo "✅ No corrupted session files found"
    fi
  else
    echo "ℹ️  No saved session directory found"
  fi
}

# Function to clean autostart entries
cleanup_autostart() {
  local autostart_dir="$HOME/.config/autostart"

  if [ -d "$autostart_dir" ]; then
    echo "📁 Checking autostart directory: $autostart_dir"

    # Look for problematic autostart entries
    if find "$autostart_dir" -name "*.desktop" -exec grep -l "Exec.*-l" {} \; 2>/dev/null | head -1 >/dev/null; then
      echo "⚠️  Found problematic autostart entries"

      # Backup autostart
      local autostart_backup="$autostart_dir.backup-$(date +%Y%m%d-%H%M%S)"
      echo "💾 Creating autostart backup: $autostart_backup"
      cp -r "$autostart_dir" "$autostart_backup"

      # Remove problematic entries
      find "$autostart_dir" -name "*.desktop" -exec grep -l "Exec.*-l" {} \; -delete 2>/dev/null || true

      echo "✅ Autostart cleaned up"
    else
      echo "✅ No problematic autostart entries found"
    fi
  else
    echo "ℹ️  No autostart directory found"
  fi
}

# Function to verify Wayland session
verify_wayland() {
  echo "🔍 Verifying Wayland session setup..."

  if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
    echo "✅ Running Wayland session"
    echo "   Wayland Display: ${WAYLAND_DISPLAY:-not set}"
    echo "   GDK Backend: ${GDK_BACKEND:-not set}"
    echo "   Qt Platform: ${QT_QPA_PLATFORM:-not set}"
  else
    echo "⚠️  Not running Wayland session (current: ${XDG_SESSION_TYPE:-unknown})"
  fi
}

# Function to restart GDM (requires sudo)
restart_gdm() {
  if command -v systemctl &>/dev/null; then
    echo "🔄 Restarting GDM service (requires sudo)..."
    if sudo systemctl restart gdm; then
      echo "✅ GDM restarted successfully"
      echo "ℹ️  Please log out and log back in"
    else
      echo "❌ Failed to restart GDM"
    fi
  else
    echo "⚠️  systemctl not found, please restart GDM manually"
  fi
}

# Main execution
main() {
  echo "Starting GNOME session cleanup..."
  echo

  cleanup_saved_session
  echo

  cleanup_autostart
  echo

  verify_wayland
  echo

  # Ask user if they want to restart GDM
  if [ "${1:-}" != "--no-restart" ]; then
    read -p "Do you want to restart GDM now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      restart_gdm
    else
      echo "ℹ️  To apply changes, restart GDM with: sudo systemctl restart gdm"
    fi
  fi

  echo
  echo "🎉 Cleanup completed!"
  echo "If you continue to experience issues, check the troubleshooting guide:"
  echo "   - Clear browser cache if web apps don't start"
  echo "   - Run 'nixos-wayland-check' to verify Wayland setup"
  echo "   - Check logs with: journalctl -xb -u gdm"
}

# Help function
show_help() {
  cat <<EOF
GNOME Session Cleanup Script for NixOS 25.05

Usage: $0 [OPTIONS]

OPTIONS:
    --no-restart    Don't prompt to restart GDM
    --help          Show this help message

This script fixes the gnome-session wrapper "-l" flag error by:
1. Backing up and removing corrupted saved session files
2. Cleaning problematic autostart entries
3. Verifying Wayland session setup
4. Optionally restarting GDM service

The "-l" flag error occurs when GNOME tries to restore a corrupted
session file containing invalid command-line arguments.
EOF
}

# Parse arguments
case "${1:-}" in
--help | -h)
  show_help
  exit 0
  ;;
*)
  main "$@"
  ;;
esac
