#!/usr/bin/env bash

# ~/NixOS/user-scripts/gnome-fixes-test.sh
# 🎯 GNOME FIXES VERIFICATION SCRIPT
# Tests all the implemented fixes for Gnome accent colors, fonts, emojis, and rendering

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Icons
CHECK="✅"
CROSS="❌"
WARNING="⚠️"
INFO="ℹ️"
ROCKET="🚀"
GEAR="⚙️"
EMOJI="😀"

echo -e "${BLUE}${ROCKET} GNOME FIXES VERIFICATION SCRIPT${NC}"
echo -e "${CYAN}Testing all implemented fixes for Gnome issues...${NC}"
echo ""

# Function to check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to test result
test_result() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}${CHECK} $2${NC}"
    return 0
  else
    echo -e "${RED}${CROSS} $2${NC}"
    return 1
  fi
}

# Function to test with warning
test_warning() {
  echo -e "${YELLOW}${WARNING} $1${NC}"
}

# Function to show info
show_info() {
  echo -e "${CYAN}${INFO} $1${NC}"
}

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

run_test() {
  local test_name="$1"
  local test_command="$2"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  show_info "Testing: $test_name"

  if eval "$test_command" >/dev/null 2>&1; then
    test_result 0 "$test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "$test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
  echo ""
}

echo -e "${PURPLE}${GEAR} 1. ENVIRONMENT VARIABLES TEST${NC}"
echo "=============================================="

# Test GSK_RENDERER
if [ "${GSK_RENDERER:-}" = "gl" ]; then
  test_result 0 "GSK_RENDERER set to 'gl' (fixes artifacts)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "GSK_RENDERER not set to 'gl' (may cause artifacts)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test GNOME_DISABLE_EMOJI_PICKER
if [ "${GNOME_DISABLE_EMOJI_PICKER:-}" = "0" ]; then
  test_result 0 "GNOME_DISABLE_EMOJI_PICKER set to '0' (emoji picker enabled)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_warning "GNOME_DISABLE_EMOJI_PICKER not set to '0' (emoji picker may be disabled)"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test XCURSOR_THEME
if [ "${XCURSOR_THEME:-}" = "Adwaita" ]; then
  test_result 0 "XCURSOR_THEME set to 'Adwaita'"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "XCURSOR_THEME not set to 'Adwaita'"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo -e "${PURPLE}${GEAR} 2. FONT INSTALLATION TEST${NC}"
echo "=========================================="

# Test Noto Color Emoji
run_test "Noto Color Emoji font installed" "fc-list | grep -q 'Noto Color Emoji'"

# Test Symbols Nerd Font
run_test "Symbols Nerd Font installed" "fc-list | grep -q 'Symbols Nerd Font'"

# Test JetBrains Mono Nerd Font
run_test "JetBrains Mono Nerd Font installed" "fc-list | grep -q 'JetBrainsMono Nerd Font'"

# Test Inter font
run_test "Inter font installed" "fc-list | grep -q 'Inter'"

# Test Cantarell font
run_test "Cantarell font installed" "fc-list | grep -q 'Cantarell'"

echo ""
echo -e "${PURPLE}${GEAR} 3. FONTCONFIG TEST${NC}"
echo "================================="

# Test emoji font fallback
show_info "Testing emoji font fallback..."
EMOJI_MATCH=$(fc-match emoji 2>/dev/null | head -1)
if echo "$EMOJI_MATCH" | grep -q -E "(Noto Color Emoji|Twemoji|OpenMoji)"; then
  test_result 0 "Emoji font fallback configured: $EMOJI_MATCH"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "Emoji font fallback not properly configured: $EMOJI_MATCH"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test monospace font fallback
show_info "Testing monospace font fallback..."
MONO_MATCH=$(fc-match monospace 2>/dev/null | head -1)
if echo "$MONO_MATCH" | grep -q -E "(JetBrainsMono|Nerd Font|Cascadia|Ubuntu Mono)"; then
  test_result 0 "Monospace font fallback configured: $MONO_MATCH"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "Monospace font fallback not optimal: $MONO_MATCH"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test sans-serif font fallback
