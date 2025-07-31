# VS Code Electron Warnings Fix

## Problem
VS Code was showing warnings about unrecognized Electron/Chromium command-line options:
```
Warning: 'ozone-platform-hint' is not in the list of known options, but still passed to Electron/Chromium.
Warning: 'enable-features' is not in the list of known options, but still passed to Electron/Chromium.
Warning: 'enable-wayland-ime' is not in the list of known options, but still passed to Electron/Chromium.
```

## Root Cause
The VS Code wrapper script in NixOS was adding Wayland-specific flags based on environment variables:
```bash
${NIXOS_OZONE_WL:+${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}
```

The logic checks if both `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set (regardless of their values). Since:
- `NIXOS_OZONE_WL="0"` (set but disabled)
- `WAYLAND_DISPLAY="/dev/null"` (set to prevent Wayland connections)

Both variables were considered "set" in bash parameter expansion, causing the wrapper to add the problematic Wayland flags even when we wanted X11-only mode.

## Solution
Removed the `NIXOS_OZONE_WL` variable from environment configuration instead of setting it to "0".

### Changes Made

#### /home/notroot/NixOS/hosts/default/configuration.nix
- **Removed**: `NIXOS_OZONE_WL = "0";` from `environment.sessionVariables`
- **Removed**: `ELECTRON_OZONE_PLATFORM_HINT=x11` from `environment.etc."environment".text` (duplicate)
- **Added**: Comment explaining why `NIXOS_OZONE_WL` is unset

#### /home/notroot/NixOS/hosts/laptop/configuration.nix  
- **Removed**: `NIXOS_OZONE_WL = "0";` from `environment.sessionVariables`
- **Removed**: `ELECTRON_OZONE_PLATFORM_HINT=x11` from `environment.etc."environment".text` (duplicate)
- **Added**: Comment explaining why `NIXOS_OZONE_WL` is unset

## Result
- ✅ VS Code launches without Electron warnings
- ✅ X11 mode still enforced via other environment variables
- ✅ Wayland completely disabled as intended
- ✅ No functional changes to desktop behavior

## Testing
```bash
# After system rebuild and environment reload:
unset NIXOS_OZONE_WL  # Simulate new session
code --version        # No warnings
code . --list-extensions  # No warnings
```

## Technical Details
The NixOS VS Code wrapper script logic uses bash parameter expansion:
- `${VAR:+text}` expands to "text" if VAR is set and non-empty
- Setting `NIXOS_OZONE_WL="0"` still counts as "set"
- Unsetting the variable prevents the Wayland flags from being added
- This maintains X11-only behavior while fixing the warnings
