# NixOS Configuration Structure

This NixOS configuration has been refactored to make it easier to share packages and configuration between hosts while maintaining host-specific customizations.

## Structure Overview

```
NixOS/
├── hosts/
│   ├── shared/
│   │   └── common.nix          # Shared configuration for all hosts
│   ├── default/                # Desktop configuration
│   │   ├── configuration.nix   # Desktop-specific settings
│   │   └── hardware-configuration.nix
│   └── laptop/                 # Laptop configuration
│       ├── configuration.nix   # Laptop-specific settings
│       └── hardware-configuration.nix
├── modules/
│   ├── packages/               # NEW: Shared package management
│   │   └── default.nix         # Categorized package definitions
│   ├── core/                   # Core system configuration
│   ├── desktop/                # Desktop environment management
│   ├── networking/             # Network configuration
│   └── home/                   # Home-manager integration
└── ...
```

## Key Changes

### 1. Shared Package Management (`modules/packages/`)

The new packages module provides categorized package management:

- **browsers**: Web browsers (Chrome, Firefox, Brave, etc.)
- **development**: Development tools (VSCode, Postman, etc.)
- **media**: Media and entertainment (Spotify, Discord, VLC, etc.)
- **utilities**: System utilities (gparted, syncthing, etc.)
- **gaming**: Gaming-related packages (Steam, GameMode, etc.)
- **audioVideo**: Audio/video tools (PipeWire, EasyEffects, etc.)
- **python**: Python with optional GTK support

### 2. Common Configuration (`hosts/shared/common.nix`)

Contains shared settings for:

- Basic system configuration
- Common hardware settings
- Shared services (Syncthing, SSH, etc.)
- User configuration
- Locale settings
- Desktop environment (GNOME)

### 3. Host-Specific Configurations

#### Desktop (`hosts/default/configuration.nix`)

- Gaming packages enabled
- AMD GPU configuration
- Java and Android development tools
- LaTeX documentation tools
- Desktop-specific ports (3000)

#### Laptop (`hosts/laptop/configuration.nix`)

- Gaming packages disabled (laptop-friendly)
- Intel graphics configuration
- Minimal package set
- Tailscale enabled for mobile connectivity

## Usage Examples

### Adding a New Package Category

To add a new package category, edit `modules/packages/default.nix`:

```nix
newCategory = {
  enable = mkEnableOption "new category packages";
  packages = mkOption {
    type = types.listOf types.package;
    default = with pkgs; [
      # your packages here
    ];
    description = "List of new category packages";
  };
};
```

### Enabling/Disabling Package Categories per Host

In any host configuration:

```nix
modules.packages = {
  enable = true;
  browsers.enable = true;     # Enable browsers
  gaming.enable = false;      # Disable gaming (good for laptops)
  development.enable = true;  # Enable development tools
};
```

### Adding Host-Specific Packages

```nix
modules.packages.extraPackages = with pkgs; [
  # Host-specific packages that don't fit in categories
  specialTool
  hostSpecificApp
];
```

## Benefits

1. **DRY Principle**: No more duplicated package lists between hosts
2. **Easy Maintenance**: Update packages in one place
3. **Flexible**: Enable/disable entire categories per host
4. **Scalable**: Easy to add new hosts that inherit common configuration
5. **Clear Separation**: Host-specific vs. shared configuration is obvious

## Migration Guide

When adding a new host:

1. Create the host directory: `hosts/newhost/`
2. Add hardware configuration: `hardware-configuration.nix`
3. Create minimal `configuration.nix` that imports common.nix
4. Add only host-specific overrides and packages

Example minimal host configuration:

```nix
{
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Override hostname
  modules.networking.hostName = "my-new-host";
  modules.home.hostName = "newhost";

  # Host-specific packages
  modules.packages.gaming.enable = true; # or false
  modules.packages.extraPackages = with pkgs; [
    hostSpecificTool
  ];

  # Host-specific hardware/boot configuration
  # ...
}
```

This structure makes it much easier to maintain multiple NixOS configurations while sharing common functionality.
