# GNOME Quick Wins - Immediate Improvements

**Quick reference for high-impact GNOME improvements using dotfiles approach**

See [GNOME_IMPROVEMENTS_2025.md](./GNOME_IMPROVEMENTS_2025.md) for comprehensive guide.

---

## 🚀 5-Minute Quick Wins

### 1. Enable Variable Refresh Rate (Gaming Performance)

```bash
# Create mutter config
cat > ~/NixOS/dotfiles/config/gnome/mutter-vrr.dconf << 'EOF'
[org/gnome/mutter]
experimental-features=['variable-refresh-rate']
EOF

# Apply
dconf load /org/gnome/mutter/ < ~/NixOS/dotfiles/config/gnome/mutter-vrr.dconf

# Add to dotfiles
dotfiles-add ~/NixOS/dotfiles/config/gnome/mutter-vrr.dconf
```

### 2. Backup Current GNOME Settings

```bash
# Export all settings
mkdir -p ~/NixOS/dotfiles/config/gnome
dconf dump / > ~/NixOS/dotfiles/config/gnome/backup-$(date +%Y%m%d).dconf

# Add to dotfiles
dotfiles-add ~/NixOS/dotfiles/config/gnome/
```

### 3. Add GSConnect Extension (Phone Integration)

```nix
# Edit modules/desktop/gnome/extensions.nix
gsconnect = {
  enable = lib.mkEnableOption "GSConnect phone integration";
  package = pkgs.gnomeExtensions.gsconnect;
};

# In host configuration, enable it:
desktop.gnome.extensions.gsconnect.enable = true;

# Rebuild
nixswitch
```

### 4. Optimize for Desktop Use

```bash
# Create desktop-optimized settings
cat > ~/NixOS/dotfiles/config/gnome/desktop-power.dconf << 'EOF'
[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-type='nothing'

[org/gnome/desktop/interface]
show-battery-percentage=false
EOF

# Apply
dconf load / < ~/NixOS/dotfiles/config/gnome/desktop-power.dconf
dotfiles-add ~/NixOS/dotfiles/config/gnome/desktop-power.dconf
```

### 5. Better Keyboard Shortcuts

```bash
# Create keybindings config
cat > ~/NixOS/dotfiles/config/gnome/keys.dconf << 'EOF'
[org/gnome/desktop/wm/keybindings]
close=['<Super>q']
maximize=['<Super>Up']
unmaximize=['<Super>Down']
switch-windows=['<Alt>Tab']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
name='Terminal'
command='kgx'
binding='<Super>Return'
EOF

# Apply
dconf load /org/gnome/desktop/wm/ < ~/NixOS/dotfiles/config/gnome/keys.dconf
dotfiles-add ~/NixOS/dotfiles/config/gnome/keys.dconf
```

---

## 🎨 Theming Quick Setup

### Install Theme Packages (System-Level)

```nix
# Add to modules/desktop/gnome/base.nix
environment.systemPackages = with pkgs; [
  adw-gtk3                # GTK theme
  papirus-icon-theme      # Icons
  bibata-cursors          # Cursors
];
```

### Configure Themes (User-Level)

```bash
# GTK 3
mkdir -p ~/NixOS/dotfiles/config/gtk-3.0
cat > ~/NixOS/dotfiles/config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-theme-name=adw-gtk3-dark
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
EOF

# GTK 4
mkdir -p ~/NixOS/dotfiles/config/gtk-4.0
cat > ~/NixOS/dotfiles/config/gtk-4.0/settings.ini << 'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Bibata-Modern-Ice
EOF

# GNOME theme settings
cat > ~/NixOS/dotfiles/config/gnome/theme.dconf << 'EOF'
[org/gnome/desktop/interface]
color-scheme='prefer-dark'
gtk-theme='adw-gtk3-dark'
icon-theme='Papirus-Dark'
cursor-theme='Bibata-Modern-Ice'
EOF

# Apply all
dotfiles-add ~/NixOS/dotfiles/config/gtk-3.0/settings.ini
dotfiles-add ~/NixOS/dotfiles/config/gtk-4.0/settings.ini
dotfiles-add ~/NixOS/dotfiles/config/gnome/theme.dconf
dconf load /org/gnome/desktop/interface/ < ~/NixOS/dotfiles/config/gnome/theme.dconf

# Rebuild for packages
nixswitch
```

---

## ⚡ AMD GPU Performance Boost

```nix
# Add to modules/hardware/amd-gpu.nix

environment.variables = {
  AMD_VULKAN_ICD = "RADV";
  RADV_PERFTEST = "gpl,nggc";
};

hardware.graphics.extraPackages = with pkgs; [
  rocmPackages.clr.icd  # Better OpenCL
];
```

Rebuild: `nixswitch`

---

## 🧹 Remove GNOME Bloat

```nix
# Add to modules/desktop/gnome/base.nix

services.gnome = {
  core-apps.enable = false;
  games.enable = false;
};

environment.gnome.excludePackages = with pkgs; [
  gnome-photos gnome-tour cheese gnome-music
  gedit epiphany geary totem gnome-calendar
  tali iagno hitori atomix
];
```

Rebuild: `nixswitch`

---

## 📊 Check Current Status

```bash
# Verify Wayland
echo $XDG_SESSION_TYPE  # Should be: wayland

# Check GNOME version
gnome-shell --version

# List extensions
gnome-extensions list

# Check GPU
glxinfo | grep "direct rendering"

# Monitor frame timing
journalctl -b | grep mutter
```

---

## 🔄 Create Auto-Apply Script

```bash
# Create chezmoi run script
cat > ~/NixOS/dotfiles/.chezmoiscripts/run_onchange_after_gnome-settings.sh << 'EOF'
#!/bin/bash
echo "Applying GNOME settings from dotfiles..."

GNOME_DIR="${HOME}/NixOS/dotfiles/config/gnome"

for dconf_file in "${GNOME_DIR}"/*.dconf; do
  if [ -f "$dconf_file" ]; then
    echo "Loading: $(basename $dconf_file)"
    dconf load / < "$dconf_file"
  fi
done

echo "Done! Restart GNOME Shell (Alt+F2, 'r') if needed."
EOF

chmod +x ~/NixOS/dotfiles/.chezmoiscripts/run_onchange_after_gnome-settings.sh
```

Now `dotfiles-apply` will automatically restore all GNOME settings!

---

## 📝 Workflow

1. **Make changes in GNOME UI** (Settings, extensions, etc.)
2. **Export settings**: `dconf dump /path/ > ~/NixOS/dotfiles/config/gnome/feature.dconf`
3. **Add to dotfiles**: `dotfiles-add ~/NixOS/dotfiles/config/gnome/feature.dconf`
4. **Validate**: `dotfiles-check`
5. **Apply**: `dotfiles-apply`
6. **Commit**: `git add . && git commit -m "feat(gnome): description"`

---

## 🎯 Top 3 Priorities

1. **Backup existing settings** → Version control everything
2. **Enable VRR** → Huge gaming improvement
3. **Remove bloat** → Faster, cleaner system

These take <15 minutes total and provide immediate benefits!

---

**Full Guide:** [GNOME_IMPROVEMENTS_2025.md](./GNOME_IMPROVEMENTS_2025.md)
**Dotfiles Docs:** [../dotfiles/README.md](../dotfiles/README.md)
**This System:** No Home Manager, dotfiles-based configuration
