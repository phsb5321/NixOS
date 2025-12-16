# Electron Titlebar Duplication Research - GNOME X11

**Date:** 2025-11-29
**Context:** NixOS Server (Proxmox VM) running GNOME on X11
**Issue:** Electron applications showing duplicate titlebars (both CSD and SSD)

---

## Executive Summary

The duplicate titlebar issue occurs when Electron applications attempt to use Client-Side Decorations (CSD) but the window manager (Mutter) also draws Server-Side Decorations (SSD), resulting in two titlebars. This is primarily an issue on X11 sessions, particularly with certain desktop environments or window manager configurations.

**Primary Solution:** Set `GTK_CSD=0` to disable client-side decorations, forcing applications to use server-side decorations exclusively.

**NixOS Implementation:** Use `environment.sessionVariables` or `services.xserver.displayManager.sessionVariables` to set environment variables for the GNOME session.

---

## 1. Environment Variables

### 1.1 Primary Variables

#### GTK_CSD
- **Purpose:** Controls GTK3 client-side decoration behavior
- **Values:**
  - `1` (default): Enable client-side decorations
  - `0`: Disable client-side decorations, force server-side decorations
- **Effect:** When set to `0`, GTK applications will not use custom titlebars and will let the window manager draw decorations
- **Compatibility:** Works with GTK3 applications, which includes many Linux apps but **NOT** Electron apps directly

**Important Note:** Electron apps are Chromium-based and don't use GTK for UI rendering. They use their own rendering engine. However, `GTK_CSD=0` can affect how Electron apps interact with the window manager's decoration expectations.

#### ELECTRON_ENABLE_WAYLAND
- **Purpose:** Force Electron apps to use Wayland instead of X11
- **Values:** `1` (enable), `0` (disable)
- **Note:** Only relevant for Wayland sessions, not applicable to X11 fix

#### NIXOS_OZONE_WL
- **Purpose:** Enable Ozone Wayland platform for Chromium/Electron apps
- **Values:** `1` (enable)
- **Note:** Wayland-only, not relevant for X11 duplicate titlebar fix

#### ELECTRON_OZONE_PLATFORM_HINT
- **Purpose:** Hint for Electron apps about which platform to use
- **Values:** `auto`, `wayland`, `x11`
- **Note:** Between Electron 28-37, can help with platform selection
- **Caveat:** Command-line flag `--ozone-platform-hint=auto` doesn't work since Electron 38

### 1.2 Additional Relevant Variables

#### GSK_RENDERER
- **Purpose:** Controls GTK4 rendering backend
- **Values:** `ngl`, `gl`, `cairo`, `""` (auto-detect)
- **Use Case:** Can affect window decoration rendering performance
- **Current Server Config:** Set to `""` (empty) for VM auto-detection

#### GDK_BACKEND
- **Purpose:** Selects GDK backend for GTK applications
- **Values:** `x11`, `wayland`, `wayland,x11` (fallback list)
- **X11 Setting:** Should be `x11` when running X11 session
- **Current Server Config:** Not explicitly set for X11 (should default correctly)

---

## 2. NixOS GNOME Configuration

### 2.1 Where to Set Environment Variables

NixOS provides multiple options for setting environment variables, each with different scopes and initialization timing:

#### Option 1: `environment.sessionVariables` (RECOMMENDED)
```nix
environment.sessionVariables = {
  GTK_CSD = "0";
};
```

- **Scope:** System-wide, all user sessions
- **Initialization:** Set through PAM during login
- **Availability:** Available in all session types (GNOME, terminal, etc.)
- **Persistence:** Survives session restarts
- **Best for:** Global settings that should apply everywhere

**Current Server Usage:** Already used for VM-specific graphics variables (lines 97-103 in configuration.nix, 122-124 in gnome.nix)

#### Option 2: `environment.variables`
```nix
environment.variables = {
  GTK_CSD = "0";
};
```

- **Scope:** System-wide, shell initialization
- **Initialization:** Set during shell startup
- **Note:** `environment.sessionVariables` gets merged into `environment.variables`
- **Best for:** Variables that need to be available in shells

#### Option 3: `services.xserver.displayManager.importedVariables`
```nix
environment.variables = {
  GTK_CSD = "0";
};

services.xserver.displayManager.importedVariables = [
  "GTK_CSD"
];
```

- **Purpose:** Expose variables to graphical systemd user services
- **Use Case:** When apps are launched via systemd services
- **Example Use:** Scaling variables (GDK_SCALE, GDK_DPI_SCALE)