show_info "Testing sans-serif font fallback..."
SANS_MATCH=$(fc-match sans-serif 2>/dev/null | head -1)
if echo "$SANS_MATCH" | grep -q -E "(Inter|Ubuntu|Cantarell|Noto Sans)"; then
  test_result 0 "Sans-serif font fallback configured: $SANS_MATCH"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "Sans-serif font fallback not optimal: $SANS_MATCH"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo -e "${PURPLE}${GEAR} 4. GNOME SERVICES TEST${NC}"
echo "==================================="

# Test if GNOME is running
if [ "${XDG_CURRENT_DESKTOP:-}" = "GNOME" ] || [ "${DESKTOP_SESSION:-}" = "gnome" ]; then
  test_result 0 "GNOME desktop session detected"
  TESTS_PASSED=$((TESTS_PASSED + 1))

  # Test GNOME Shell
  if pgrep -x "gnome-shell" >/dev/null; then
    test_result 0 "GNOME Shell running"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "GNOME Shell not running"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Test GDM
  if systemctl is-active --quiet gdm; then
    test_result 0 "GDM service active"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "GDM service not active"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  TOTAL_TESTS=$((TOTAL_TESTS + 3))
else
  test_warning "Not running in GNOME session - skipping GNOME-specific tests"
  TOTAL_TESTS=$((TOTAL_TESTS + 3))
  TESTS_FAILED=$((TESTS_FAILED + 3))
fi

echo ""
echo -e "${PURPLE}${GEAR} 5. XDG PORTAL TEST${NC}"
echo "==============================="

# Test xdg-desktop-portal-gnome
if systemctl --user is-active --quiet xdg-desktop-portal >/dev/null 2>&1; then
  test_result 0 "XDG Desktop Portal service running"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "XDG Desktop Portal service not running"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

# Test portal configuration
if [ -f /etc/xdg/xdg-desktop-portal/portals.conf ] || [ -f ~/.config/xdg-desktop-portal/portals.conf ]; then
  test_result 0 "XDG Portal configuration found"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  test_result 1 "XDG Portal configuration not found"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo -e "${PURPLE}${GEAR} 6. DCONF SETTINGS TEST${NC}"
echo "===================================="

if command_exists dconf; then
  # Test accent color setting
  ACCENT_COLOR=$(dconf read /org/gnome/desktop/interface/accent-color 2>/dev/null || echo "not set")
  if [ "$ACCENT_COLOR" != "not set" ] && [ "$ACCENT_COLOR" != "" ]; then
    test_result 0 "Accent color configured: $ACCENT_COLOR"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "Accent color not configured"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Test cursor theme
  CURSOR_THEME=$(dconf read /org/gnome/desktop/interface/cursor-theme 2>/dev/null || echo "not set")
  if echo "$CURSOR_THEME" | grep -q "Adwaita"; then
    test_result 0 "Cursor theme set to Adwaita: $CURSOR_THEME"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "Cursor theme not set to Adwaita: $CURSOR_THEME"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  # Test font settings
  INTERFACE_FONT=$(dconf read /org/gnome/desktop/interface/font-name 2>/dev/null || echo "not set")
  if echo "$INTERFACE_FONT" | grep -q -E "(Inter|Ubuntu|Cantarell)"; then
    test_result 0 "Interface font configured: $INTERFACE_FONT"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    test_result 1 "Interface font not optimally configured: $INTERFACE_FONT"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi

  TOTAL_TESTS=$((TOTAL_TESTS + 3))
else
  test_warning "dconf command not available - skipping dconf tests"
  TOTAL_TESTS=$((TOTAL_TESTS + 3))
  TESTS_FAILED=$((TESTS_FAILED + 3))
fi

