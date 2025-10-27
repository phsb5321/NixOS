# GNOME Desktop Environment - Modular Architecture

This directory contains the shared GNOME configuration modules used across all hosts.

## Architecture Overview

```
modules/desktop/gnome/
├── base.nix        ← Core GNOME infrastructure
├── extensions.nix  ← Extension package management
├── default.nix     ← Main module orchestrator
└── README.md       ← This file

hosts/
├── default/gnome.nix  ← Desktop host configuration
├── laptop/gnome.nix   ← Laptop host configuration
└── server/gnome.nix   ← Server host configuration
```

## Module Responsibilities

### `base.nix` - Core Infrastructure

**Purpose**: Shared GNOME base services and packages that all hosts need.

**Provides**:
- Display Manager (GDM)
- Essential GNOME services (keyring, settings-daemon, evolution-data-server, etc.)
- XDG desktop portals (file dialogs, screen sharing)
- Base GNOME packages (gnome-shell, control-center, nautilus, firefox, etc.)
- System fonts (Cantarell, Source Code Pro, Noto fonts)
- Input device management (libinput)
- Qt theming integration

**Options**:
```nix
modules.desktop.gnome.base = {
  enable = true;              # Enable base GNOME
  displayManager = true;      # Enable GDM
  coreServices = true;        # Enable GNOME services
  coreApplications = true;    # Install core apps
  portal = true;              # Enable XDG portals
  themes = true;              # Install themes
  fonts = true;               # Install fonts
};
```

### `extensions.nix` - Extension Management

**Purpose**: Manage GNOME Shell extensions with granular per-host control.

**Provides**:
- Extension package installation based on enable flags
- Granular enable/disable options for each extension

**Available Extensions**:
- `appIndicator` - System tray support
- `dashToDock` - Dock customization
- `userThemes` - Custom theme support
- `justPerfection` - UI tweaks
- `vitals` - System monitoring
- `caffeine` - Prevent screen dimming
- `clipboard` - Clipboard manager
- `gsconnect` - KDE Connect integration
- `workspaceIndicator` - Workspace switching
- `soundOutput` - Audio output selector

**Options**:
```nix
modules.desktop.gnome.extensions = {
  enable = true;
  appIndicator = true;
  dashToDock = true;
  userThemes = true;
  # ... etc for each extension
  customList = [];  # Additional extension IDs
};
```

**Important**: Extension packages are installed here, but the `enabled-extensions`
dconf list must be defined in host-specific `gnome.nix` files.

### `default.nix` - Main Orchestrator

**Purpose**: Main GNOME module that coordinates base and extensions.

**Provides**:
- Imports base.nix and extensions.nix
- Wayland/X11 switching logic
- Session-specific environment variables
- Portal service systemd units
- Theme management (icon theme, cursor theme)

**Options**:
```nix
modules.desktop.gnome = {
  enable = true;
  wayland.enable = true;  # false for X11
  theme = {
    iconTheme = "Papirus-Dark";
    cursorTheme = "Bibata-Modern-Ice";
  };
};
```

## Host-Specific Configuration

Each host MUST define its own complete GNOME configuration in `hosts/<hostname>/gnome.nix`.

### Required in Each Host Config

1. **Enable GNOME and set options**:
```nix
modules.desktop.gnome = {
  enable = true;
  wayland.enable = true;  # or false for X11

  extensions = {
    enable = true;
    appIndicator = true;
    dashToDock = true;
    # ... enable desired extensions
  };
};
```

2. **Define complete dconf database**:
```nix
programs.dconf.profiles.user.databases = [
  {
    lockAll = false;
    settings = {
      # MUST include enabled-extensions list
      "org/gnome/shell" = {
        enabled-extensions = [
          "appindicatorsupport@rgcjonas.gmail.com"
          "dash-to-dock@micxgx.gmail.com"
          # ... list all enabled extension IDs
        ];
        favorite-apps = [ /* ... */ ];
      };

      # All other dconf settings
      "org/gnome/desktop/interface" = { /* ... */ };
      "org/gnome/mutter" = { /* ... */ };
      # ... etc
    };
  }
];
```