#### Option 4: Module-level `environment.sessionVariables` (CURRENT APPROACH)
```nix
# In modules/desktop/gnome/wayland.nix
config = lib.mkIf cfg.enable {
  environment.sessionVariables = lib.mkMerge [
    (lib.mkIf cfg.wayland.enable {
      GTK_CSD = "1";
      # ... other Wayland vars
    })
    (lib.mkIf (!cfg.wayland.enable) {
      GTK_CSD = "0";  # Could add this for X11
      # ... other X11 vars
    })
  ];
};
```

- **Scope:** Conditional based on Wayland/X11 mode
- **Best for:** Host-specific or mode-specific configurations
- **Current Implementation:** Server uses X11 mode (`wayland.enable = false`)

### 2.2 NixOS Configuration Examples

#### Example 1: System-wide GTK CSD Disable
```nix
# In configuration.nix or modules/desktop/gnome/wayland.nix
environment.sessionVariables = {
  # Disable client-side decorations globally
  GTK_CSD = "0";
};
```

#### Example 2: X11-specific Configuration (Conditional)
```nix
# In modules/desktop/gnome/wayland.nix
environment.sessionVariables = lib.mkMerge [
  # X11-specific (for NVIDIA compatibility and titlebar fix)
  (lib.mkIf (!cfg.wayland.enable) {
    GDK_BACKEND = "x11";
    MOZ_ENABLE_WAYLAND = "0";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    GSK_RENDERER = "gl";
    QT_QPA_PLATFORM = "xcb";
    XDG_SESSION_TYPE = "x11";
    GTK_CSD = "0";  # Add this to disable duplicate titlebars
  })
];
```

#### Example 3: Per-Application Desktop File Override
```nix
# Create wrapper for specific Electron app
{ pkgs, lib, ... }:

let
  vscodeNoCSD = pkgs.writeShellScriptBin "vscode-nocsd" ''
    export GTK_CSD=0
    exec ${pkgs.vscode}/bin/code "$@"
  '';
in {
  environment.systemPackages = [ vscodeNoCSD ];

  # Override desktop file
  xdg.desktopEntries.vscode-nocsd = {
    name = "Visual Studio Code (No CSD)";
    exec = "${vscodeNoCSD}/bin/vscode-nocsd %F";
    icon = "vscode";
    type = "Application";
    categories = [ "Development" "IDE" ];
  };
}
```

### 2.3 Current Server Configuration Analysis

**File:** `/home/notroot/NixOS/hosts/server/gnome.nix`

**Current X11 Settings (lines 122-124):**
```nix
environment.sessionVariables = {
  GSK_RENDERER = lib.mkForce "";  # VM auto-detect
};
```

**Wayland Module (modules/desktop/gnome/wayland.nix):**
- Line 70: Sets `GTK_CSD = "1"` for Wayland mode
- Lines 92-99: X11 mode settings (when `wayland.enable = false`)
- **Missing:** `GTK_CSD = "0"` in X11 mode configuration

**Recommendation:** Add `GTK_CSD = "0"` to the X11-specific section in `modules/desktop/gnome/wayland.nix`

---

## 3. Best Practices & Recommendations

### 3.1 Recommended Approach for NixOS Server

Given the server context (Proxmox VM, X11 mode, GNOME), the recommended approach is:

1. **Add GTK_CSD=0 to X11 mode in wayland.nix**
   - Consistent with existing architecture
   - Applies conditionally only when X11 is used
   - Centralized in the GNOME module

2. **Implementation:**
```nix
# In modules/desktop/gnome/wayland.nix, line 92-99 section
(lib.mkIf (!cfg.wayland.enable) {
  GDK_BACKEND = "x11";
  MOZ_ENABLE_WAYLAND = "0";
  ELECTRON_OZONE_PLATFORM_HINT = "auto";
  GSK_RENDERER = "gl";
  QT_QPA_PLATFORM = "xcb";
  XDG_SESSION_TYPE = "x11";
  GTK_CSD = "0";  # ADD THIS LINE
})
```

### 3.2 Why This Approach?

**Pros:**
- Consistent with existing modular architecture
- Automatically applies to all X11 sessions
- No per-application configuration needed
- Centralized in the GNOME module
- Can be overridden per-host if needed

