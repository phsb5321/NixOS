#!/usr/bin/env bash
# ~/NixOS/user-scripts/setup-kitty-default.sh
# Script to set up Kitty as the default terminal in GNOME

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running in GNOME
check_gnome() {
  if [[ "${XDG_CURRENT_DESKTOP:-}" != *"GNOME"* ]]; then
    print_error "This script is designed for GNOME desktop environment"
    print_error "Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
    exit 1
  fi
  print_success "Running in GNOME desktop environment"
}

# Check if Kitty is installed
check_kitty() {
  if ! command -v kitty &>/dev/null; then
    print_error "Kitty is not installed or not in PATH"
    exit 1
  fi

  local kitty_version
  kitty_version=$(kitty --version | head -n1)
  print_success "Kitty found: $kitty_version"
}

# Set up GNOME terminal default
setup_gnome_terminal_default() {
  print_status "Setting up GNOME terminal preferences..."

  # Set default terminal application
  gsettings set org.gnome.desktop.default-applications.terminal exec 'kitty'
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''

  print_success "GNOME default terminal set to Kitty"
}

# Set up XDG terminal configuration (for newer Ubuntu/GNOME versions)
setup_xdg_terminal() {
  print_status "Setting up XDG terminal configuration..."

  local config_dir="$HOME/.config"
  mkdir -p "$config_dir"

  # Create terminal priority lists
  for list in "xdg-terminals.list" "ubuntu-xdg-terminals.list" "gnome-xdg-terminals.list"; do
    cat >"$config_dir/$list" <<EOF
kitty.desktop
gnome-terminal.desktop
org.gnome.Console.desktop
EOF
    print_success "Created $config_dir/$list"
  done
}

# Set up desktop integration
setup_desktop_integration() {
  print_status "Setting up desktop integration..."

  # Create applications directory if it doesn't exist
  local apps_dir="$HOME/.local/share/applications"
  mkdir -p "$apps_dir"

  # Check if kitty.desktop exists in system locations
  local desktop_file=""
  for dir in "/usr/share/applications" "/usr/local/share/applications" "$apps_dir"; do
    if [[ -f "$dir/kitty.desktop" ]]; then
      desktop_file="$dir/kitty.desktop"
      break
    fi
  done

  if [[ -n "$desktop_file" ]]; then
    print_success "Found Kitty desktop file: $desktop_file"
  else
    print_warning "Kitty desktop file not found in standard locations"
  fi

  # Update desktop database
  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$apps_dir" 2>/dev/null || true
    print_success "Updated desktop database"
  fi
}

# Configure keyboard shortcuts
configure_shortcuts() {
  print_status "Configuring keyboard shortcuts..."

  # Set Ctrl+Alt+T to open Kitty
  # Note: This might not work in all GNOME versions due to security restrictions
  local custom_shortcut_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$custom_shortcut_path']"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$custom_shortcut_path name 'Kitty Terminal'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$custom_shortcut_path command 'kitty'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$custom_shortcut_path binding '<Primary><Alt>t'

  print_success "Configured Ctrl+Alt+T to open Kitty"
}

# Test terminal integration
test_integration() {
  print_status "Testing terminal integration..."

  # Test gsettings
  local current_terminal
  current_terminal=$(gsettings get org.gnome.desktop.default-applications.terminal exec)
  if [[ "$current_terminal" == "'kitty'" ]]; then
    print_success "GNOME terminal setting: $current_terminal"
  else
    print_warning "GNOME terminal setting: $current_terminal (expected 'kitty')"
  fi

  # Test XDG terminal lists
  for list in "xdg-terminals.list" "ubuntu-xdg-terminals.list" "gnome-xdg-terminals.list"; do
    local file="$HOME/.config/$list"
    if [[ -f "$file" ]] && head -n1 "$file" | grep -q "kitty.desktop"; then
      print_success "XDG terminal list $list: kitty.desktop is first"
    else
      print_warning "XDG terminal list $list: issue detected"
    fi
  done

  # Test if xdg-terminal-exec exists (Ubuntu 25.04+)
  if command -v xdg-terminal-exec &>/dev/null; then
    print_success "xdg-terminal-exec found (modern terminal switching supported)"
  else
    print_warning "xdg-terminal-exec not found (older system)"
  fi
}

# Display usage instructions
show_usage_instructions() {
  cat <<EOF

${GREEN}═══════════════════════════════════════════════════════════════════════════════${NC}
${GREEN}                        KITTY SETUP COMPLETE!                                  ${NC}
${GREEN}═══════════════════════════════════════════════════════════════════════════════${NC}

${BLUE}How to use Kitty as your main terminal:${NC}

${YELLOW}1. Keyboard Shortcuts:${NC}
   • Ctrl+Alt+T       - Open new Kitty window
   • Ctrl+Shift+T     - New tab
   • Ctrl+Shift+W     - Close tab
   • Ctrl+Shift+N     - New window
   • F11              - Toggle fullscreen
   • Ctrl+Shift+C/V   - Copy/Paste

${YELLOW}2. Right-click Integration:${NC}
   • Right-click folders in Files (Nautilus)
   • Select "Open in Terminal" - should open Kitty

${YELLOW}3. Application Launcher:${NC}
   • Press Super key and type "kitty"
   • Or click Activities and find Kitty

${YELLOW}4. Advanced Features:${NC}
   • Shell integration enabled (command output navigation)
   • Ligature support for coding fonts
   • GPU acceleration for smooth performance
   • Wayland optimization for GNOME
   • Dark/Light theme automatic switching

${YELLOW}5. Configuration:${NC}
   • Config managed by NixOS Home Manager
   • Manual config: ~/.config/kitty/kitty.conf
   • Theme switches with GNOME dark/light preference

${BLUE}Troubleshooting:${NC}
   • Restart GNOME Shell: Alt+F2, type 'r', press Enter
   • Log out and back in to refresh all integrations
   • Check: gsettings get org.gnome.desktop.default-applications.terminal exec

${GREEN}Enjoy your supercharged terminal experience! 🚀${NC}

EOF
}

# Main execution
main() {
  echo
  print_status "Setting up Kitty as default terminal in GNOME..."
  echo

  check_gnome
  check_kitty
  echo

  setup_gnome_terminal_default
  setup_xdg_terminal
  setup_desktop_integration
  configure_shortcuts
  echo

  test_integration
  echo

  show_usage_instructions
}

# Run main function
main "$@"
