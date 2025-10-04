# NixOS Modular Architecture Guide

This document explains the modular architecture implemented for the multi-host NixOS flake configuration.

## Overview

The configuration follows a hierarchical module system that enables:
- **Composition**: Build configurations by combining modules
- **Reusability**: Share common configurations across hosts
- **Flexibility**: Override defaults at any level
- **Type Safety**: Leverage NixOS module system for validation

## Module Structure

```
modules/
├── core/           # Core system modules
├── desktop/        # Desktop environment modules
├── packages/       # Package category modules
├── networking/     # Network configuration
├── hardware/       # Hardware-specific modules
├── profiles/       # Complete system profiles
└── dotfiles/       # User configuration files
```

## Key Concepts

### 1. Module Composition

Modules can be composed together to create complete system configurations:

```nix
# Enable laptop profile which automatically configures:
# - Hardware (battery, power, touchpad)
# - Desktop (GNOME with laptop extensions)
# - Packages (optimized selection)
modules.profiles.laptop = {
  enable = true;
  variant = "workstation";
};
```

### 2. Option-Based Configuration

Each module exposes options that can be configured:

```nix
modules.hardware.laptop = {
  batteryManagement.chargeThreshold = 85;
  powerManagement.profile = "balanced";
  touchpad.naturalScrolling = true;
};
```

### 3. Hierarchical Overrides

Configuration follows a precedence hierarchy:
1. Host-specific configuration (highest priority)
2. Profile defaults
3. Module defaults
4. NixOS defaults (lowest priority)

## Module Categories

### Core Modules (`modules/core/`)

Essential system configuration:
- **default.nix**: Base system settings, locale, timezone
- **fonts.nix**: Font configuration
- **pipewire.nix**: Audio system
- **gaming.nix**: Gaming support
- **document-tools.nix**: LaTeX, Markdown, documentation tools

### Desktop Modules (`modules/desktop/`)

Desktop environment configuration:
- **gnome.nix**: GNOME desktop with extensions

### Hardware Modules (`modules/hardware/`)

Hardware-specific configurations:
- **laptop.nix**: Laptop-specific settings (battery, power, touchpad)

### Profile Modules (`modules/profiles/`)

Complete system profiles that combine multiple modules:
- **laptop.nix**: Laptop profile with variants (ultrabook, gaming, workstation, standard)

### Package Modules (`modules/packages/`)

Categorized software packages:
- **browsers**: Web browsers
- **development**: Development tools
- **media**: Media players and editors
- **gaming**: Gaming-related packages

## Usage Examples

### 1. Basic Laptop Configuration

```nix
# hosts/laptop/configuration.nix
{
  modules.profiles.laptop = {
    enable = true;
    variant = "standard";
  };
}
```

### 2. Gaming Laptop Configuration

```nix
{
  modules.profiles.laptop = {
    enable = true;
    variant = "gaming";
    gnomeExtensions.minimal = true; # Better performance
  };
  
  # Override specific settings
  modules.hardware.laptop = {
    batteryManagement.chargeThreshold = null; # Full charge for gaming
    powerManagement.profile = "performance";
  };
}
```

### 3. Development Workstation

```nix
{
  modules.profiles.laptop = {
    enable = true;
    variant = "workstation";
    gnomeExtensions.productivity = true;
  };
  
  modules.packages = {
    development.enable = true;
    extraPackages = with pkgs; [
      vscode
      docker-compose
      kubectl
    ];
  };
}
```

### 4. Ultra-portable Configuration

```nix
{
  modules.profiles.laptop = {
    enable = true;
    variant = "ultrabook";
    gnomeExtensions.minimal = true;
  };
  
  # Disable heavy features
  modules.packages.gaming.enable = false;
  modules.core.documentTools.latex.enable = false;
}
```

## Creating New Hosts

1. Create a new directory under `hosts/`:
   ```
   hosts/new-laptop/
   ├── configuration.nix
   └── hardware-configuration.nix
   ```

2. Use profiles and modules in `configuration.nix`:
   ```nix
   {
     imports = [
       ./hardware-configuration.nix
       ../../modules
       ../shared/common.nix
     ];
     
     modules.profiles.laptop = {
       enable = true;
       variant = "standard";
     };
     
     # Host-specific overrides...
   }
   ```

3. Add to `flake.nix`:
   ```nix
   nixosConfigurations.new-laptop = mkNixosSystem {
     system = "x86_64-linux";
     hostname = "new-laptop";
     configPath = "new-laptop";
   };
   ```

## Best Practices

1. **Use Profiles First**: Start with a profile that matches your use case
2. **Override Sparingly**: Only override what's necessary for your specific hardware
3. **Document Hardware**: Add comments for hardware-specific settings (GPU, touchpad quirks)
4. **Test Changes**: Use `nixos-rebuild dry-build` before switching
5. **Version Control**: Commit working configurations before major changes

## Module Development

To create a new module:

1. **Define Options**: Use `lib.mkOption` with types and descriptions
2. **Provide Defaults**: Use `lib.mkDefault` for overridable defaults
3. **Check Enable**: Wrap config in `lib.mkIf cfg.enable`
4. **Document**: Add descriptions to all options

Example module structure:
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.category.name;
in {
  options.modules.category.name = {
    enable = lib.mkEnableOption "module description";
    
    setting = lib.mkOption {
      type = lib.types.str;
      default = "value";
      description = "What this setting does";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Implementation
  };
}
```

## Troubleshooting

1. **Option Conflicts**: Check module precedence and use `lib.mkForce` if needed
2. **Missing Options**: Ensure all required modules are imported
3. **Type Errors**: Verify option types match expected values
4. **Performance**: Use `nixos-rebuild dry-build --show-trace` for debugging

## Future Improvements

- [ ] Server profiles (web server, database server)
- [ ] Desktop profiles (KDE, XFCE, Sway)
- [ ] Security hardening profiles
- [ ] Container orchestration profiles
- [ ] Home-manager integration