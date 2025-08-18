#!/usr/bin/env bash
# GNOME Theming Validation Script
# Tests accent colors, themes, and overall appearance after configuration changes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a GNOME session
check_gnome_session() {
    log_info "Checking GNOME session..."

    if [ "${XDG_CURRENT_DESKTOP:-}" != "GNOME" ]; then
        log_error "Not running in a GNOME session. Current desktop: ${XDG_CURRENT_DESKTOP:-unknown}"
        return 1
    fi

    if [ "${XDG_SESSION_DESKTOP:-}" != "gnome" ]; then
        log_warning "Session desktop is not GNOME: ${XDG_SESSION_DESKTOP:-unknown}"
    fi

    log_success "GNOME session detected"
    return 0
}

# Test dconf settings
test_dconf_settings() {
    log_info "Testing dconf settings..."

    # Test accent color
    local accent_color
    accent_color=$(gsettings get org.gnome.desktop.interface accent-color 2>/dev/null || echo "not set")
    if [ "$accent_color" = "'blue'" ]; then
        log_success "Accent color is correctly set to blue"
    else
        log_error "Accent color is not set correctly. Current: $accent_color"
    fi

    # Test color scheme
    local color_scheme
    color_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "not set")
    if [ "$color_scheme" = "'prefer-dark'" ]; then
        log_success "Color scheme is correctly set to dark mode"
    else
        log_warning "Color scheme is not set to dark mode. Current: $color_scheme"
    fi

    # Test GTK theme
    local gtk_theme
    gtk_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "not set")
    if [[ "$gtk_theme" == *"Adwaita-dark"* ]]; then
        log_success "GTK theme is correctly set to Adwaita-dark"
    else
        log_warning "GTK theme might not be set correctly. Current: $gtk_theme"
    fi

    # Test icon theme
    local icon_theme
    icon_theme=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "not set")
    if [[ "$icon_theme" == *"Adwaita"* ]]; then
        log_success "Icon theme is correctly set to Adwaita"
    else
        log_warning "Icon theme might not be set correctly. Current: $icon_theme"
    fi

    # Test cursor theme
    local cursor_theme
    cursor_theme=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo "not set")
    if [[ "$cursor_theme" == *"Adwaita"* ]]; then
        log_success "Cursor theme is correctly set to Adwaita"
    else
        log_warning "Cursor theme might not be set correctly. Current: $cursor_theme"
    fi

    # Test experimental features
    local experimental_features
    experimental_features=$(gsettings get org.gnome.mutter experimental-features 2>/dev/null || echo "not set")
    if [[ "$experimental_features" == *"scale-monitor-framebuffer"* ]]; then
        log_success "Experimental features are enabled (fractional scaling)"
    else
        log_warning "Experimental features might not be enabled. Current: $experimental_features"
    fi
}

# Test fonts
test_fonts() {
    log_info "Testing font configuration..."

    # Test main font
    local font_name
    font_name=$(gsettings get org.gnome.desktop.interface font-name 2>/dev/null || echo "not set")
    if [[ "$font_name" == *"Cantarell"* ]]; then
        log_success "System font is correctly set to Cantarell"
    else
        log_warning "System font might not be set correctly. Current: $font_name"
    fi

    # Test monospace font
    local monospace_font
    monospace_font=$(gsettings get org.gnome.desktop.interface monospace-font-name 2>/dev/null || echo "not set")
    if [[ "$monospace_font" == *"Source Code Pro"* ]]; then
        log_success "Monospace font is correctly set to Source Code Pro"
    else
        log_warning "Monospace font might not be set correctly. Current: $monospace_font"
    fi

    # Check if fonts are available
    if fc-list | grep -qi "cantarell"; then
        log_success "Cantarell font family is available"
    else
        log_error "Cantarell font family is not available"
    fi

    if fc-list | grep -qi "source code pro"; then
        log_success "Source Code Pro font family is available"
    else
        log_error "Source Code Pro font family is not available"
    fi
}

# Test Qt theming
test_qt_theming() {
    log_info "Testing Qt theming..."

    # Check Qt platform theme environment variable
    if [ "${QT_QPA_PLATFORMTHEME:-}" = "gnome" ]; then
        log_success "Qt platform theme is set to GNOME"
    else
        log_warning "Qt platform theme is not set to GNOME. Current: ${QT_QPA_PLATFORMTHEME:-not set}"
    fi

    # Check if adwaita-qt is available
    if command -v qt5ct >/dev/null 2>&1; then
        log_success "Qt5 configuration tool is available"
    else
        log_warning "Qt5 configuration tool is not available"
    fi
}

