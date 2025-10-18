#!/usr/bin/env bash

# Google Meet Screen Sharing Fix Script for NixOS Wayland
# This script ensures Chrome runs with native Wayland support and WebRTC PipeWire enabled

set -euo pipefail

echo "🔧 Google Meet Screen Sharing Fix for NixOS Wayland"
echo "=================================================="

# Check if running on Wayland
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo "❌ Not running on Wayland. Current session: $XDG_SESSION_TYPE"
    echo "   Screen sharing fix is designed for Wayland systems."
    exit 1
fi

echo "✅ Running on Wayland"

# Check PipeWire status
if ! pgrep -x pipewire > /dev/null; then
    echo "❌ PipeWire is not running"
    exit 1
fi
echo "✅ PipeWire is running"

# Check portal services
if ! systemctl --user is-active --quiet xdg-desktop-portal; then
    echo "❌ xdg-desktop-portal is not running"
    exit 1
fi

if ! systemctl --user is-active --quiet xdg-desktop-portal-gnome; then
    echo "❌ xdg-desktop-portal-gnome is not running"
    exit 1
fi
echo "✅ Portal services are running"

# Find Chrome/Chromium
CHROME_PATH=""
if command -v google-chrome-stable > /dev/null; then
    CHROME_PATH="google-chrome-stable"
elif command -v chromium > /dev/null; then
    CHROME_PATH="chromium"
elif command -v google-chrome > /dev/null; then
    CHROME_PATH="google-chrome"
else
    echo "❌ No Chrome or Chromium browser found"
    exit 1
fi

echo "✅ Found browser: $CHROME_PATH"

# Kill existing Chrome instances
if pgrep -f "$CHROME_PATH" > /dev/null; then
    echo "🔄 Closing existing Chrome instances..."
    pkill -f "$CHROME_PATH" || true
    sleep 2
fi

# Launch Chrome with Wayland native support and WebRTC PipeWire
echo "🚀 Launching Chrome with native Wayland support..."
echo ""
echo "📋 Chrome will be launched with these important flags:"
echo "   --ozone-platform=wayland    (Native Wayland support)"
echo "   --enable-webrtc-pipewire-capturer    (Enable PipeWire screen capture)"
echo "   --enable-features=WebRTCPipeWireCapturer    (Force WebRTC PipeWire)"
echo ""

# Set environment variables for optimal Wayland support
export OZONE_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=GNOME
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-0

# Launch Chrome with optimal settings for Google Meet screen sharing
exec "$CHROME_PATH" \
    --ozone-platform=wayland \
    --enable-webrtc-pipewire-capturer \
    --enable-features=WebRTCPipeWireCapturer \
    --disable-gpu-sandbox \
    --enable-unsafe-webgpu \
    "https://meet.google.com" \
    "$@"