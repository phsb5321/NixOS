# GNOME Improvements for NixOS (2025)

**Tailored for Dotfiles-Based Configuration (No Home Manager)**

This guide provides research-backed improvements for GNOME on NixOS, adapted specifically for this repository's chezmoi dotfiles architecture.

---

## Table of Contents

1. [Latest GNOME Features](#latest-gnome-features)
2. [Essential Extensions](#essential-extensions)
3. [Performance Optimizations](#performance-optimizations)
4. [Theming Approaches](#theming-approaches)
5. [Portal Configuration](#portal-configuration)
6. [Implementation Guide](#implementation-guide)

---

## Latest GNOME Features

### GNOME 47 "Denver" (NixOS 24.11)
- ✅ Accent colors support
- ✅ Small screen compatibility improvements
- ✅ Hardware-accelerated screen capture
- ✅ Better Wayland performance

### GNOME 48 "Bengaluru" (NixOS 25.05 - Latest)
- 🎨 **HDR support** for compatible displays
- 🔔 Improved notification system
- 🎵 New Decibels music player (default)
- ⚡ Enhanced Wayland compositor performance

**Current System Status:**
- Desktop: GNOME 48 on Wayland with AMD RX 5700 XT
- Laptop: GNOME 48 (X11 for NVIDIA compatibility)

---

## Essential Extensions

### Currently Installed (Good Foundation)
✅ Dash-to-Panel
✅ AppIndicator and KStatusNotifierItem Support
✅ Blur My Shell
✅ Aylur's Widgets
✅ Advanced Alt-Tab Window Switcher
✅ Clipboard History
✅ Caffeine
✅ Just Perfection
✅ User Themes
✅ Vitals

### Recommended Additions

#### 1. GSConnect
**Purpose:** Phone integration (KDE Connect for GNOME)
- File sharing between phone and computer
- Notification sync
- Media controls
- Clipboard sharing
- SMS from desktop

**Installation:**
```nix
# Add to modules/desktop/gnome/extensions.nix
gsconnect = {
  enable = lib.mkEnableOption "GSConnect extension";
  package = pkgs.gnomeExtensions.gsconnect;
};
```

#### 2. Space Bar
**Purpose:** Workspace indicator in top panel
- Visual workspace switcher
- Shows current workspace number
- Customizable appearance

**Installation:**
```nix
space-bar = {
  enable = lib.mkEnableOption "Space Bar workspace indicator";
  package = pkgs.gnomeExtensions.space-bar;
};
```

### Extension Configuration via Dotfiles

**Configure extension settings using dconf:**

```bash
# Export current settings
dconf dump /org/gnome/shell/extensions/ > ~/NixOS/dotfiles/config/gnome/extensions.dconf

# Add to dotfiles
dotfiles-add ~/NixOS/dotfiles/config/gnome/extensions.dconf

# Apply changes
dotfiles-apply
```

**Create a template for host-specific extension settings:**

```bash
# ~/NixOS/dotfiles/config/gnome/extensions.dconf.tmpl
[dash-to-panel]
panel-position='BOTTOM'
panel-size=48
{{- if eq .chezmoi.hostname "desktop" }}
multi-monitors=true
stockgs-keep-dash=false
{{- else if eq .chezmoi.hostname "laptop" }}
multi-monitors=false
stockgs-keep-dash=true
{{- end }}

[vitals]
hot-sensors=['_processor_usage_', '_memory_usage_', '_temperature_max_']
{{- if eq .chezmoi.hostname "desktop" }}
show-gpu=true
show-network=true
{{- else }}
show-gpu=false
show-battery=true
{{- end }}
```

---

## Performance Optimizations

### 1. Wayland Optimizations (System-Level)

**Add to `modules/desktop/gnome/wayland.nix`:**

```nix
environment.sessionVariables = {
  # Existing
  NIXOS_OZONE_WL = "1";

  # New additions for performance
  MOZ_ENABLE_WAYLAND = "1";  # Firefox Wayland
  QT_QPA_PLATFORM = "wayland";  # Qt applications

  # Mutter performance tweaks
  MUTTER_DEBUG_FORCE_KMS_MODE = "simple";  # Better GPU compatibility
  CLUTTER_PAINT = "disable-clipped-redraws:disable-culling";
};
```

### 2. AMD GPU Optimizations (Desktop)

**Add to `modules/hardware/amd-gpu.nix`:**

```nix
# Enhanced AMD GPU configuration
hardware.graphics = {
  extraPackages = with pkgs; [
    amdvlk
    rocmPackages.clr.icd  # Better OpenCL support
  ];
};

# Mesa performance optimizations
environment.variables = {
  AMD_VULKAN_ICD = "RADV";  # RADV is faster for most workloads
  RADV_PERFTEST = "gpl,nggc";  # Graphics pipeline library + NGG culling
  RADV_DEBUG = "zerovram";  # Reduce VRAM usage
};
```

### 3. Mutter Performance Settings (User-Level via Dotfiles)

**Create `~/NixOS/dotfiles/config/gnome/mutter-performance.dconf`:**

```ini
[org/gnome/mutter]
# Variable refresh rate (FreeSync/G-Sync)
experimental-features=['variable-refresh-rate', 'scale-monitor-framebuffer']

# Reduce compositing overhead
check-alive-timeout=uint32 60000

# Better frame pacing
sync-to-vblank=true
```

**Add to dotfiles:**
```bash
dotfiles-add ~/NixOS/dotfiles/config/gnome/mutter-performance.dconf

# Apply settings
dconf load /org/gnome/mutter/ < ~/NixOS/dotfiles/config/gnome/mutter-performance.dconf
```

### 4. GNOME Settings Optimization (User-Level)

**Create `~/NixOS/dotfiles/config/gnome/performance-settings.dconf`:**

```ini
[org/gnome/desktop/interface]
enable-animations=true
enable-hot-corners=false

[org/gnome/desktop/session]
idle-delay=uint32 0  # Never blank screen (desktop)

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'  # Never suspend on AC
power-button-action='interactive'

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=false  # Not needed on desktop
```

**Template version for multi-host:**

```ini
# ~/NixOS/dotfiles/config/gnome/performance-settings.dconf.tmpl
[org/gnome/desktop/interface]
enable-animations=true
{{- if eq .chezmoi.hostname "desktop" }}
enable-hot-corners=false
show-battery-percentage=false
{{- else if eq .chezmoi.hostname "laptop" }}
enable-hot-corners=true
show-battery-percentage=true
{{- end }}

[org/gnome/desktop/session]
{{- if eq .chezmoi.hostname "desktop" }}
idle-delay=uint32 0
{{- else }}
idle-delay=uint32 300
{{- end }}

[org/gnome/settings-daemon/plugins/power]
{{- if eq .chezmoi.hostname "desktop" }}
sleep-inactive-ac-type='nothing'
{{- else }}
sleep-inactive-ac-type='suspend'
sleep-inactive-battery-type='suspend'
sleep-inactive-battery-timeout=900
{{- end }}
```

### 5. Disable Unnecessary GNOME Services (System-Level)

**Add to `modules/desktop/gnome/base.nix`:**

```nix
# Disable GNOME bloat
services.gnome = {
  core-apps.enable = false;  # Disable all default apps
  games.enable = false;  # No GNOME games
  core-developer-tools.enable = false;  # No Builder, etc.
};

# Explicit package exclusions
environment.gnome.excludePackages = with pkgs; [
  gnome-photos
  gnome-tour
  cheese
  gnome-music
  gedit
  epiphany  # GNOME Web
  geary  # Email client
  gnome-characters
  totem  # Video player
  gnome-calendar
  gnome-contacts
  # Games
  tali
  iagno
  hitori
  atomix
  gnome-chess
  gnome-mahjongg
  gnome-mines
  gnome-sudoku
];
```

---

## Theming Approaches

### Option 1: Manual GTK Theming (Recommended for GNOME)

**System-level theme packages (NixOS module):**

```nix
# Add to modules/desktop/gnome/base.nix or a new themes.nix
environment.systemPackages = with pkgs; [
  # GTK Themes
  adw-gtk3  # Adwaita-like theme for GTK3

  # Icon Themes
  papirus-icon-theme

  # Cursor Themes
  bibata-cursors

  # Fonts
  (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
];
```

**User-level theme configuration (dotfiles):**

```bash
# Create GTK configuration files
mkdir -p ~/NixOS/dotfiles/config/gtk-3.0
mkdir -p ~/NixOS/dotfiles/config/gtk-4.0
```

**`~/NixOS/dotfiles/config/gtk-3.0/settings.ini`:**

```ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-font-name=Cantarell 11
gtk-enable-animations=true
```

**`~/NixOS/dotfiles/config/gtk-4.0/settings.ini`:**

```ini
[Settings]
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
gtk-font-name=Cantarell 11
```

**GNOME-specific theming via dconf (dotfiles):**

```bash
# ~/NixOS/dotfiles/config/gnome/theming.dconf
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='adw-gtk3-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Ice'
font-name='Cantarell 11'
document-font-name='Sans 11'
monospace-font-name='JetBrainsMono Nerd Font 10'
```

**Add to dotfiles:**

```bash
dotfiles-add ~/NixOS/dotfiles/config/gtk-3.0/settings.ini
dotfiles-add ~/NixOS/dotfiles/config/gtk-4.0/settings.ini
dotfiles-add ~/NixOS/dotfiles/config/gnome/theming.dconf

# Apply
dotfiles-apply
dconf load /org/gnome/desktop/interface/ < ~/NixOS/dotfiles/config/gnome/theming.dconf
```

### Option 2: Stylix (Unified System Theming)

**⚠️ Note:** Stylix has limitations with libadwaita apps (GNOME Console, Settings)

**Add to `flake.nix`:**

```nix
inputs.stylix.url = "github:danth/stylix";

# In nixosConfigurations
modules = [
  inputs.stylix.nixosModules.stylix
  # ... other modules
];
```

**Create `modules/desktop/stylix.nix`:**

```nix
{ config, pkgs, lib, ... }:

{
  options.desktop.stylix = {
    enable = lib.mkEnableOption "Stylix system theming";
  };

  config = lib.mkIf config.desktop.stylix.enable {
    stylix = {
      enable = true;

      # Auto-generate from wallpaper
      image = ./wallpaper.png;

      # Or use predefined scheme
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      fonts = {
        monospace = {
          package = pkgs.nerdfonts.override { fonts = ["JetBrainsMono"]; };
          name = "JetBrainsMono Nerd Font";
        };

        sansSerif = {
          package = pkgs.cantarell-fonts;
          name = "Cantarell";
        };

        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
      };

      # Override for GNOME compatibility
      targets = {
        gnome.enable = true;
        gtk.enable = true;
      };
    };
  };
}
```

### Popular Theme Collections

**Catppuccin (Modern Pastel Theme):**

```nix
environment.systemPackages = with pkgs; [
  catppuccin-gtk
  catppuccin-papirus-folders
];
```

```ini
# In dotfiles gtk settings
gtk-theme-name=catppuccin-mocha-lavender-standard+default
```

**Orchis (Material Design):**

```nix
environment.systemPackages = with pkgs; [
  orchis-theme
];
```

**Graphite (Clean Modern):**

```nix
environment.systemPackages = with pkgs; [
  graphite-gtk-theme
];
```

---

## Portal Configuration

### Enhanced XDG Portal Setup

**Update `modules/desktop/gnome/base.nix`:**

```nix
# Modern portal configuration
xdg.portal = {
  enable = true;

  # Explicit backend configuration
  config = {
    common = {
      default = ["gtk"];
      "org.freedesktop.impl.portal.Settings" = ["gnome"];
    };

    gnome = {
      default = ["gnome" "gtk"];
      "org.freedesktop.impl.portal.FileChooser" = ["gnome"];
      "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
    };
  };

  extraPortals = with pkgs; [
    xdg-desktop-portal-gnome
    xdg-desktop-portal-gtk
  ];

  # Force apps to use portals
  xdgOpenUsePortal = true;
};

# Ensure PipeWire for screen sharing
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = false;

  # Low-latency configuration
  extraConfig.pipewire."92-low-latency" = {
    context.properties = {
      default.clock.rate = 48000;
      default.clock.quantum = 1024;
      default.clock.min-quantum = 512;
      default.clock.max-quantum = 2048;
    };
  };
};
```

---

## Implementation Guide

### Phase 1: System-Level Improvements

**1. Update GNOME Modules**

```bash
# Edit modules/desktop/gnome/base.nix
# Add package exclusions and portal config

# Edit modules/desktop/gnome/wayland.nix
# Add new environment variables

# Edit modules/hardware/amd-gpu.nix (desktop)
# Add performance optimizations

# Rebuild
nixswitch
```

**2. Add New Extensions**

```bash
# Edit modules/desktop/gnome/extensions.nix
# Add gsconnect, space-bar options

# Rebuild
nixswitch
```

### Phase 2: User-Level Configuration (Dotfiles)

**1. Create GNOME dotfiles structure**

```bash
mkdir -p ~/NixOS/dotfiles/config/gnome
mkdir -p ~/NixOS/dotfiles/config/gtk-3.0
mkdir -p ~/NixOS/dotfiles/config/gtk-4.0
```

**2. Export current GNOME settings**

```bash
# Full dump
dconf dump / > ~/NixOS/dotfiles/config/gnome/full-settings.dconf

# Specific subsystems
dconf dump /org/gnome/desktop/ > ~/NixOS/dotfiles/config/gnome/desktop.dconf
dconf dump /org/gnome/shell/ > ~/NixOS/dotfiles/config/gnome/shell.dconf
dconf dump /org/gnome/mutter/ > ~/NixOS/dotfiles/config/gnome/mutter.dconf
dconf dump /org/gnome/shell/extensions/ > ~/NixOS/dotfiles/config/gnome/extensions.dconf
```

**3. Create performance config files**

```bash
# Create the files from examples in this guide
# mutter-performance.dconf
# performance-settings.dconf
# theming.dconf

# Use templates (.tmpl) for host-specific settings
```

**4. Add to dotfiles**

```bash
dotfiles-add ~/NixOS/dotfiles/config/gnome/
dotfiles-add ~/NixOS/dotfiles/config/gtk-3.0/settings.ini
dotfiles-add ~/NixOS/dotfiles/config/gtk-4.0/settings.ini

# Check status
dotfiles-status

# Validate
dotfiles-check

# Apply
dotfiles-apply
```

**5. Create restoration script**

Create `~/NixOS/dotfiles/.chezmoiscripts/run_onchange_after_apply-gnome-settings.sh`:

```bash
#!/bin/bash
# Apply GNOME dconf settings from dotfiles

DOTFILES_DIR="${HOME}/NixOS/dotfiles"

echo "Applying GNOME settings..."

# Apply mutter settings
if [ -f "${DOTFILES_DIR}/config/gnome/mutter-performance.dconf" ]; then
  dconf load /org/gnome/mutter/ < "${DOTFILES_DIR}/config/gnome/mutter-performance.dconf"
fi

# Apply desktop settings
if [ -f "${DOTFILES_DIR}/config/gnome/desktop.dconf" ]; then
  dconf load /org/gnome/desktop/ < "${DOTFILES_DIR}/config/gnome/desktop.dconf"
fi

# Apply shell settings
if [ -f "${DOTFILES_DIR}/config/gnome/shell.dconf" ]; then
  dconf load /org/gnome/shell/ < "${DOTFILES_DIR}/config/gnome/shell.dconf"
fi

# Apply extension settings
if [ -f "${DOTFILES_DIR}/config/gnome/extensions.dconf" ]; then
  dconf load /org/gnome/shell/extensions/ < "${DOTFILES_DIR}/config/gnome/extensions.dconf"
fi

# Apply theme settings
if [ -f "${DOTFILES_DIR}/config/gnome/theming.dconf" ]; then
  dconf load /org/gnome/desktop/interface/ < "${DOTFILES_DIR}/config/gnome/theming.dconf"
fi

echo "GNOME settings applied. Restart GNOME Shell (Alt+F2, 'r') for all changes to take effect."
```

Make it executable:
```bash
chmod +x ~/NixOS/dotfiles/.chezmoiscripts/run_onchange_after_apply-gnome-settings.sh
```

### Phase 3: Advanced Keyboard Shortcuts (Optional)

**Create `~/NixOS/dotfiles/config/gnome/keybindings.dconf`:**

```ini
[org/gnome/desktop/wm/keybindings]
close=['<Super>q']
maximize=['<Super>Up']
unmaximize=['<Super>Down']
toggle-maximized=['<Super>m']

# Disable alt-tab for apps, use for windows instead
switch-applications=@as []
switch-windows=['<Alt>Tab']

# Workspace switching
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']

# Move windows to workspaces
move-to-workspace-1=['<Super><Shift>1']
move-to-workspace-2=['<Super><Shift>2']
move-to-workspace-3=['<Super><Shift>3']
move-to-workspace-4=['<Super><Shift>4']

[org/gnome/settings-daemon/plugins/media-keys]
# Custom keybindings list
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
name='Terminal'
command='kgx'
binding='<Super>Return'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1]
name='File Manager'
command='nautilus'
binding='<Super>e'

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2]
name='System Monitor'
command='gnome-system-monitor'
binding='<Super><Shift>Escape'
```

---

## Troubleshooting

### Settings Not Applying

**Check dconf is enabled:**
```bash
# Should show installed
rpm -q dconf
```

**Reload dconf:**
```bash
dconf update
killall -HUP gnome-shell
```

**Reset GNOME Shell:**
```
Alt+F2, type 'r', press Enter
```

### Extensions Not Working

**Check extension compatibility:**
```bash
gnome-extensions list
gnome-extensions info extension-name@example.com
```

**Enable extensions:**
```bash
gnome-extensions enable extension-name@example.com
```

**Check logs:**
```bash
journalctl -b | grep -i gnome
journalctl -b | grep -i mutter
```

### Performance Issues

**Check Wayland is active:**
```bash
echo $XDG_SESSION_TYPE  # Should output: wayland
```

**Check GPU acceleration:**
```bash
glxinfo | grep "direct rendering"  # Should be "Yes"
```

**Monitor compositing:**
```bash
# Install
nix-shell -p mesa-demos

# Test
glxgears -info
```

---

## Summary: Priority Improvements

### Immediate Wins (Do First)

1. ✅ **Enable VRR for gaming** - Add to mutter settings via dotfiles
2. ✅ **Add GSConnect extension** - Phone integration
3. ✅ **Export current GNOME settings** - Backup and version control
4. ✅ **Optimize AMD GPU settings** - Better performance
5. ✅ **Clean up GNOME bloat** - Remove unused packages

### Quick Improvements (Easy)

6. ✅ **Add keyboard shortcuts** - Productivity boost
7. ✅ **Configure GTK themes** - Consistent appearance
8. ✅ **Optimize mutter settings** - Better frame pacing
9. ✅ **Enhanced portal config** - Better Wayland app integration

### Advanced (Optional)

10. ✅ **Stylix integration** - Unified theming
11. ✅ **Custom extension configs** - Fine-tuned workflow
12. ✅ **Auto-sync scripts** - Dotfiles restoration on login

---

## Resources

- [GNOME Official Wiki](https://wiki.gnome.org/)
- [GNOME Extensions](https://extensions.gnome.org/)
- [Chezmoi Documentation](https://www.chezmoi.io/)
- [NixOS GNOME Wiki](https://wiki.nixos.org/wiki/GNOME)
- [This Repository's Dotfiles Guide](../dotfiles/README.md)

---

**Last Updated:** 2025-11-24
**GNOME Version:** 48 "Bengaluru"
**NixOS Channel:** nixpkgs-unstable
**Configuration Method:** Chezmoi Dotfiles (No Home Manager)