3. **Optional: Host-specific overrides**:
```nix
# Override environment variables if needed
environment.sessionVariables = {
  GSK_RENDERER = lib.mkForce "";  # Example: VM auto-detection
};

# Security configuration
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
};
```

## Critical Design Decision: No dconf Merging

**Why each host defines a complete dconf database:**

NixOS cannot properly merge multiple `programs.dconf.profiles.user.databases`
definitions from different modules. Attempting to do so causes:

```
error: Cannot construct GVariant value from an attribute set
```

**Solution**: Each host defines ONE complete dconf database containing:
- All GNOME settings (interface, mutter, wm, privacy, power, etc.)
- Enabled extensions list matching the extensions enabled in module options
- All other host-specific customizations

This prevents merging conflicts and gives each host complete control.

## Example Host Configuration

See `hosts/server/gnome.nix` for a complete example:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable GNOME with X11
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = false;

    extensions = {
      enable = true;
      appIndicator = true;
      dashToDock = true;
      justPerfection = true;
      vitals = true;
      caffeine = true;
      workspaceIndicator = true;
      # Disabled: userThemes, clipboard, gsconnect, soundOutput
    };
  };

  # Complete dconf database
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "just-perfection-desktop@just-perfection"
            "Vitals@CoreCoding.com"
            "caffeine@patapon.info"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          ];
          # ... rest of settings
        };
        # ... all other dconf settings
      };
    }
  ];

  # Host-specific overrides
  environment.sessionVariables = {
    GSK_RENDERER = lib.mkForce "";  # VM auto-detection
  };
}
```

## Adding a New Extension

1. **Add option to `extensions.nix`**:
```nix
myExtension = lib.mkOption {
  type = lib.types.bool;
  default = true;
  description = "Enable My Extension";
};
```

2. **Add package installation**:
```nix
environment.systemPackages = with pkgs;
  # ...
  ++ lib.optional config.modules.desktop.gnome.extensions.myExtension gnomeExtensions.my-extension;
```

3. **Enable in host config**:
```nix
modules.desktop.gnome.extensions.myExtension = true;
```

4. **Add extension ID to host's dconf**:
```nix
"org/gnome/shell" = {
  enabled-extensions = [
    # ...
    "my-extension@example.com"
  ];
};
```

## Common Patterns

### Desktop (High Performance)
- Wayland enabled
- All extensions enabled
- Hardware acceleration variables
- Dynamic triple buffering
- Gaming-focused

### Laptop (Battery Conscious)
- X11 for compatibility
- Most extensions enabled (except power-hungry ones)
- Power-saving settings
- Shorter idle timeout
- Suspend even on AC

### Server (Minimal)
- X11 for VM compatibility
- Only essential extensions
- No idle/sleep
- Fixed workspaces
- VM-optimized rendering

## Testing

After modifying GNOME modules:

```bash
# Test build for each host
sudo nixos-rebuild build --flake .#default
sudo nixos-rebuild build --flake .#laptop
sudo nixos-rebuild build --flake .#nixos-server

# Or use the helper script
./user-scripts/nixswitch
```

## Troubleshooting

### Build fails with GVariant error
**Problem**: Multiple dconf databases trying to merge.

**Solution**: Ensure ONLY the host-specific `gnome.nix` defines `programs.dconf.profiles.user.databases`.
Remove any dconf database definitions from `hosts/shared/common.nix` or other shared modules.

### Extension not appearing
**Problem**: Extension package installed but not showing.

**Solution**: Check that:
1. Extension is enabled in `modules.desktop.gnome.extensions.*`
2. Extension ID is listed in `enabled-extensions` in host's dconf
3. Extension ID matches exactly (check extension package for correct ID)

### Wrong display protocol (Wayland/X11)
**Problem**: Running Wayland when X11 expected or vice versa.

**Solution**: Check `modules.desktop.gnome.wayland.enable` in host config.
GDM will respect this setting.

## References

- [NixOS GNOME Wiki](https://nixos.wiki/wiki/GNOME)
- [GNOME Extensions](https://extensions.gnome.org/)
- [dconf Manual](https://help.gnome.org/admin/system-admin-guide/stable/dconf.html.en)
