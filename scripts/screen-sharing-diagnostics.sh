#!/usr/bin/env bash
# Screen sharing diagnostics script for NixOS + GNOME + PipeWire

echo "=== Screen Sharing Diagnostics ==="
echo

# Check if PipeWire is running
echo "1. Checking PipeWire status..."
if systemctl --user is-active --quiet pipewire; then
    echo "✓ PipeWire is running"
else
    echo "✗ PipeWire is not running"
    echo "  Try: systemctl --user start pipewire"
fi

if systemctl --user is-active --quiet wireplumber; then
    echo "✓ WirePlumber is running"
else
    echo "✗ WirePlumber is not running"
    echo "  Try: systemctl --user start wireplumber"
fi

echo

# Check desktop portal services
echo "2. Checking XDG Desktop Portal services..."
if systemctl --user is-active --quiet xdg-desktop-portal; then
    echo "✓ xdg-desktop-portal is running"
else
    echo "✗ xdg-desktop-portal is not running"
    echo "  Try: systemctl --user start xdg-desktop-portal"
fi

if systemctl --user is-active --quiet xdg-desktop-portal-gnome; then
    echo "✓ xdg-desktop-portal-gnome is running"
else
    echo "✗ xdg-desktop-portal-gnome is not running"
    echo "  Try: systemctl --user start xdg-desktop-portal-gnome"
fi

if systemctl --user is-active --quiet xdg-desktop-portal-gtk; then
    echo "✓ xdg-desktop-portal-gtk is running"
else
    echo "✗ xdg-desktop-portal-gtk is not running"
    echo "  Try: systemctl --user start xdg-desktop-portal-gtk"
fi

echo

# Check environment variables
echo "3. Checking environment variables..."
if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    echo "✓ XDG_CURRENT_DESKTOP = $XDG_CURRENT_DESKTOP"
else
    echo "✗ XDG_CURRENT_DESKTOP = $XDG_CURRENT_DESKTOP (should be GNOME)"
fi

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    echo "✓ XDG_SESSION_TYPE = $XDG_SESSION_TYPE"
else
    echo "✗ XDG_SESSION_TYPE = $XDG_SESSION_TYPE (should be wayland)"
fi

if [ "$GTK_USE_PORTAL" = "1" ]; then
    echo "✓ GTK_USE_PORTAL = $GTK_USE_PORTAL"
else
    echo "✗ GTK_USE_PORTAL = $GTK_USE_PORTAL (should be 1)"
fi

echo

# Check portal configuration
echo "4. Checking portal configuration..."
if [ -f "/run/user/$(id -u)/xdg-desktop-portal/portals.conf" ]; then
    echo "✓ Portal config found:"
    cat "/run/user/$(id -u)/xdg-desktop-portal/portals.conf" | head -10
else
    echo "✗ Portal config not found"
fi

echo

# Check available portals
echo "5. Checking available portals..."
if command -v busctl >/dev/null 2>&1; then
    echo "Available portal implementations:"
    busctl --user list | grep -E "(desktop.portal|portal)" || echo "No portals found via D-Bus"
fi

echo

# Browser-specific checks
echo "6. Browser compatibility notes..."
echo "Firefox: WebRTC screen sharing should work out of the box"
echo "Chrome/Chromium: Requires --enable-features=WebRTCPipeWireCapturer flag for older versions"
echo "  - Chrome 110+ should work without flags"
echo "  - Chromium in NixOS usually includes the flag"

echo
echo "=== Test Instructions ==="
echo "1. Open Firefox or Chrome"
echo "2. Go to: https://mozilla.github.io/webrtc-landing/gum_test.html"
echo "3. Click 'GetDisplayMedia' button"
echo "4. You should see a GNOME screen sharing permission dialog"
echo "5. Grant permission and check if screen sharing works"
echo
echo "If it doesn't work, try restarting your session:"
echo "  systemctl --user restart pipewire wireplumber"
echo "  systemctl --user restart xdg-desktop-portal*"
echo "  Log out and log back in"