echo ""
echo -e "${PURPLE}${GEAR} 7. EMOJI RENDERING TEST${NC}"
echo "===================================="

# Create a test file with emojis and symbols
TEST_FILE="/tmp/gnome_emoji_test.txt"
cat >"$TEST_FILE" <<'EOF'
🎯 Emoji Test: 😀 🚀 ❤️ 🔥 ✅ ⚠️ 📱 🖥️
🔤 Nerd Font Symbols:      
📁 File icons and symbols
🎨 Colors and themes work
EOF

show_info "Created emoji test file: $TEST_FILE"

# Test if emoji file can be displayed
if command_exists gnome-text-editor; then
  show_info "You can test emoji rendering by opening: gnome-text-editor $TEST_FILE"
elif command_exists gedit; then
  show_info "You can test emoji rendering by opening: gedit $TEST_FILE"
else
  show_info "Open the test file $TEST_FILE in any text editor to verify emoji rendering"
fi

# Test character map availability
if command_exists gucharmap; then
  test_result 0 "Character Map (gucharmap) available for emoji testing"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  show_info "Run 'gucharmap' to browse available emojis and symbols"
else
  test_result 1 "Character Map (gucharmap) not available"
  TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo -e "${PURPLE}${GEAR} 8. TROUBLESHOOTING COMMANDS${NC}"
echo "=========================================="

echo -e "${CYAN}Useful commands for further testing:${NC}"
echo ""
echo -e "${YELLOW}Font debugging:${NC}"
echo "  fc-list | grep -i emoji          # List installed emoji fonts"
echo "  fc-list | grep -i nerd           # List installed Nerd Fonts"
echo "  fc-match emoji                   # Show emoji font fallback"
echo "  fc-match monospace               # Show monospace font fallback"
echo "  fc-cache -fv                     # Refresh font cache"
echo ""
echo -e "${YELLOW}GNOME debugging:${NC}"
echo "  dconf read /org/gnome/desktop/interface/accent-color    # Check accent color"
echo "  dconf read /org/gnome/desktop/interface/cursor-theme    # Check cursor theme"
echo "  dconf read /org/gnome/desktop/interface/font-name       # Check interface font"
echo "  gsettings list-schemas | grep interface                 # List interface schemas"
echo ""
echo -e "${YELLOW}Environment debugging:${NC}"
echo "  echo \$GSK_RENDERER                   # Should be 'gl'"
echo "  echo \$GNOME_DISABLE_EMOJI_PICKER     # Should be '0'"
echo "  echo \$XCURSOR_THEME                  # Should be 'Adwaita'"
echo ""
echo -e "${YELLOW}Process debugging:${NC}"
echo "  ps aux | grep gnome-shell             # Check GNOME Shell process"
echo "  systemctl --user status xdg-desktop-portal    # Check XDG portal"
echo "  journalctl --user -u xdg-desktop-portal -f    # Monitor portal logs"

echo ""
echo -e "${BLUE}${ROCKET} TEST RESULTS SUMMARY${NC}"
echo "=================================="
echo -e "Total tests run: ${CYAN}$TOTAL_TESTS${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
  echo ""
  echo -e "${GREEN}${CHECK} ALL TESTS PASSED! Your GNOME setup should be working correctly.${NC}"
  echo -e "${CYAN}${EMOJI} Emojis, fonts, accent colors, and rendering should all work properly now!${NC}"
  exit 0
elif [ $TESTS_PASSED -gt $TESTS_FAILED ]; then
  echo ""
  echo -e "${YELLOW}${WARNING} Some tests failed, but most functionality should work.${NC}"
  echo -e "${CYAN}Check the failed tests above and use the troubleshooting commands.${NC}"
  exit 1
else
  echo ""
  echo -e "${RED}${CROSS} Many tests failed. Your GNOME setup may need attention.${NC}"
  echo -e "${CYAN}Please review the configuration and run 'nixos-rebuild switch' if needed.${NC}"
  exit 2
fi
