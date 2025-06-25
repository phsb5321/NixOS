#!/usr/bin/env bash
# Bruno Wayland Compatibility Wrapper
# Fixes remaining Wayland proxy cleanup issues

# Set optimal Wayland environment for Electron apps
export ELECTRON_OZONE_PLATFORM_HINT=auto
export ELECTRON_ENABLE_WAYLAND=1
export WAYLAND_DEBUG=0

# Additional environment tweaks for better compatibility
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland

# Launch Bruno with error suppression for non-critical Wayland warnings
exec bruno "$@" 2> >(grep -v "libwayland: warning: queue .* destroyed while proxies still attached" >&2)