**Cons:**
- Affects all GTK applications, not just Electron apps
- Some native GTK apps might look different (traditional titlebars)
- May not work with all Electron apps (they don't use GTK directly)

### 3.3 Alternative Approaches

#### Approach 2: Host-specific Override
```nix
# In hosts/server/gnome.nix
environment.sessionVariables = {
  GTK_CSD = lib.mkForce "0";
};
```
- **Use when:** Only server needs this fix
- **Downside:** Doesn't help other X11 hosts

#### Approach 3: Per-application Wrappers
```nix
# Create wrappers for specific Electron apps
environment.systemPackages = [
  (pkgs.writeShellScriptBin "electron-app-nocsd" ''
    export GTK_CSD=0
    exec ${pkgs.electronApp}/bin/electron-app "$@"
  '')
];
```
- **Use when:** Only certain apps have the issue
- **Downside:** Maintenance overhead, need to wrap each app

#### Approach 4: Desktop File Overrides
- Use `xdg.desktopEntries` to create custom launchers
- **Use when:** Want to offer both CSD and non-CSD versions
- **Downside:** Complex, requires per-app configuration

### 3.4 Known Issues & Limitations

#### GTK_CSD=0 Limitations

1. **Electron Apps Don't Use GTK Directly**
   - Electron uses Chromium's rendering engine
   - GTK_CSD may not affect Electron apps as expected
   - The variable affects how the window manager treats decoration hints

2. **Application-Specific Behavior**
   - Some apps hardcode CSD behavior
   - VSCode, Discord, and other Electron apps may ignore GTK_CSD
   - Results vary by Electron version and app configuration

3. **Visual Inconsistency**
   - Native GTK apps will use traditional titlebars
   - Mixed appearance between GTK and Electron apps
   - May not match GNOME's modern design aesthetic

#### gtk3-nocsd Tool Status

- **gtk3-nocsd:** Legacy LD_PRELOAD hack to disable CSD
  - Status: **Largely defunct as of 2024**
  - Works inconsistently on modern systems
  - Not recommended for new deployments

- **GTK-NoCSD:** Modern alternative supporting GTK3/GTK4/libadwaita
  - More reliable than original gtk3-nocsd
  - Uses LD_PRELOAD: `export LD_PRELOAD=libgtk-nocsd.so`
  - **Still may not work with Electron apps**

#### GNOME/Mutter Limitations

- **Wayland:** Mutter only supports CSD on Wayland
  - No global SSD enforcement possible on Wayland
  - Applications must implement CSD or look broken

- **X11:** Mutter can draw SSD but apps can override
  - GTK_CSD=0 hints to apps to not use CSD
  - Window manager should draw decorations
  - Some apps ignore the hint

---

## 4. Alternative Solutions

### 4.1 GNOME Shell Extensions

**Potential Extensions for Window Decoration Control:**

1. **Unite Extension**
   - **Purpose:** Removes titlebars from maximized/all windows
   - **Use Case:** Hide redundant titlebars, merge with top bar
   - **Limitation:** Hides titlebars, doesn't fix duplication
   - **URL:** https://extensions.gnome.org/extension/1287/unite/

2. **Custom Window Controls**
   - **Purpose:** Customize window control buttons
   - **Use Case:** Theme window buttons to match design
   - **Limitation:** Cosmetic only, doesn't prevent duplication
   - **URL:** https://extensions.gnome.org/extension/6300/custom-window-controls/

3. **Window Commander**
   - **Purpose:** Advanced window management via D-Bus
   - **Use Case:** Programmatic window control
   - **Limitation:** Doesn't provide CSD/SSD enforcement
   - **URL:** https://extensions.gnome.org/extension/7302/window-commander/

**Verdict:** No GNOME Shell extension currently provides global CSD/SSD enforcement or duplicate titlebar prevention.

### 4.2 Per-Application Configuration

#### VSCode-Specific Solution
```json
// In VSCode settings.json
{
  "window.titleBarStyle": "native"
}
```
- Forces VSCode to use native (server-side) decorations
- Avoids duplicate titlebar in VSCode specifically
- **Note:** VSCode 1.97.1+ changed default to "custom"

#### Electron Apps Command-Line Flags
```bash
# Launch with SSD preference
electron-app --disable-features=CustomTitlebar
electron-app --gtk-titlebar
```
- May work for some Electron apps
- Not standardized across all apps
- Requires per-app configuration

#### Desktop File Modification
```nix
# Override desktop file with environment variable
xdg.desktopEntries.app-nocsd = {
  name = "App (No CSD)";
  exec = "env GTK_CSD=0 electron-app %U";
  # ... other settings
};
```

### 4.3 Switch to Wayland (Long-term)

**Current Status:**
- GNOME heavily favors Wayland over X11
- Fedora, Ubuntu defaulting to Wayland
- GNOME removing X11 session support in future

**For Server:**
- **Current:** X11 for Proxmox VM compatibility
- **Limitation:** VirtIO-GPU may have better Wayland support
- **Future:** Consider testing Wayland mode

**Wayland Benefits:**
- Better CSD support and integration
- Proper window decoration protocol
- Modern display server architecture

**Wayland Challenges:**
- Some apps still have X11-only features
- VNC/RDP may need different setup
- Screen sharing complexity

---

## 5. Potential Side Effects & Compatibility Concerns

### 5.1 Side Effects of GTK_CSD=0

#### Visual Changes
- **Traditional Titlebars:** GTK apps will use old-style window decorations
- **Button Layout:** May not respect GNOME's button layout preferences
- **Theme Inconsistency:** Mixed appearance between apps
- **Lost Features:** Some apps integrate controls into headerbar (lost with SSD)

#### Application Compatibility
- **GNOME Apps:** Designed for CSD, may look outdated with SSD
- **Third-party Apps:** Varies by application
- **Electron Apps:** May or may not respect the hint
- **Qt Apps:** Unaffected (use QT_QPA_PLATFORM instead)

### 5.2 Compatibility Concerns

#### Elementary OS Users
- Elementary OS sets GTK_CSD=1 by default
- Setting GTK_CSD=0 fixes duplicate titlebars for Firefox
- Known workaround in Elementary OS community

#### Firefox/Mozilla Apps
- Bugzilla #1195002: Titlebar overlap on Elementary OS with GTK_CSD
- Firefox can use either CSD or SSD depending on GTK_CSD
- Generally respects the environment variable

#### Chrome/Chromium Apps
- Use their own window decoration system
- Support both CSD and SSD on Linux
- May or may not respect GTK_CSD
- Can be configured via chrome://flags or command-line

#### VSCode/Electron Apps
- Electron apps don't use GTK for rendering
- GTK_CSD may affect window manager hints
- Behavior varies by Electron version
- VSCode has internal titleBarStyle setting

### 5.3 Testing Recommendations

Before deploying GTK_CSD=0 globally, test with:

1. **Native GNOME Apps:**
   - Nautilus (Files)
   - GNOME Terminal
   - GNOME Text Editor
   - Settings

2. **Electron Apps:**
   - VSCode
   - Discord
   - Any other Electron apps on the system

3. **Browsers:**
   - Firefox
   - Chrome/Chromium

4. **Verify:**
   - No duplicate titlebars
   - Window controls work correctly
   - Minimize/maximize/close buttons functional
   - No visual glitches or rendering issues

---

## 6. Implementation Decision Matrix

| Approach | Scope | Effort | Effectiveness | Maintenance |
|----------|-------|--------|---------------|-------------|
| `GTK_CSD=0` in X11 mode | All apps | Low | Medium | Low |
| Host-specific override | Server only | Low | Medium | Low |
| Per-app wrappers | Specific apps | Medium | High | High |
| Desktop file overrides | Specific apps | Medium | High | High |
| GNOME Shell extension | All windows | Medium | Low | Medium |
| Switch to Wayland | All apps | High | High | Low |

**Recommended for NixOS Server:** `GTK_CSD=0` in X11 mode (Approach 1)

---

## 7. Proposed Implementation for NixOS Server

### 7.1 Changes Required

**File:** `/home/notroot/NixOS/modules/desktop/gnome/wayland.nix`

**Change:** Add `GTK_CSD = "0";` to X11-specific environment variables

```nix
# Line 92-99, modify to:
(lib.mkIf (!cfg.wayland.enable) {
  GDK_BACKEND = "x11";
  MOZ_ENABLE_WAYLAND = "0";
  ELECTRON_OZONE_PLATFORM_HINT = "auto";
  GSK_RENDERER = "gl";
  QT_QPA_PLATFORM = "xcb";
  XDG_SESSION_TYPE = "x11";
  GTK_CSD = "0";  # Disable client-side decorations on X11
})
```

### 7.2 Testing Plan

1. **Build configuration:**
   ```bash
   sudo nixos-rebuild build --flake .#nixos-server
   ```

2. **Review changes:**
   ```bash
   nix store diff-closures /run/current-system ./result
   ```

3. **Deploy to server:**
   ```bash
   sudo nixos-rebuild switch --flake .#nixos-server
   ```

4. **Test applications:**
   - Log out and log back in (reload session variables)
   - Check GNOME apps (Nautilus, Terminal)
   - Check any Electron apps (if installed)
   - Check Firefox/browsers
   - Verify no duplicate titlebars
   - Verify window controls work

5. **Rollback if needed:**
   ```bash
   sudo nixos-rebuild switch --rollback
   ```

### 7.3 Documentation Updates

After implementation, document in:
- `CLAUDE.md`: Note about GTK_CSD=0 for X11 sessions
- Host-specific notes if behavior differs from other hosts

---

## 8. References & Sources

### Primary Research Sources

1. **Electron GitHub Issues:**
   - [Native headerbars · Issue #11907](https://github.com/electron/electron/issues/11907)
   - [GTK CSD: CSS rules · Issue #44531](https://github.com/electron/electron/issues/44531)
   - [Feature Request: Support CSD in Wayland · Issue #27522](https://github.com/electron/electron/issues/27522)

2. **NixOS Documentation:**
   - [Environment Variables - NixOS Wiki](https://nixos.wiki/wiki/Environment_variables)
   - [GNOME - NixOS Wiki](https://nixos.wiki/wiki/GNOME)
   - [Overview of the NixOS X11 session modules](https://gist.github.com/bennofs/bb41b17deeeb49e345904f2339222625)

3. **GTK/GNOME Documentation:**
   - [Running and debugging GTK Applications](https://docs.gtk.org/gtk4/running.html)
   - [Server Side Decorations in GTK: A Proposal](https://discourse.gnome.org/t/server-side-decorations-in-gtk-a-proposal/16029)
   - [Client-side decoration - Wikipedia](https://en.wikipedia.org/wiki/Client-side_decoration)

4. **Community Solutions:**
   - [How do I disable CSD globally in GNOME?](https://askubuntu.com/questions/961161/how-do-i-disable-client-side-decoration-globally-in-gnome)
   - [2 title bars in some gnome GTK apps](https://stackoverflow.com/questions/73848549/2-title-bars-in-some-gnome-gtk-apps)
   - [GTK-NoCSD - Modern CSD disabling tool](https://codeberg.org/MorsMortium/GTK-NoCSD)

5. **Electron Environment Variables:**
   - [Environment Variables | Electron](https://www.electronjs.org/docs/latest/api/environment-variables)
   - [How to run Electron apps under Wayland](https://dev.to/archerallstars/how-to-run-electron-apps-under-linuxs-wayland-session-like-a-pro-2g25)

6. **VSCode-Specific:**
   - [duplicate title bars · Issue #67984](https://github.com/microsoft/vscode/issues/67984)
   - [Title Bar styling broken on Linux · Issue #240732](https://github.com/microsoft/vscode/issues/240732)
   - [Allow custom titlebar on Linux · PR #237337](https://github.com/microsoft/vscode/pull/237337)

7. **NixOS Configuration:**
   - [Override desktopItem from package](https://discourse.nixos.org/t/override-desktopitem-from-package/11352)
   - [NixOS displayManager configuration](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/x11/display-managers/default.nix)

---

## 9. Glossary

**CSD (Client-Side Decorations):** Window decorations (titlebar, borders, buttons) drawn by the application itself using GTK HeaderBar or similar.

**SSD (Server-Side Decorations):** Window decorations drawn by the window manager (Mutter, Metacity, etc.), traditional X11 approach.

**Mutter:** GNOME's compositing window manager, based on Metacity.

**Ozone:** Chromium's platform abstraction layer for supporting different display servers (X11, Wayland).

**GTK HeaderBar:** GTK3+ widget that merges titlebar, menubar, and toolbar into one unified bar.

**PAM (Pluggable Authentication Module):** System for authentication, used in NixOS to initialize session variables.

**GDM (GNOME Display Manager):** Login screen and session manager for GNOME.

**VirtIO-GPU:** Paravirtualized GPU driver for virtual machines, used in Proxmox/QEMU.

---

## 10. Conclusion

The duplicate titlebar issue on Electron applications in GNOME X11 is a complex problem stemming from the interaction between:
- Electron's Chromium-based rendering (not GTK)
- GNOME's preference for client-side decorations
- X11's window manager decoration system
- Application-specific decoration handling

The recommended solution for the NixOS server is to add `GTK_CSD=0` to the X11-specific environment variables in the GNOME module. This is:
- Low effort
- Low maintenance
- Architecturally consistent
- Easily reversible

However, it's important to understand that:
- This may not fix all Electron apps (they don't use GTK)
- Native GNOME apps will look different (traditional titlebars)
- Results should be tested before permanent deployment
- Wayland migration may be a better long-term solution

The implementation should be tested thoroughly with common applications to verify effectiveness and identify any visual or functional regressions.

---

**Generated:** 2025-11-29
**For:** NixOS Server (Proxmox VM) - GNOME X11 Configuration
**Status:** Research Complete - Ready for Implementation Testing