# Test GNOME extensions
test_extensions() {
    log_info "Testing GNOME extensions..."

    # Check if gnome-extensions command is available
    if ! command -v gnome-extensions >/dev/null 2>&1; then
        log_error "gnome-extensions command not available"
        return 1
    fi

    # List enabled extensions
    local enabled_extensions
    enabled_extensions=$(gnome-extensions list --enabled 2>/dev/null || echo "")

    if [ -n "$enabled_extensions" ]; then
        log_success "GNOME extensions are available:"
        echo "$enabled_extensions" | while read -r ext; do
            echo "  - $ext"
        done
    else
        log_warning "No GNOME extensions are enabled"
    fi

    # Check specific important extensions
    if echo "$enabled_extensions" | grep -q "dash-to-dock"; then
        log_success "Dash to Dock extension is enabled"
    else
        log_warning "Dash to Dock extension is not enabled"
    fi

    if echo "$enabled_extensions" | grep -q "blur-my-shell"; then
        log_success "Blur My Shell extension is enabled"
    else
        log_warning "Blur My Shell extension is not enabled"
    fi
}

# Test background and wallpaper
test_background() {
    log_info "Testing background configuration..."

    # Test background URI
    local bg_uri
    bg_uri=$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || echo "not set")

    if [[ "$bg_uri" == *"adwaita-d.webp"* ]]; then
        log_success "Dark mode wallpaper is correctly configured"
    else
        log_info "Dark mode wallpaper URI: $bg_uri"
    fi

    # Check if background files exist
    local bg_path="/nix/store"
    if find $bg_path -name "*gnome-backgrounds*" -type d 2>/dev/null | head -1 | grep -q gnome-backgrounds; then
        log_success "GNOME backgrounds package is available"
    else
        log_warning "GNOME backgrounds package might not be available"
    fi
}

# Test display server
test_display_server() {
    log_info "Testing display server..."

    case "${XDG_SESSION_TYPE:-}" in
        "wayland")
            log_success "Running on Wayland"
            ;;
        "x11")
            log_info "Running on X11"
            ;;
        *)
            log_warning "Unknown session type: ${XDG_SESSION_TYPE:-unknown}"
            ;;
    esac

    # Check for hardware acceleration
    if command -v glxinfo >/dev/null 2>&1; then
        local renderer
        renderer=$(glxinfo | grep "OpenGL renderer" | cut -d: -f2 | xargs 2>/dev/null || echo "unknown")
        if [[ "$renderer" != *"llvmpipe"* ]] && [[ "$renderer" != *"software"* ]]; then
            log_success "Hardware acceleration is working: $renderer"
        else
            log_warning "Software rendering detected: $renderer"
        fi
    else
        log_info "glxinfo not available, cannot check hardware acceleration"
    fi
}

# Main execution
main() {
    echo "=================================="
    echo "GNOME Theming Validation Script"
    echo "=================================="
    echo

    # Run all tests
    local tests_passed=0
    local total_tests=7

    if check_gnome_session; then ((tests_passed++)); fi
    test_dconf_settings; ((tests_passed++))
    test_fonts; ((tests_passed++))
    test_qt_theming; ((tests_passed++))
    test_extensions; ((tests_passed++))
    test_background; ((tests_passed++))
    test_display_server; ((tests_passed++))

    echo
    echo "=================================="
    log_info "Validation completed"

    if [ $tests_passed -eq $total_tests ]; then
        log_success "All tests passed!"
    else
        log_warning "Some tests had warnings or errors"
    fi

    echo
    echo "If you see errors or warnings, you may need to:"
    echo "1. Log out and log back in"
    echo "2. Run 'dconf reset -f /' to reset GNOME settings"
    echo "3. Rebuild your NixOS configuration with 'sudo nixos-rebuild switch'"
    echo "4. Restart your system"
    echo
    echo "For accent color issues specifically:"
    echo "1. Open GNOME Settings > Appearance"
    echo "2. Try changing the accent color manually"
    echo "3. Check if the change persists after restart"
}

# Run the script
main "$@"
