# NixOS Multi-Machine Flake Architecture Improvement Plan

**Date:** October 5, 2025
**Current System:** Multi-machine NixOS flake with modular configuration
**Objective:** Reduce duplication, improve modularity, enhance maintainability

---

## Executive Summary

This plan outlines a comprehensive refactoring of the NixOS flake architecture to:
- **Eliminate configuration duplication** between hosts and shared configs
- **Split monolithic modules** into focused, maintainable units
- **Introduce role-based configuration** for better host abstraction
- **Add modern Nix helper libraries** for reduced boilerplate
- **Improve hardware abstraction** with unified GPU/device management
- **Implement secrets management** using sops-nix
- **Add testing infrastructure** for configuration validation

**No home-manager will be used** - your existing dotfiles solution is superior for single-user systems.

---

## Quick Reference: What's Being Improved

This plan covers **two major refactoring efforts** that work together:

### 1. NixOS Architecture Refactoring (Main Focus)
- **Role-based modules** replacing 372-line common.nix
- **Split package modules** from 335-line monolith into 10+ focused files
- **Unified GPU management** with automatic driver selection
- **Secrets management** with sops-nix
- **Testing infrastructure** for validation
- **Result:** 77-80% reduction in host config lines, massive maintainability improvement

### 2. Dotfiles Enhancement (Bonus - Milestone 8.5)
- **Template-based configs** for per-host customization (SSH, Git)
- **Proper initialization** of existing chezmoi setup
- **Portable configuration** with dynamic paths
- **Validation scripts** to prevent broken configs
- **Missing dotfiles** (.gitignore, .editorconfig, .curlrc)
- **Optional:** Secrets integration and auto-sync
- **Result:** Host-aware dotfiles, better security, automatic validation

### How They Work Together

```
┌─────────────────────────────────────────────────────┐
│ NixOS Configuration (System-Level)                  │
│ ├── Role-based modules (desktop/laptop)            │
│ ├── Package management (categorized)               │
│ ├── GPU abstraction (AMD/NVIDIA/hybrid)            │
│ ├── Secrets (sops-nix)                             │
│ └── Services (systemd)                             │
└─────────────────────────────────────────────────────┘
                        ↕
        ┌───────────────────────────────┐
        │ Integration Layer             │
        │ - Secrets exposed to chezmoi  │
        │ - Host detection (role-aware) │
        └───────────────────────────────┘
                        ↕
┌─────────────────────────────────────────────────────┐
│ Dotfiles (User-Level - Instant Changes)            │
│ ├── SSH config templates (per-host)                │
│ ├── Git config templates (different emails)        │
│ ├── Shell configs (modular)                        │
│ ├── Editor configs (.editorconfig)                 │
│ └── Validation (prevent broken configs)            │
└─────────────────────────────────────────────────────┘
```

### Task Count by Category

| Category | Tasks | Time | Benefit |
|----------|-------|------|---------|
| Foundation (libs, helpers) | 6 | 2h | Essential infrastructure |
| Modularization (services, roles, packages) | 20 | 11h | Core refactoring |
| Hardware (GPU abstraction) | 4 | 1.75h | Unified GPU management |
| Testing & Validation | 3 | 1.5h | Quality assurance |
| Secrets | 2 | 0.75h | Security |
| **Dotfiles** | **8** | **3.5h** | **Per-host configs** |
| Migration (breaking changes) | 8 | 4h | Deploy new architecture |
| Cleanup & Polish | 12 | 5.5h | Final touches |
| **TOTAL** | **63** | **28h** | **Complete modernization** |

---

## Current State Analysis

### Strengths ✅
- Modular structure with clear separation
- Host-specific configurations with shared base
- Categorical package management
- Profile system for laptop variants
- Git branching strategy for multi-host management
- Working dotfiles integration with chezmoi

### Pain Points ❌

| Issue | Impact | Lines Affected |
|-------|--------|----------------|
| `hosts/shared/common.nix` contains 372 lines of mixed concerns | High duplication | ~372 lines |
| `modules/packages/default.nix` is monolithic (335 lines) | Hard to maintain | ~335 lines |
| Hardware config manually managed per host | Brittle GPU switching | ~100 lines |
| No secrets management | Security risk | N/A |
| No configuration testing | Breaking changes | N/A |
| Repeated GNOME settings across hosts | Duplication | ~150 lines |

---

## Proposed Architecture

### New Directory Structure

```
NixOS/
├── flake.nix                    # Simplified with flake-parts
├── flake.lock
├── lib/                         # NEW: Custom helper functions
│   ├── default.nix
│   ├── builders.nix             # Host/module builders
│   └── utils.nix                # Utility functions
├── hosts/
│   ├── default/                 # Desktop
│   │   ├── configuration.nix    # Minimal - just role + hardware
│   │   └── hardware-configuration.nix
│   ├── laptop/                  # Laptop
│   │   ├── configuration.nix    # Minimal - just role + hardware
│   │   └── hardware-configuration.nix
│   └── shared/                  # DELETE - move to roles
│       └── common.nix           # TO BE DELETED
├── modules/
│   ├── core/                    # System core (unchanged)
│   │   ├── default.nix
│   │   ├── fonts.nix
│   │   ├── pipewire.nix
│   │   ├── gaming.nix
│   │   ├── java.nix
│   │   ├── document-tools.nix
│   │   ├── docker-dns.nix
│   │   ├── monitor-audio.nix
│   │   └── networking.nix
│   ├── roles/                   # NEW: Role-based configs
│   │   ├── default.nix
│   │   ├── desktop.nix          # Desktop workstation role
│   │   ├── laptop.nix           # Laptop role
│   │   ├── server.nix           # Server role (future)
│   │   └── minimal.nix          # Minimal install role
│   ├── hardware/                # Enhanced hardware abstraction
│   │   ├── default.nix
│   │   ├── gpu/                 # NEW: Unified GPU management
│   │   │   ├── default.nix
│   │   │   ├── amd.nix          # AMD-specific
│   │   │   ├── nvidia.nix       # NVIDIA-specific
│   │   │   ├── intel.nix        # Intel-specific
│   │   │   └── hybrid.nix       # Hybrid graphics (Prime, etc)
│   │   ├── audio/               # NEW: Audio subsystem
│   │   │   ├── default.nix
│   │   │   ├── pipewire.nix     # Move from core
│   │   │   └── monitor-audio.nix # Move from core
│   │   └── laptop.nix           # Laptop-specific (unchanged)
│   ├── packages/                # SPLIT: One file per category
│   │   ├── default.nix          # Just imports
│   │   ├── browsers.nix         # Browser packages
│   │   ├── development/         # Development tools split
│   │   │   ├── default.nix
│   │   │   ├── languages.nix    # Compilers, runtimes
│   │   │   ├── tools.nix        # Build tools, debuggers
│   │   │   ├── editors.nix      # VS Code, Zed
│   │   │   └── lsp.nix          # Language servers
│   │   ├── media.nix            # Media apps
│   │   ├── gaming.nix           # Gaming packages
│   │   ├── utilities.nix        # System utilities
│   │   ├── audioVideo.nix       # A/V tools
│   │   └── terminal.nix         # Terminal tools
│   ├── desktop/                 # Desktop environments
│   │   ├── default.nix
│   │   ├── gnome/               # NEW: Split GNOME config
│   │   │   ├── default.nix      # Base GNOME
│   │   │   ├── extensions.nix   # Extension management
│   │   │   ├── settings.nix     # dconf/gsettings
│   │   │   └── wayland.nix      # Wayland-specific
│   │   └── gnome.nix            # DELETE - replaced by gnome/
│   ├── networking/              # Network configs (unchanged)
│   │   ├── default.nix
│   │   ├── tailscale.nix
│   │   ├── remote-desktop.nix
│   │   ├── dns.nix
│   │   └── firewall.nix
│   ├── services/                # NEW: Service modules
│   │   ├── default.nix
│   │   ├── syncthing.nix        # Extract from common.nix
│   │   ├── ssh.nix              # Extract from common.nix
│   │   ├── printing.nix         # Extract from common.nix
│   │   └── docker.nix           # Docker daemon config
│   ├── secrets/                 # NEW: Secrets management
│   │   ├── default.nix
│   │   └── README.md
│   ├── dotfiles/                # Existing dotfiles (unchanged)
│   │   └── default.nix
│   └── profiles/                # Existing profiles (keep)
│       ├── default.nix
│       └── laptop.nix
├── secrets/                     # NEW: Encrypted secrets
│   ├── secrets.yaml             # sops-nix encrypted file
│   └── .sops.yaml              # sops configuration
├── tests/                       # NEW: Integration tests
│   ├── default.nix
│   ├── desktop-boot.nix         # Desktop boots successfully
│   ├── laptop-boot.nix          # Laptop boots successfully
│   └── packages-available.nix   # All packages resolve
├── shells/                      # Dev shells (unchanged)
│   ├── JavaScript.nix
│   ├── Python.nix
│   ├── Rust.nix
│   ├── Golang.nix
│   ├── ESP.nix
│   └── Elixir.nix
├── user-scripts/                # User scripts (unchanged)
│   ├── nixswitch
│   ├── nix-shell-selector.sh
│   ├── nixos-maintenance.sh
│   ├── gaming-nvidia.sh
│   └── textractor.sh
└── dotfiles/                    # Existing dotfiles (unchanged)
    └── ...
```

---

## Phase 1: Add Helper Libraries & Infrastructure

### 1.1 Integrate flake-parts

**Why:** Reduces boilerplate, improves flake organization, better multi-system support

**Changes to `flake.nix`:**

```nix
{
  description = "NixOS configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # NEW: flake-parts for better organization
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # NEW: flake-utils for system handling
    flake-utils.url = "github:numtide/flake-utils";

    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [
        ./lib/flake-module.nix
        ./hosts/flake-module.nix
        ./tests/flake-module.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Development shells
        devShells.default = pkgs.mkShell {
          name = "nixos-config";
          buildInputs = with pkgs; [
            nixpkgs-fmt
            alejandra
            statix
            deadnix
          ];
        };

        # Formatters
        formatter = pkgs.alejandra;
      };
    };
}
```

**Files to create:**
- `lib/flake-module.nix` - Custom lib functions
- `hosts/flake-module.nix` - Host configurations
- `tests/flake-module.nix` - Test definitions

**Lines changed:** ~50 lines in flake.nix (refactor)

---

### 1.2 Create Custom Library Functions

**File: `lib/default.nix`**

```nix
{ lib, inputs, ... }:

{
  # Import all lib modules
  builders = import ./builders.nix { inherit lib inputs; };
  utils = import ./utils.nix { inherit lib; };

  # Re-export commonly used nixpkgs lib functions
  inherit (lib)
    mkIf
    mkDefault
    mkForce
    mkMerge
    mkBefore
    mkAfter
    mkEnableOption
    mkOption
    types
    optionals
    optionalAttrs
    ;
}
```

**File: `lib/builders.nix`**

```nix
{ lib, inputs }:

{
  # Build a NixOS system with sensible defaults
  mkSystem = {
    hostname,
    system ? "x86_64-linux",
    role,
    hardware ? [],
    extraModules ? [],
    nixpkgsInput ? inputs.nixpkgs-unstable,
  }: let
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    pkgs = import nixpkgsInput {
      inherit system;
      config = pkgsConfig;
    };

    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config = pkgsConfig;
    };

    systemVersion = let
      version = nixpkgsInput.lib.version;
      versionParts = builtins.splitVersion version;
      major = builtins.head versionParts;
      minor = builtins.elemAt versionParts 1;
    in "${major}.${minor}";
  in
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs systemVersion hostname pkgs-unstable;
        stablePkgs = pkgs;
      };

      modules = [
        # Base configuration
        {
          nixpkgs.config = pkgsConfig;
          nix.settings = {
            experimental-features = [ "nix-command" "flakes" ];
            auto-optimise-store = true;
          };
          nix.gc = {
            automatic = true;
            dates = "weekly";
            options = "--delete-older-than 7d";
          };
          system.stateVersion = systemVersion;
          networking.hostName = lib.mkDefault hostname;
        }

        # Import all modules
        ../modules

        # Role-based configuration
        { modules.roles.${role}.enable = true; }

        # Hardware modules
      ] ++ hardware ++ extraModules;
    };

  # Helper to create package category modules
  mkPackageCategory = {
    name,
    description ? "packages for ${name}",
    packages,
    extraOptions ? {},
  }: { config, lib, pkgs, pkgs-unstable, ... }: {
    options.modules.packages.${name} = {
      enable = lib.mkEnableOption "${name} packages";
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packages;
        description = "List of ${description}";
      };
    } // extraOptions;

    config = lib.mkIf config.modules.packages.${name}.enable {
      environment.systemPackages = config.modules.packages.${name}.packages;
    };
  };
}
```

**File: `lib/utils.nix`**

```nix
{ lib }:

{
  # Merge multiple attrsets with priority
  mergeWithPriority = priority: attrs:
    lib.mapAttrs (_: v: lib.mkOverride priority v) attrs;

  # Conditional package lists
  pkgsIf = condition: packages:
    if condition then packages else [];

  # Enable multiple options at once
  enableAll = options:
    lib.listToAttrs (map (opt: { name = opt; value = { enable = true; }; }) options);

  # Create GNOME extension list from names
  mkGnomeExtensions = extensions:
    map (ext: "${ext}@gnome-shell-extensions.gcampax.github.com") extensions;
}
```

**File: `lib/flake-module.nix`**

```nix
{ self, lib, ... }:

{
  flake.lib = import ./default.nix { inherit lib; inherit (self) inputs; };
}
```

**Lines to create:** ~150 lines of new helper code

---

### 1.3 Add Secrets Management (sops-nix)

**Add to `flake.nix` inputs:**

```nix
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**File: `modules/secrets/default.nix`**

```nix
{ config, lib, inputs, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.modules.secrets = {
    enable = lib.mkEnableOption "secrets management with sops-nix";
  };

  config = lib.mkIf config.modules.secrets.enable {
    sops = {
      defaultSopsFile = ../../secrets/secrets.yaml;
      age.keyFile = "/var/lib/sops-nix/key.txt";

      # Define secrets here
      secrets = {
        # Example: Tailscale auth key
        "tailscale-auth-key" = {
          owner = "root";
          group = "root";
        };

        # Example: WiFi passwords
        "wifi/home" = {};
        "wifi/work" = {};

        # Example: SSH keys
        "ssh/github-deploy" = {
          owner = "notroot";
          group = "users";
        };
      };
    };
  };
}
```

**File: `secrets/.sops.yaml`**

```yaml
keys:
  # Desktop host key (generate with: ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "")
  - &desktop age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  # Laptop host key
  - &laptop age1yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *desktop
          - *laptop
```

**File: `secrets/secrets.yaml`** (encrypted with sops)

```yaml
# This file will be encrypted. Example structure:
tailscale-auth-key: ENC[AES256_GCM,data:xxxxx,tag:xxxxx]
wifi:
  home: ENC[AES256_GCM,data:xxxxx,tag:xxxxx]
  work: ENC[AES256_GCM,data:xxxxx,tag:xxxxx]
ssh:
  github-deploy: ENC[AES256_GCM,data:xxxxx,tag:xxxxx]
```

**Setup commands:**
```bash
# Install sops
nix-shell -p sops age ssh-to-age

# Generate age key from SSH host key
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Initialize secrets file
sops secrets/secrets.yaml
```

**Lines to create:** ~100 lines for secrets infrastructure

---

## Phase 2: Refactor Module System

### 2.1 Create Role-Based Modules

**Problem:** `hosts/shared/common.nix` (372 lines) contains mixed concerns for all hosts

**Solution:** Extract into role-based modules

**File: `modules/roles/default.nix`**

```nix
{
  imports = [
    ./desktop.nix
    ./laptop.nix
    ./server.nix
    ./minimal.nix
  ];
}
```

**File: `modules/roles/desktop.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  options.modules.roles.desktop = {
    enable = lib.mkEnableOption "desktop workstation role";
  };

  config = lib.mkIf config.modules.roles.desktop.enable {
    # Package selection
    modules.packages = {
      enable = true;
      browsers.enable = true;
      development.enable = true;
      media.enable = true;
      utilities.enable = true;
      audioVideo.enable = true;
      terminal.enable = true;
      gaming.enable = lib.mkDefault true;
      python = {
        enable = true;
        withGTK = true;
      };
    };

    # Desktop environment
    modules.desktop.gnome = {
      enable = true;
      wayland.enable = lib.mkDefault true;
      extensions.productivity = true;
    };

    # Services
    modules.services = {
      syncthing.enable = true;
      printing.enable = true;
      ssh.enable = true;
    };

    # Core configuration
    modules.core = {
      enable = true;
      pipewire = {
        enable = true;
        highQualityAudio = true;
        bluetooth.enable = true;
      };
      fonts.enable = true;
      documentTools.enable = true;
    };

    # Networking
    modules.networking = {
      enable = true;
      optimizeTCP = true;
      dns.enableDNSOverTLS = true;
      firewall = {
        enable = true;
        allowedServices = [ "ssh" ];
      };
    };

    # Dotfiles
    modules.dotfiles.enable = true;

    # Hardware
    hardware = {
      enableRedistributableFirmware = true;
      bluetooth.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
        "networkmanager" "wheel" "audio" "video"
        "disk" "input" "bluetooth" "docker"
        "render" "kvm" "pipewire"
      ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
      dconf.enable = true;
      nix-ld.enable = true;
    };
  };
}
```

**File: `modules/roles/laptop.nix`**

```nix
{ config, lib, ... }:

{
  options.modules.roles.laptop = {
    enable = lib.mkEnableOption "laptop role";
    variant = lib.mkOption {
      type = lib.types.enum [ "standard" "ultrabook" "gaming" "workstation" ];
      default = "standard";
    };
  };

  config = lib.mkIf config.modules.roles.laptop.enable {
    # Import desktop role as base
    modules.roles.desktop.enable = true;

    # Laptop-specific overrides
    modules.hardware.laptop = {
      enable = true;
      powerManagement.profile = lib.mkDefault "balanced";
      batteryManagement.enable = true;
    };

    # Use laptop profile for additional config
    modules.profiles.laptop = {
      enable = true;
      inherit (config.modules.roles.laptop) variant;
    };

    # Laptop-specific networking
    modules.networking = {
      tailscale.enable = lib.mkDefault true;
      firewall.tailscaleCompatible = lib.mkDefault true;
    };

    # Optimize for battery
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 10;
      "vm.laptop_mode" = 5;
    };

    # Enable zram
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };
  };
}
```

**File: `modules/roles/server.nix`** (future use)

```nix
{ config, lib, ... }:

{
  options.modules.roles.server.enable = lib.mkEnableOption "server role";

  config = lib.mkIf config.modules.roles.server.enable {
    # Minimal packages
    modules.packages = {
      enable = true;
      browsers.enable = false;
      development.enable = true;
      gaming.enable = false;
      terminal.enable = true;
    };

    # No desktop environment
    modules.desktop.gnome.enable = false;

    # Server services
    modules.services.ssh = {
      enable = true;
      hardened = true;
    };

    # Networking optimized for server
    modules.networking = {
      enable = true;
      optimizeTCP = true;
      firewall = {
        enable = true;
        allowedServices = [ "ssh" ];
      };
    };
  };
}
```

**File: `modules/roles/minimal.nix`**

```nix
{ config, lib, ... }:

{
  options.modules.roles.minimal.enable = lib.mkEnableOption "minimal installation role";

  config = lib.mkIf config.modules.roles.minimal.enable {
    # Bare minimum packages
    modules.packages = {
      enable = true;
      browsers.enable = false;
      development.enable = false;
      gaming.enable = false;
      terminal.enable = true;
    };

    # Basic services only
    modules.services.ssh.enable = true;

    # Minimal networking
    modules.networking = {
      enable = true;
      firewall.enable = true;
    };
  };
}
```

**Lines to create:** ~300 lines (role modules)
**Lines to delete:** ~372 lines (common.nix)
**Net change:** -72 lines, massive improvement in organization

---

### 2.2 Split Package Modules

**Problem:** `modules/packages/default.nix` is 335 lines, hard to maintain

**Solution:** One file per category with granular options

**File: `modules/packages/default.nix`** (new simplified version)

```nix
{
  imports = [
    ./browsers.nix
    ./development
    ./media.nix
    ./gaming.nix
    ./utilities.nix
    ./audioVideo.nix
    ./terminal.nix
  ];

  options.modules.packages = {
    enable = lib.mkEnableOption "shared packages module";

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional host-specific packages";
    };
  };

  config = lib.mkIf config.modules.packages.enable {
    environment.systemPackages = config.modules.packages.extraPackages;
  };
}
```

**File: `modules/packages/browsers.nix`**

```nix
{ config, lib, pkgs, inputs, ... }:

{
  options.modules.packages.browsers = {
    enable = lib.mkEnableOption "browser packages";

    chrome.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    firefox.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };

    brave.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    zen.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };

    librewolf.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf config.modules.packages.browsers.enable {
    environment.systemPackages = with pkgs;
      lib.optionals config.modules.packages.browsers.chrome.enable [ google-chrome ]
      ++ lib.optionals config.modules.packages.browsers.brave.enable [ brave ]
      ++ lib.optionals config.modules.packages.browsers.librewolf.enable [ librewolf ]
      ++ lib.optionals config.modules.packages.browsers.zen.enable [
        inputs.zen-browser.packages.${pkgs.system}.default
      ];
  };
}
```

**File: `modules/packages/development/default.nix`**

```nix
{
  imports = [
    ./languages.nix
    ./tools.nix
    ./editors.nix
    ./lsp.nix
  ];

  options.modules.packages.development = {
    enable = lib.mkEnableOption "development packages";
  };
}
```

**File: `modules/packages/development/languages.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  options.modules.packages.development.languages = {
    rust.enable = lib.mkEnableOption "Rust toolchain";
    go.enable = lib.mkEnableOption "Go toolchain";
    python.enable = lib.mkEnableOption "Python toolchain";
    node.enable = lib.mkEnableOption "Node.js toolchain";
    java.enable = lib.mkEnableOption "Java toolchain";
  };

  config = let
    cfg = config.modules.packages.development;
  in lib.mkIf config.modules.packages.development.enable {
    environment.systemPackages = with pkgs;
      lib.optionals cfg.languages.rust.enable [ rustc cargo ]
      ++ lib.optionals cfg.languages.go.enable [ go ]
      ++ lib.optionals cfg.languages.python.enable [ python3 ]
      ++ lib.optionals cfg.languages.node.enable [ nodejs ]
      ++ lib.optionals cfg.languages.java.enable [ openjdk ];
  };
}
```

**Similar files for:**
- `development/tools.nix` - Build tools, debuggers, compilers (gcc, cmake, etc)
- `development/editors.nix` - VS Code, Zed, etc
- `development/lsp.nix` - Language servers

**Lines to create:** ~400 lines (split across 10+ files)
**Lines to delete:** ~335 lines (monolithic file)
**Net change:** +65 lines, massive improvement in maintainability

---

### 2.3 Unified Hardware/GPU Management

**Problem:** GPU configuration is manually managed per host, no abstraction

**Solution:** Unified GPU module with automatic driver selection

**File: `modules/hardware/gpu/default.nix`**

```nix
{ config, lib, ... }:

{
  imports = [
    ./amd.nix
    ./nvidia.nix
    ./intel.nix
    ./hybrid.nix
  ];

  options.modules.hardware.gpu = {
    type = lib.mkOption {
      type = lib.types.enum [ "amd" "nvidia" "intel" "hybrid" "none" ];
      default = "none";
      description = "Primary GPU type";
    };

    variant = lib.mkOption {
      type = lib.types.enum [ "hardware" "conservative" "software" ];
      default = "hardware";
      description = "GPU acceleration variant";
    };
  };

  config = {
    # Enable appropriate GPU module based on type
    modules.hardware.gpu.amd.enable = lib.mkIf
      (config.modules.hardware.gpu.type == "amd") true;

    modules.hardware.gpu.nvidia.enable = lib.mkIf
      (config.modules.hardware.gpu.type == "nvidia") true;

    modules.hardware.gpu.intel.enable = lib.mkIf
      (config.modules.hardware.gpu.type == "intel") true;

    modules.hardware.gpu.hybrid.enable = lib.mkIf
      (config.modules.hardware.gpu.type == "hybrid") true;
  };
}
```

**File: `modules/hardware/gpu/amd.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.gpu.amd = {
    enable = lib.mkEnableOption "AMD GPU configuration";

    model = lib.mkOption {
      type = lib.types.enum [ "navi10" "navi21" "rdna3" "other" ];
      default = "other";
    };
  };

  config = lib.mkIf config.modules.hardware.gpu.amd.enable {
    # Import existing amd-gpu.nix configuration
    modules.hardware.amdgpu = {
      enable = true;
      inherit (config.modules.hardware.gpu.amd) model;
    };

    # Set environment variables
    environment.variables = {
      VDPAU_DRIVER = "radeonsi";
      LIBVA_DRIVER_NAME = "radeonsi";
      AMD_VULKAN_ICD = "RADV";
    };

    # Variant-specific kernel params
    boot.kernelParams = lib.mkMerge [
      (lib.mkIf (config.modules.hardware.gpu.variant == "hardware") [
        "amdgpu.dc=1"
        "amdgpu.dpm=1"
      ])
      (lib.mkIf (config.modules.hardware.gpu.variant == "software") [
        "nomodeset"
        "amdgpu.modeset=0"
      ])
    ];
  };
}
```

**File: `modules/hardware/gpu/hybrid.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  options.modules.hardware.gpu.hybrid = {
    enable = lib.mkEnableOption "hybrid graphics (NVIDIA + Intel)";

    mode = lib.mkOption {
      type = lib.types.enum [ "offload" "sync" "reverse-sync" ];
      default = "offload";
      description = "NVIDIA Prime mode";
    };

    intelBusId = lib.mkOption {
      type = lib.types.str;
      example = "PCI:0:2:0";
    };

    nvidiaBusId = lib.mkOption {
      type = lib.types.str;
      example = "PCI:1:0:0";
    };
  };

  config = lib.mkIf config.modules.hardware.gpu.hybrid.enable {
    # Enable both drivers
    hardware.nvidia = {
      modesetting.enable = true;
      prime = {
        inherit (config.modules.hardware.gpu.hybrid) intelBusId nvidiaBusId;

        offload.enable = config.modules.hardware.gpu.hybrid.mode == "offload";
        sync.enable = config.modules.hardware.gpu.hybrid.mode == "sync";
        reverseSync.enable = config.modules.hardware.gpu.hybrid.mode == "reverse-sync";
      };
    };

    # Intel configuration
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [ intel-media-driver ];
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
```

**Lines to create:** ~250 lines (GPU abstraction)
**Lines changed in hosts:** ~50 lines simplified

---

### 2.4 Split GNOME Configuration

**Problem:** GNOME settings scattered across multiple files

**Solution:** Dedicated GNOME module directory

**File: `modules/desktop/gnome/default.nix`**

```nix
{
  imports = [
    ./base.nix
    ./extensions.nix
    ./settings.nix
    ./wayland.nix
  ];
}
```

**File: `modules/desktop/gnome/base.nix`**

```nix
{ config, lib, pkgs, ... }:

{
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";
  };

  config = lib.mkIf config.modules.desktop.gnome.enable {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    # Base GNOME packages
    environment.systemPackages = with pkgs; [
      gnome-text-editor
      gnome-calculator
      gnome-calendar
      gnome-tweaks
      gnome-extension-manager
      dconf-editor
    ];

    # GNOME services
    services.gnome = {
      core-shell.enable = true;
      core-os-services.enable = true;
      gnome-keyring.enable = true;
      sushi.enable = true;
    };
  };
}
```

**File: `modules/desktop/gnome/extensions.nix`** - Extension management
**File: `modules/desktop/gnome/settings.nix`** - dconf/gsettings
**File: `modules/desktop/gnome/wayland.nix`** - Wayland-specific config

**Lines to create:** ~200 lines (GNOME split)
**Lines to delete:** ~150 lines (old gnome.nix + duplicates)

---

### 2.5 Extract Services from common.nix

**File: `modules/services/syncthing.nix`**

```nix
{ config, lib, ... }:

{
  options.modules.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing file synchronization";

    user = lib.mkOption {
      type = lib.types.str;
      default = "notroot";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.modules.services.syncthing.user}/Sync";
    };
  };

  config = lib.mkIf config.modules.services.syncthing.enable {
    services.syncthing = {
      enable = true;
      inherit (config.modules.services.syncthing) user dataDir;
      configDir = "/home/${config.modules.services.syncthing.user}/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };
  };
}
```

**Similar modules:**
- `services/ssh.nix` - SSH server
- `services/printing.nix` - Printing services
- `services/docker.nix` - Docker daemon

**Lines to create:** ~150 lines (service modules)

---

## Phase 3: Simplify Host Configurations

### 3.1 New Desktop Configuration

**File: `hosts/default/configuration.nix`** (NEW - simplified)

```nix
{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Role-based configuration (replaces common.nix import)
  modules.roles.desktop.enable = true;

  # Hardware configuration
  modules.hardware.gpu = {
    type = "amd";
    variant = "hardware";
    amd.model = "navi10"; # RX 5700 XT
  };

  # Desktop-specific settings
  modules.networking = {
    hostName = "nixos-desktop";
    remoteDesktop = {
      enable = true;
      server.enable = true;
    };
    firewall.developmentPorts = [ 3000 ];
  };

  # Enable gaming
  modules.packages.gaming.enable = true;
  modules.core.gaming.enable = true;

  # Performance tuning
  powerManagement.cpuFreqGovernor = "performance";

  boot = {
    tmp.useTmpfs = true;
    kernel.sysctl = {
      "vm.swappiness" = 1;
      "vm.dirty_ratio" = 10;
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };
}
```

**Lines before:** ~200 lines
**Lines after:** ~45 lines
**Reduction:** 77% fewer lines!

---

### 3.2 New Laptop Configuration

**File: `hosts/laptop/configuration.nix`** (NEW - simplified)

```nix
{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Role-based configuration
  modules.roles.laptop = {
    enable = true;
    variant = "standard"; # or "gaming", "ultrabook", "workstation"
  };

  # Hardware configuration
  modules.hardware.gpu = {
    type = "hybrid"; # Intel + NVIDIA
    hybrid = {
      mode = "offload"; # or disable for Intel-only
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Laptop-specific settings
  modules.networking = {
    hostName = "nixos-laptop";
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    firewall = {
      developmentPorts = [ 3000 8080 ];
      tailscaleCompatible = true;
    };
  };

  # GNOME with X11 for NVIDIA
  modules.desktop.gnome.wayland.enable = lib.mkForce false;

  # Laptop-specific packages
  modules.packages.extraPackages = with pkgs; [
    claude-code
    nvidia-system-monitor-qt
    nvtopPackages.full
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    plymouth.enable = true;
    kernelParams = [ "quiet" "splash" ];
  };
}
```

**Lines before:** ~276 lines
**Lines after:** ~55 lines
**Reduction:** 80% fewer lines!

---

### 3.3 Update Flake Host Definitions

**File: `hosts/flake-module.nix`** (NEW)

```nix
{ self, inputs, ... }:

{
  flake.nixosConfigurations = let
    lib = self.lib;
  in {
    # Desktop system
    default = lib.builders.mkSystem {
      hostname = "nixos-desktop";
      system = "x86_64-linux";
      role = "desktop";
      hardware = [ ./default/hardware-configuration.nix ];
      extraModules = [ ./default/configuration.nix ];
    };

    # Laptop system
    laptop = lib.builders.mkSystem {
      hostname = "nixos-laptop";
      system = "x86_64-linux";
      role = "laptop";
      hardware = [ ./laptop/hardware-configuration.nix ];
      extraModules = [ ./laptop/configuration.nix ];
    };

    # Compatibility alias
    nixos = self.nixosConfigurations.default;
  };
}
```

**Lines changed:** ~30 lines in flake structure

---

## Phase 4: Add Testing Infrastructure

### 4.1 NixOS Integration Tests

**File: `tests/flake-module.nix`**

```nix
{ self, ... }:

{
  perSystem = { pkgs, ... }: {
    checks = {
      # Test desktop boots
      desktop-boot = import ./desktop-boot.nix { inherit pkgs self; };

      # Test laptop boots
      laptop-boot = import ./laptop-boot.nix { inherit pkgs self; };

      # Test packages resolve
      packages-available = import ./packages-available.nix { inherit pkgs self; };

      # Nix formatting check
      formatting = pkgs.runCommand "check-format" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${self}
        touch $out
      '';

      # Dead code detection
      deadnix-check = pkgs.runCommand "check-deadnix" {} ''
        ${pkgs.deadnix}/bin/deadnix --fail ${self}
        touch $out
      '';
    };
  };
}
```

**File: `tests/desktop-boot.nix`**

```nix
{ pkgs, self, ... }:

pkgs.nixosTest {
  name = "desktop-boots-successfully";

  nodes.machine = {
    imports = [ self.nixosConfigurations.default.config ];
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("gdm.service")
    machine.succeed("gnome-shell --version")
    machine.succeed("systemctl is-active pipewire")
  '';
}
```

**File: `tests/laptop-boot.nix`** - Similar for laptop

**File: `tests/packages-available.nix`**

```nix
{ pkgs, self, ... }:

pkgs.runCommand "check-packages" {} ''
  # Check that key packages are available
  ${pkgs.google-chrome}/bin/google-chrome-stable --version
  ${pkgs.vscode}/bin/code --version
  ${pkgs.zed-editor}/bin/zed --version

  touch $out
''
```

**Run tests:**
```bash
nix flake check  # Run all checks
nix build .#checks.x86_64-linux.desktop-boot  # Run specific test
```

**Lines to create:** ~150 lines (test infrastructure)

---

## Phase 5: Migration & Deployment

### 5.1 Migration Steps

**Step-by-step migration process:**

1. **Backup current system**
   ```bash
   sudo nixos-rebuild build --flake .#default
   git commit -am "Backup: Working configuration before refactor"
   git tag backup-$(date +%Y%m%d)
   ```

2. **Create feature branch**
   ```bash
   git checkout -b refactor/architecture-v2
   ```

3. **Phase 1: Add helpers** (Day 1)
   - Add flake-parts to inputs
   - Create `lib/` directory
   - Add sops-nix
   - Test: `nix flake check`

4. **Phase 2: Create roles** (Day 2-3)
   - Create `modules/roles/`
   - Extract desktop role from common.nix
   - Extract laptop role
   - Test builds: `nix build .#nixosConfigurations.default.config.system.build.toplevel`

5. **Phase 3: Split packages** (Day 3-4)
   - Create `modules/packages/` structure
   - Split by category
   - Update imports
   - Test: `nix flake check`

6. **Phase 4: GPU abstraction** (Day 5)
   - Create `modules/hardware/gpu/`
   - Migrate AMD config
   - Migrate hybrid config
   - Test on both hosts

7. **Phase 5: Simplify hosts** (Day 6)
   - Update desktop config
   - Update laptop config
   - Delete common.nix
   - Test rebuilds on both systems

8. **Phase 6: Add tests** (Day 7)
   - Create test infrastructure
   - Run validation tests
   - Fix any issues

9. **Phase 7: Deploy** (Day 8)
   ```bash
   # Test on desktop first
   sudo nixos-rebuild test --flake .#default

   # If successful, switch
   sudo nixos-rebuild switch --flake .#default

   # Repeat for laptop
   sudo nixos-rebuild switch --flake .#laptop
   ```

10. **Merge to develop**
    ```bash
    git checkout develop
    git merge refactor/architecture-v2
    git push origin develop
    ```

---

### 5.2 Rollback Plan

If anything breaks during migration:

```bash
# Boot into previous generation
sudo nixos-rebuild switch --rollback

# Or from GRUB menu, select previous generation

# Restore from git tag
git checkout backup-20251005
sudo nixos-rebuild switch --flake .#default
```

---

## Summary of Changes

### Files to Create (New)

| File | Lines | Purpose |
|------|-------|---------|
| `lib/default.nix` | 30 | Library exports |
| `lib/builders.nix` | 80 | System builders |
| `lib/utils.nix` | 40 | Utility functions |
| `lib/flake-module.nix` | 10 | Flake-parts integration |
| `modules/roles/default.nix` | 10 | Role imports |
| `modules/roles/desktop.nix` | 100 | Desktop role |
| `modules/roles/laptop.nix` | 60 | Laptop role |
| `modules/roles/server.nix` | 50 | Server role |
| `modules/roles/minimal.nix` | 40 | Minimal role |
| `modules/secrets/default.nix` | 50 | Secrets management |
| `secrets/.sops.yaml` | 20 | Sops config |
| `modules/packages/browsers.nix` | 50 | Browser packages |
| `modules/packages/development/default.nix` | 15 | Dev imports |
| `modules/packages/development/languages.nix` | 50 | Language toolchains |
| `modules/packages/development/tools.nix` | 60 | Dev tools |
| `modules/packages/development/editors.nix` | 40 | Editors |
| `modules/packages/development/lsp.nix` | 50 | Language servers |
| `modules/hardware/gpu/default.nix` | 40 | GPU abstraction |
| `modules/hardware/gpu/amd.nix` | 60 | AMD config |
| `modules/hardware/gpu/nvidia.nix` | 60 | NVIDIA config |
| `modules/hardware/gpu/intel.nix` | 40 | Intel config |
| `modules/hardware/gpu/hybrid.nix` | 70 | Hybrid graphics |
| `modules/desktop/gnome/default.nix` | 10 | GNOME imports |
| `modules/desktop/gnome/base.nix` | 60 | GNOME base |
| `modules/desktop/gnome/extensions.nix` | 50 | Extensions |
| `modules/desktop/gnome/settings.nix` | 40 | Settings |
| `modules/desktop/gnome/wayland.nix` | 30 | Wayland config |
| `modules/services/syncthing.nix` | 35 | Syncthing service |
| `modules/services/ssh.nix` | 40 | SSH service |
| `modules/services/printing.nix` | 30 | Printing service |
| `modules/services/docker.nix` | 25 | Docker service |
| `hosts/flake-module.nix` | 30 | Host definitions |
| `tests/flake-module.nix` | 30 | Test definitions |
| `tests/desktop-boot.nix` | 25 | Desktop test |
| `tests/laptop-boot.nix` | 25 | Laptop test |
| `tests/packages-available.nix` | 20 | Package test |
| **Total New** | **1,480** | |

### Files to Delete

| File | Lines | Reason |
|------|-------|--------|
| `hosts/shared/common.nix` | 372 | Replaced by roles |
| `modules/packages/default.nix` (old) | 335 | Split into categories |
| `modules/desktop/gnome.nix` | 80 | Split into subdirectory |
| **Total Deleted** | **787** | |

### Files to Modify

| File | Current Lines | New Lines | Change |
|------|---------------|-----------|--------|
| `flake.nix` | 218 | 50 | -168 (simplified with flake-parts) |
| `hosts/default/configuration.nix` | 200 | 45 | -155 (role-based) |
| `hosts/laptop/configuration.nix` | 276 | 55 | -221 (role-based) |
| **Total Modified** | **694** | **150** | **-544** |

### Net Change Summary

- **New files:** 36 files, ~1,480 lines
- **Deleted files:** 3 files, ~787 lines
- **Modified files:** 3 files, reduced by ~544 lines
- **Net change:** +693 lines across 36 new modular files
- **Maintainability:** Massively improved - split into focused, single-purpose modules
- **Host configs:** Reduced by 77-80%

---

## Recommended Nix Helper Libraries

Based on research, here are the recommended libraries:

### 1. **flake-parts** ⭐ (RECOMMENDED)
- **URL:** `github:hercules-ci/flake-parts`
- **Purpose:** Simplify flake structure using module system
- **Benefits:**
  - Modular flake organization
  - Reduces boilerplate
  - Better multi-system support
  - Familiar module syntax

### 2. **flake-utils** ⭐ (RECOMMENDED)
- **URL:** `github:numtide/flake-utils`
- **Purpose:** Multi-system utilities
- **Benefits:**
  - `eachDefaultSystem` for easy multi-platform
  - Pure Nix functions, no nixpkgs dependency
  - Minimal and focused

### 3. **sops-nix** ⭐ (RECOMMENDED)
- **URL:** `github:Mic92/sops-nix`
- **Purpose:** Secrets management
- **Benefits:**
  - Encrypt secrets in git
  - Age or GPG encryption
  - Per-host key management
  - Automatic secret deployment

### 4. **snowfall-lib** (OPTIONAL)
- **URL:** `github:snowfallorg/lib`
- **Purpose:** Opinionated flake structure
- **Benefits:**
  - Convention over configuration
  - Automatic namespace handling
  - Good for large configs
- **Trade-off:** Very opinionated, may be overkill

### 5. **nixpkgs.lib extensions** (BUILT-IN)
- Use `lib.extend` for custom functions
- No external dependency
- Access to all nixpkgs.lib functions
- Recommended for project-specific helpers

**Recommended Stack:**
```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  flake-parts.url = "github:hercules-ci/flake-parts";
  flake-utils.url = "github:numtide/flake-utils";
  sops-nix.url = "github:Mic92/sops-nix";
};
```

---

## Implementation Tasks

This section breaks down the refactoring into **small, atomic tasks** that:
- ✅ Keep the system working at all times
- ✅ Can be tested independently
- ✅ Can be committed and pushed to GitHub after each task
- ✅ Allow rollback at any point

### Task Tracking

**Branch Strategy:**
- Create feature branch: `refactor/architecture-v2`
- Each task = 1 commit
- Push to GitHub after each successful task
- Test rebuild before moving to next task

**Validation Command (run after each task):**
```bash
# Validate syntax
nix flake check

# Test build (don't switch)
sudo nixos-rebuild build --flake .#default

# If successful, commit and push
git add .
git commit -m "task(X): description"
git push origin refactor/architecture-v2
```

---

### Milestone 1: Foundation & Helpers ✅ COMPLETE

**Status:** ✅ All 6 tasks completed (October 6, 2025)
**Branch:** refactor/architecture-v2
**Commits:** 4 commits pushed

**Safe, No Breaking Changes**

#### Task 1.1: Backup Current System ✓
**Estimated time:** 10 minutes
**Risk:** None (backup only)

```bash
# Create backup
sudo nixos-rebuild build --flake .#default
git commit -am "backup: Working configuration before refactor"
git tag backup-$(date +%Y%m%d)
git push origin --tags

# Create feature branch
git checkout -b refactor/architecture-v2
```

**Validation:** Tag created, branch created
**Commit:** `backup: Working configuration before refactor`

---

#### Task 1.2: Add flake-parts Input ✓
**Estimated time:** 15 minutes
**Risk:** Low (just adds input, no usage yet)

**Changes:**
1. Edit `flake.nix` inputs section:
```nix
flake-parts = {
  url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs-lib.follows = "nixpkgs";
};
```

2. Run `nix flake lock` to update lockfile

**Validation:**
```bash
nix flake lock
nix flake show  # Should show flake structure
```

**Commit:** `feat(flake): add flake-parts input`

---

#### Task 1.3: Add flake-utils Input ✓
**Estimated time:** 10 minutes
**Risk:** Low (just adds input)

**Changes:**
```nix
flake-utils.url = "github:numtide/flake-utils";
```

**Validation:**
```bash
nix flake lock
nix flake show
```

**Commit:** `feat(flake): add flake-utils input`

---

#### Task 1.4: Create lib Directory Structure ✓
**Estimated time:** 20 minutes
**Risk:** None (new files, not used yet)

**Changes:**
1. Create `lib/default.nix` (empty for now)
2. Create `lib/builders.nix` (empty for now)
3. Create `lib/utils.nix` (empty for now)
4. Create `lib/flake-module.nix`:

```nix
{ self, lib, ... }:

{
  flake.lib = import ./default.nix {
    inherit lib;
    inherit (self) inputs;
  };
}
```

**Validation:**
```bash
nix flake check
# Should pass - no functional changes yet
```

**Commit:** `feat(lib): create library directory structure`

---

#### Task 1.5: Add Core Lib Functions ✓
**Estimated time:** 30 minutes
**Risk:** Low (functions not used yet)

**Changes:**
Populate `lib/default.nix`, `lib/utils.nix`, `lib/builders.nix` with code from plan

**Validation:**
```bash
nix flake check
nix eval .#lib.utils --apply builtins.attrNames  # Should show function names
```

**Commit:** `feat(lib): implement core library functions`

---

#### Task 1.6: Add sops-nix Input (Optional) ✓
**Estimated time:** 15 minutes
**Risk:** Low (input only, no usage)

**Changes:**
```nix
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

**Validation:**
```bash
nix flake lock
```

**Commit:** `feat(flake): add sops-nix for secrets management`

---

### Milestone 2: Modular Services ✅ COMPLETE

**Status:** ✅ All 4 tasks completed (October 6, 2025)
**Branch:** refactor/architecture-v2
**Commits:** 4 commits pushed

**No Impact on Existing Config**

#### Task 2.1: Create Services Directory ✓
**Estimated time:** 15 minutes
**Risk:** None (new module, not enabled)

**Changes:**
1. Create `modules/services/default.nix`:
```nix
{
  imports = [
    ./syncthing.nix
    ./ssh.nix
    ./printing.nix
    ./docker.nix
  ];
}
```

2. Update `modules/default.nix` to import services:
```nix
imports = [
  ./core
  ./packages
  ./networking
  ./desktop
  ./dotfiles
  ./hardware
  ./profiles
  ./services  # NEW
];
```

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(services): create services module directory`

---

#### Task 2.2: Extract Syncthing Service ✓
**Estimated time:** 20 minutes
**Risk:** Low (parallel implementation)

**Changes:**
1. Create `modules/services/syncthing.nix` (code from plan)
2. Keep original in `common.nix` (parallel implementation)

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(services): add modular syncthing service`

---

#### Task 2.3: Extract SSH Service ✓
**Estimated time:** 20 minutes
**Risk:** Low

**Changes:** Create `modules/services/ssh.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(services): add modular ssh service`

---

#### Task 2.4: Extract Printing Service ✓
**Estimated time:** 20 minutes
**Risk:** Low

**Changes:** Create `modules/services/printing.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(services): add modular printing service`

---

### Milestone 3: Role System (Parallel to Existing)

#### Task 3.1: Create Roles Directory ✓
**Estimated time:** 15 minutes
**Risk:** None

**Changes:**
1. Create `modules/roles/default.nix`
2. Update `modules/default.nix` to import roles

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(roles): create roles module directory`

---

#### Task 3.2: Create Desktop Role (Disabled by Default) ✓
**Estimated time:** 45 minutes
**Risk:** Low (not enabled yet)

**Changes:**
1. Create `modules/roles/desktop.nix` with full implementation
2. Set `enable = lib.mkEnableOption` (defaults to false)

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
# Desktop role exists but not enabled - no change to system
```

**Commit:** `feat(roles): add desktop role module`

---

#### Task 3.3: Create Laptop Role (Disabled by Default) ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Create `modules/roles/laptop.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(roles): add laptop role module`

---

#### Task 3.4: Create Server and Minimal Roles ✓
**Estimated time:** 30 minutes
**Risk:** None (future use)

**Changes:** Create `modules/roles/server.nix` and `minimal.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(roles): add server and minimal roles`

---

### Milestone 4: GPU Abstraction (Parallel Implementation)

#### Task 4.1: Create GPU Module Directory ✓
**Estimated time:** 15 minutes
**Risk:** None

**Changes:**
1. Create `modules/hardware/gpu/default.nix`
2. Update `modules/hardware/default.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(hardware): create GPU module directory`

---

#### Task 4.2: Implement AMD GPU Module ✓
**Estimated time:** 30 minutes
**Risk:** Low (not enabled)

**Changes:** Create `modules/hardware/gpu/amd.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(hardware): add AMD GPU module`

---

#### Task 4.3: Implement Hybrid GPU Module ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Create `modules/hardware/gpu/hybrid.nix`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `feat(hardware): add hybrid GPU module`

---

#### Task 4.4: Implement Intel and NVIDIA GPU Modules ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Create `intel.nix` and `nvidia.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(hardware): add Intel and NVIDIA GPU modules`

---

### Milestone 5: Split Package Modules (Parallel)

#### Task 5.1: Create New Packages Directory Structure ✓
**Estimated time:** 20 minutes
**Risk:** None

**Changes:**
1. Create `modules/packages-new/` directory (temporary)
2. Create `modules/packages-new/default.nix`
3. Do NOT modify existing `modules/packages/`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(packages): create new package module structure`

---

#### Task 5.2: Split Browser Packages ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Create `modules/packages-new/browsers.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(packages): add modular browsers package`

---

#### Task 5.3: Split Development Packages ✓
**Estimated time:** 45 minutes
**Risk:** Low

**Changes:**
1. Create `modules/packages-new/development/` directory
2. Create `default.nix`, `languages.nix`, `tools.nix`, `editors.nix`, `lsp.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(packages): add modular development packages`

---

#### Task 5.4: Split Media, Gaming, Utilities Packages ✓
**Estimated time:** 45 minutes
**Risk:** Low

**Changes:** Create `media.nix`, `gaming.nix`, `utilities.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(packages): add modular media, gaming, utilities packages`

---

#### Task 5.5: Split Audio/Video and Terminal Packages ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Create `audioVideo.nix`, `terminal.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(packages): add modular audioVideo and terminal packages`

---

### Milestone 6: GNOME Module Split (Parallel)

#### Task 6.1: Create GNOME Subdirectory ✓
**Estimated time:** 20 minutes
**Risk:** None

**Changes:**
1. Create `modules/desktop/gnome-new/` directory
2. Create `default.nix`, `base.nix`, `extensions.nix`, `settings.nix`, `wayland.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(desktop): create modular GNOME structure`

---

#### Task 6.2: Implement GNOME Base Module ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:** Populate `modules/desktop/gnome-new/base.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(desktop): implement GNOME base module`

---

#### Task 6.3: Implement GNOME Extensions, Settings, Wayland ✓
**Estimated time:** 45 minutes
**Risk:** Low

**Changes:** Populate remaining GNOME modules

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(desktop): implement GNOME extensions, settings, wayland modules`

---

### Milestone 7: Testing Infrastructure (Safe Addition)

#### Task 7.1: Create Tests Directory ✓
**Estimated time:** 20 minutes
**Risk:** None

**Changes:**
1. Create `tests/` directory
2. Create `tests/flake-module.nix`
3. Update flake to import tests

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(tests): add testing infrastructure`

---

#### Task 7.2: Add Formatting and Linting Tests ✓
**Estimated time:** 30 minutes
**Risk:** None (might fail, but won't break system)

**Changes:**
1. Create formatting check
2. Create deadnix check

**Validation:**
```bash
nix flake check
# May show formatting issues - that's OK
```

**Commit:** `feat(tests): add formatting and linting checks`

---

#### Task 7.3: Add Boot Tests ✓
**Estimated time:** 45 minutes
**Risk:** Low (VM tests only)

**Changes:**
1. Create `tests/desktop-boot.nix`
2. Create `tests/laptop-boot.nix`

**Validation:**
```bash
nix build .#checks.x86_64-linux.desktop-boot
```

**Commit:** `feat(tests): add boot validation tests`

---

### Milestone 8: Secrets Management (Optional, Safe)

#### Task 8.1: Create Secrets Directory Structure ✓
**Estimated time:** 20 minutes
**Risk:** None

**Changes:**
1. Create `secrets/` directory
2. Create `secrets/.sops.yaml`
3. Create `modules/secrets/default.nix` (disabled by default)

**Validation:**
```bash
nix flake check
```

**Commit:** `feat(secrets): add sops-nix secrets infrastructure`

---

#### Task 8.2: Initialize Secrets File ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:**
1. Generate age keys
2. Create `secrets/secrets.yaml`
3. Add example secrets (not sensitive)

**Validation:**
```bash
sops secrets/secrets.yaml  # Should open in editor
```

**Commit:** `feat(secrets): initialize secrets file with sops`

---

### Milestone 8.5: Dotfiles Enhancement ✅ COMPLETE

**Status:** ✅ All 8 tasks completed (October 6, 2025)
**Branch:** refactor/architecture-v2
**Commits:** 9 commits pushed

**Note:** These tasks enhance the existing dotfiles system. They can be done in parallel with other milestones.

#### Task 8.5.1: Initialize Dotfiles Properly ✓
**Estimated time:** 15 minutes
**Risk:** None (just initialization)

**Problem:** Chezmoi configured in repo but not initialized for user

**Changes:**
```bash
# Run initialization
dotfiles-init

# Verify it worked
dotfiles-status
chezmoi managed
```

**Validation:**
```bash
# Should exist now
cat ~/.config/chezmoi/chezmoi.toml
chezmoi status
```

**Commit:** `fix(dotfiles): properly initialize chezmoi for user`

---

#### Task 8.5.2: Make Dotfiles Paths Portable ✓
**Estimated time:** 20 minutes
**Risk:** Low (makes system more flexible)

**Changes:**
1. Update `modules/dotfiles/default.nix`:

```nix
options.modules.dotfiles = {
  enable = mkEnableOption "dotfiles management with chezmoi";

  username = mkOption {
    type = types.str;
    default = "notroot";
    description = "Username for dotfiles management";
  };

  projectDir = mkOption {
    type = types.str;
    default = "NixOS";
    description = "Name of NixOS project directory in user home";
  };

  enableHelperScripts = mkOption {
    type = types.bool;
    default = true;
    description = "Install helper scripts for dotfiles management";
  };
};
```

2. Update path references:
```nix
dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";
```

3. Update `.chezmoi.toml` template in init script to use variable

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `refactor(dotfiles): make paths portable and configurable`

---

#### Task 8.5.3: Convert SSH Config to Template ✓
**Estimated time:** 30 minutes
**Risk:** Low (parallel implementation)

**Problem:** SSH config has all hosts on all machines, no per-host customization

**Changes:**
1. Rename: `dotfiles/dot_ssh/config` → `dotfiles/dot_ssh/config.tmpl`

2. Add host detection to `.chezmoi.toml`:
```toml
[data]
    hostname = "{{ .chezmoi.hostname }}"
    username = "{{ .chezmoi.username }}"
    os = "{{ .chezmoi.os }}"
    arch = "{{ .chezmoi.arch }}"

    # NEW: Host type detection
    isDesktop = {{ if eq .chezmoi.hostname "nixos-desktop" }}true{{ else }}false{{ end }}
    isLaptop = {{ if eq .chezmoi.hostname "nixos-laptop" }}true{{ else }}false{{ end }}
```

3. Convert SSH config to template:
```ssh-config
# SSH Configuration
# Generated for: {{ .hostname }}

# Common hosts (all machines)
Host github.com
  User git
  IdentityFile ~/.ssh/github_key
  IdentitiesOnly yes

Host ssh.dev.azure.com
  User git
  IdentityFile ~/.ssh/azure_key
  IdentitiesOnly yes

{{- if .isDesktop }}
# Desktop-only: Home infrastructure
Host ProxMox.Home301Server
  HostName 192.168.1.10
  User root
  IdentityFile ~/.ssh/proxmox_key
  SetEnv TERM=xterm-256color

Host ProxMox.PlexVM
  HostName 192.168.1.144
  User notroot
  IdentityFile ~/.ssh/proxmox_vm_105
  ServerAliveInterval 60
{{- end }}

{{- if .isLaptop }}
# Laptop-only: Mobile/work configurations
# Add laptop-specific hosts here
{{- end }}

# Development hosts (all machines)
Host pi
  HostName 192.168.1.124
  User pi
  IdentityFile ~/.ssh/delicasa_pi_key
  SetEnv TERM=xterm-256color
```

**Validation:**
```bash
# Apply and check
dotfiles-apply
cat ~/.ssh/config  # Should have templated content
ssh -G github.com  # Verify config is valid
```

**Commit:** `feat(dotfiles): convert SSH config to host-specific template`

---

#### Task 8.5.4: Convert Git Config to Template ✓
**Estimated time:** 20 minutes
**Risk:** Low

**Changes:**
1. Rename: `dotfiles/dot_gitconfig` → `dotfiles/dot_gitconfig.tmpl`

2. Create template:
```gitconfig
[user]
{{- if .isDesktop }}
    name = Pedro Balbino
    email = personal@example.com
{{- else if .isLaptop }}
    name = Pedro Balbino
    email = work@example.com
{{- end }}
    signingkey = ~/.ssh/github_key.pub

[core]
    editor = {{ if lookPath "code" }}code --wait{{ else if lookPath "zed" }}zed --wait{{ else }}nvim{{ end }}
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = true

[push]
    autoSetupRemote = true

[commit]
    gpgsign = true

[gpg]
    format = ssh

[gpg "ssh"]
    allowedSignersFile = ~/.ssh/allowed_signers
```

**Validation:**
```bash
dotfiles-apply
git config --list  # Verify config
```

**Commit:** `feat(dotfiles): add host-specific git configuration template`

---

#### Task 8.5.5: Add Missing Essential Dotfiles ✓
**Estimated time:** 25 minutes
**Risk:** None (new files)

**Changes:**

1. Create `dotfiles/dot_gitignore_global`:
```gitignore
# OS-specific
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# Editors
.vscode/
.idea/
*.code-workspace

# Build artifacts
node_modules/
target/
dist/
build/
*.pyc
__pycache__/
.pytest_cache/

# Secrets
.env
.env.local
*.pem
*.key
!**/*.pub
```

2. Create `dotfiles/dot_editorconfig`:
```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,jsx,tsx,json,yml,yaml}]
indent_style = space
indent_size = 2

[*.{py,rs,go}]
indent_style = space
indent_size = 4

[*.nix]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

3. Create `dotfiles/dot_curlrc`:
```
# Follow redirects
--location

# Show progress bar
--progress-bar

# Retry on failure
--retry 3
--retry-delay 2
```

4. Update git config to use global gitignore:
```gitconfig
[core]
    excludesfile = ~/.gitignore_global
```

**Validation:**
```bash
dotfiles-apply
cat ~/.gitignore_global
cat ~/.editorconfig
```

**Commit:** `feat(dotfiles): add essential dotfiles (gitignore, editorconfig, curlrc)`

---

#### Task 8.5.6: Add Dotfiles Validation Script ✓
**Estimated time:** 30 minutes
**Risk:** None (new feature)

**Changes:**

Add to `modules/dotfiles/default.nix`:

```nix
# Validation script
checkScript = pkgs.writeShellScriptBin "dotfiles-check" ''
  #!/usr/bin/env bash
  set -euo pipefail

  echo "🔍 Validating dotfiles configuration..."
  ERRORS=0

  # Check zsh syntax
  if [[ -f ~/.zshrc ]]; then
    echo "  Checking zsh configuration..."
    if ! zsh -n ~/.zshrc 2>/dev/null; then
      echo "  ❌ Invalid zsh configuration"
      ERRORS=$((ERRORS + 1))
    else
      echo "  ✅ zsh configuration valid"
    fi
  fi

  # Check SSH config syntax
  if [[ -f ~/.ssh/config ]]; then
    echo "  Checking SSH configuration..."
    if ! ssh -G localhost &>/dev/null; then
      echo "  ❌ Invalid SSH configuration"
      ERRORS=$((ERRORS + 1))
    else
      echo "  ✅ SSH configuration valid"
    fi
  fi

  # Check git config
  echo "  Checking git configuration..."
  if ! git config --list &>/dev/null; then
    echo "  ❌ Invalid git configuration"
    ERRORS=$((ERRORS + 1))
  else
    echo "  ✅ git configuration valid"
  fi

  # Check for required git settings
  if ! git config user.name &>/dev/null; then
    echo "  ⚠️  Warning: git user.name not set"
  fi

  if ! git config user.email &>/dev/null; then
    echo "  ⚠️  Warning: git user.email not set"
  fi

  if [[ $ERRORS -eq 0 ]]; then
    echo "✅ All dotfiles validation passed!"
    exit 0
  else
    echo "❌ Dotfiles validation failed with $ERRORS error(s)"
    exit 1
  fi
'';
```

Add to systemPackages:
```nix
environment.systemPackages = [
  pkgs.chezmoi
  checkScript  # NEW
] ++ (optionals cfg.enableHelperScripts [
  # ... existing scripts
]);
```

Update applyScript to run validation:
```nix
applyScript = pkgs.writeShellScriptBin "dotfiles-apply" ''
  #!/usr/bin/env bash
  set -euo pipefail

  DOTFILES_DIR="${dotfilesPath}"

  if [[ ! -d "$DOTFILES_DIR" ]]; then
      echo "❌ Dotfiles directory not found: $DOTFILES_DIR"
      echo "Run 'dotfiles-init' first."
      exit 1
  fi

  echo "🔄 Applying dotfiles from: $DOTFILES_DIR"

  # Show diff if requested
  if [[ "''${1:-}" == "--diff" ]]; then
      chezmoi diff --no-pager
      exit 0
  fi

  # Apply changes
  chezmoi apply

  # Run validation
  echo ""
  ${checkScript}/bin/dotfiles-check

  echo "✅ Dotfiles applied successfully!"
'';
```

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
dotfiles-check  # New command
```

**Commit:** `feat(dotfiles): add validation script for dotfiles`

---

#### Task 8.5.7: Integrate Dotfiles with Secrets (Optional) ✓
**Estimated time:** 30 minutes
**Risk:** Low (requires Task 8.2 completed)

**Prerequisites:** Secrets management set up (Task 8.2)

**Changes:**

1. Update `modules/dotfiles/default.nix` to expose secrets:
```nix
config = mkIf cfg.enable {
  # Expose sops secrets as environment variables for chezmoi templates
  environment.variables = mkIf config.modules.secrets.enable {
    CHEZMOI_GITHUB_TOKEN = "$(cat ${config.sops.secrets.github-token.path} 2>/dev/null || echo '')";
    CHEZMOI_NPM_TOKEN = "$(cat ${config.sops.secrets.npm-token.path} 2>/dev/null || echo '')";
  };

  # ... rest of config
};
```

2. Create template using secrets:

`dotfiles/dot_npmrc.tmpl`:
```npmrc
{{- if env "CHEZMOI_NPM_TOKEN" }}
//registry.npmjs.org/:_authToken={{ env "CHEZMOI_NPM_TOKEN" }}
{{- else }}
# NPM token not configured
{{- end }}
```

3. Add secrets to sops:
```yaml
# secrets/secrets.yaml
github-token: ENC[AES256_GCM,data:xxxxx]
npm-token: ENC[AES256_GCM,data:xxxxx]
```

**Validation:**
```bash
dotfiles-apply
cat ~/.npmrc  # Should have token if secret exists
```

**Commit:** `feat(dotfiles): integrate with sops-nix secrets management`

---

#### Task 8.5.8: Add Automatic Dotfiles Sync (Optional) ✓
**Estimated time:** 35 minutes
**Risk:** Low (systemd services)

**Changes:**

Create `modules/dotfiles/auto-sync.nix`:

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.dotfiles;
  dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";
in
{
  options.modules.dotfiles.autoSync = {
    enable = lib.mkEnableOption "automatic dotfiles synchronization";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "5min";
      description = "How often to check for dotfiles changes";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.autoSync.enable) {
    # User systemd service to apply dotfiles
    systemd.user.services.dotfiles-sync = {
      description = "Synchronize dotfiles with chezmoi";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.chezmoi}/bin/chezmoi apply --source ${dotfilesPath}";
      };
    };

    # Timer to run periodically
    systemd.user.timers.dotfiles-sync = {
      description = "Timer for dotfiles synchronization";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.autoSync.interval;
        Unit = "dotfiles-sync.service";
      };
    };

    # Path watcher - apply immediately when dotfiles directory changes
    systemd.user.paths.dotfiles-watch = {
      description = "Watch dotfiles directory for changes";
      wantedBy = [ "default.target" ];

      pathConfig = {
        PathChanged = dotfilesPath;
        Unit = "dotfiles-sync.service";
      };
    };
  };
}
```

Import in `modules/dotfiles/default.nix`:
```nix
{
  imports = [
    ./auto-sync.nix
  ];

  # ... rest of config
}
```

Enable in host config (optional):
```nix
modules.dotfiles = {
  enable = true;
  autoSync.enable = true;  # NEW
  autoSync.interval = "5min";
};
```

**Validation:**
```bash
# After rebuild
systemctl --user status dotfiles-sync.timer
systemctl --user list-timers | grep dotfiles

# Test it works
touch ~/NixOS/dotfiles/dot_test
systemctl --user status dotfiles-sync.service
```

**Commit:** `feat(dotfiles): add automatic sync with systemd services`

---

### Milestone 9: Migration - Desktop Host (BREAKING - Test Carefully!)

#### Task 9.1: Create Test Desktop Config (New File) ✓
**Estimated time:** 30 minutes
**Risk:** Medium (new config, tested in parallel)

**Changes:**
1. Create `hosts/default/configuration-v2.nix` with new role-based config
2. Keep original `configuration.nix` untouched

**Validation:**
```bash
sudo nixos-rebuild build --flake .#default
# Still uses old config
```

**Commit:** `feat(hosts): add new role-based desktop configuration (v2)`

---

#### Task 9.2: Test Desktop Config V2 ✓
**Estimated time:** 30 minutes
**Risk:** Medium (testing only, no switch)

**Changes:**
1. Temporarily update flake to use `configuration-v2.nix`
2. Build and test

**Validation:**
```bash
# Modify flake temporarily
sudo nixos-rebuild test --flake .#default
# Test system with new config
# Revert flake change
```

**Commit:** (No commit - testing only)

---

#### Task 9.3: Switch Desktop to Role-Based Config ⚠️
**Estimated time:** 30 minutes
**Risk:** HIGH (breaking change)

**Prerequisites:**
- Task 9.2 successful
- Desktop VM test passed
- Backup generation exists

**Changes:**
1. Rename `configuration.nix` → `configuration-old.nix`
2. Rename `configuration-v2.nix` → `configuration.nix`
3. Update desktop config to use roles
4. Enable desktop role

**Validation:**
```bash
# Test build first
sudo nixos-rebuild build --flake .#default

# If successful, test without switching boot
sudo nixos-rebuild test --flake .#default

# If test successful, switch
sudo nixos-rebuild switch --flake .#default

# Verify system works
systemctl status
gnome-shell --version
```

**Rollback if needed:**
```bash
sudo nixos-rebuild switch --rollback
# OR
mv configuration-old.nix configuration.nix
sudo nixos-rebuild switch --flake .#default
```

**Commit:** `refactor(hosts): migrate desktop to role-based configuration`

---

#### Task 9.4: Verify Desktop System ✓
**Estimated time:** 30 minutes
**Risk:** Low (verification only)

**Changes:**
1. Reboot desktop
2. Verify all services
3. Check GPU acceleration
4. Test applications

**Validation Checklist:**
- [ ] System boots
- [ ] GNOME loads
- [ ] GPU acceleration working (`glxinfo | grep renderer`)
- [ ] Audio working
- [ ] Network working
- [ ] Development tools available
- [ ] Gaming packages present

**Commit:** (No commit - verification only)

---

### Milestone 10: Migration - Laptop Host (BREAKING)

#### Task 10.1: Create Test Laptop Config ✓
**Estimated time:** 30 minutes
**Risk:** Medium

**Changes:**
1. Create `hosts/laptop/configuration-v2.nix`
2. Keep original untouched

**Validation:**
```bash
sudo nixos-rebuild build --flake .#laptop
```

**Commit:** `feat(hosts): add new role-based laptop configuration (v2)`

---

#### Task 10.2: Test Laptop Config V2 ✓
**Estimated time:** 30 minutes
**Risk:** Medium

**Validation:**
```bash
sudo nixos-rebuild test --flake .#laptop
```

**Commit:** (No commit - testing only)

---

#### Task 10.3: Switch Laptop to Role-Based Config ⚠️
**Estimated time:** 30 minutes
**Risk:** HIGH

**Prerequisites:**
- Desktop migration successful
- Laptop test successful

**Changes:**
1. Rename configs
2. Switch to role-based config
3. Enable laptop role

**Validation:**
```bash
sudo nixos-rebuild build --flake .#laptop
sudo nixos-rebuild test --flake .#laptop
sudo nixos-rebuild switch --flake .#laptop
```

**Commit:** `refactor(hosts): migrate laptop to role-based configuration`

---

#### Task 10.4: Verify Laptop System ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Validation Checklist:**
- [ ] System boots
- [ ] GNOME loads
- [ ] GPU switching working (if enabled)
- [ ] Battery management active
- [ ] Tailscale connected
- [ ] WiFi working
- [ ] Development tools available

**Commit:** (No commit - verification only)

---

### Milestone 11: Cleanup (Final, Safe Deletions)

#### Task 11.1: Remove Old Package Module ✓
**Estimated time:** 15 minutes
**Risk:** Low (already replaced)

**Changes:**
1. Delete `modules/packages/default.nix` (old monolithic file)
2. Rename `modules/packages-new/` → `modules/packages/`

**Validation:**
```bash
sudo nixos-rebuild build --flake .#default
sudo nixos-rebuild build --flake .#laptop
```

**Commit:** `refactor(packages): remove old monolithic package module`

---

#### Task 11.2: Remove Old GNOME Module ✓
**Estimated time:** 15 minutes
**Risk:** Low

**Changes:**
1. Delete `modules/desktop/gnome.nix` (old monolithic)
2. Rename `modules/desktop/gnome-new/` → `modules/desktop/gnome/`

**Validation:**
```bash
sudo nixos-rebuild build --flake .#default
sudo nixos-rebuild build --flake .#laptop
```

**Commit:** `refactor(desktop): remove old monolithic GNOME module`

---

#### Task 11.3: Remove hosts/shared/common.nix ✓
**Estimated time:** 10 minutes
**Risk:** Low (replaced by roles)

**Changes:**
1. Delete `hosts/shared/common.nix`
2. Delete `hosts/shared/` directory (if empty)

**Validation:**
```bash
sudo nixos-rebuild build --flake .#default
sudo nixos-rebuild build --flake .#laptop
```

**Commit:** `refactor(hosts): remove deprecated shared common.nix`

---

#### Task 11.4: Remove Old Host Config Backups ✓
**Estimated time:** 10 minutes
**Risk:** None

**Changes:**
1. Delete `hosts/default/configuration-old.nix`
2. Delete `hosts/laptop/configuration-old.nix`

**Validation:**
```bash
nix flake check
```

**Commit:** `cleanup: remove old host configuration backups`

---

### Milestone 12: Flake Modernization (Final Polish)

#### Task 12.1: Migrate Flake to flake-parts ✓
**Estimated time:** 60 minutes
**Risk:** Medium (significant refactor)

**Changes:**
1. Refactor `flake.nix` to use flake-parts structure
2. Create `hosts/flake-module.nix`
3. Update host builders to use `lib.builders.mkSystem`

**Validation:**
```bash
nix flake check
sudo nixos-rebuild build --flake .#default
sudo nixos-rebuild build --flake .#laptop
```

**Commit:** `refactor(flake): migrate to flake-parts structure`

---

#### Task 12.2: Add Formatter and Dev Shells ✓
**Estimated time:** 20 minutes
**Risk:** None

**Changes:**
1. Add formatter output
2. Add development shell with tools

**Validation:**
```bash
nix fmt  # Format all files
nix develop  # Enter dev shell
```

**Commit:** `feat(flake): add formatter and development shell`

---

#### Task 12.3: Update Documentation ✓
**Estimated time:** 45 minutes
**Risk:** None

**Changes:**
1. Update `CLAUDE.md` with new structure
2. Update `README.md`
3. Add migration notes

**Validation:**
```bash
# Review docs
cat CLAUDE.md
cat README.md
```

**Commit:** `docs: update documentation for new architecture`

---

### Milestone 13: Final Validation & Merge

#### Task 13.1: Run All Tests ✓
**Estimated time:** 30 minutes
**Risk:** None

**Validation:**
```bash
nix flake check
nix build .#checks.x86_64-linux.desktop-boot
nix build .#checks.x86_64-linux.laptop-boot
alejandra --check .
```

**Commit:** (No commit - validation only)

---

#### Task 13.2: Full System Test on Both Hosts ✓
**Estimated time:** 60 minutes
**Risk:** None (verification)

**Validation:**
1. Reboot desktop, verify all functions
2. Reboot laptop, verify all functions
3. Test key applications on both
4. Verify GPU on both
5. Test networking on both

**Commit:** (No commit - validation only)

---

#### Task 13.3: Merge to Develop ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:**
```bash
git checkout develop
git merge refactor/architecture-v2
git push origin develop
```

**Validation:**
```bash
# On develop branch
nix flake check
sudo nixos-rebuild build --flake .#default
```

**Commit:** `Merge branch 'refactor/architecture-v2' into develop`

---

#### Task 13.4: Create Release Tag ✓
**Estimated time:** 15 minutes
**Risk:** None

**Changes:**
```bash
git tag -a v2.0.0 -m "Architecture v2: Role-based modular configuration"
git push origin v2.0.0
```

**Commit:** (Tag only)

---

#### Task 13.5: Merge to Main ✓
**Estimated time:** 30 minutes
**Risk:** Low

**Changes:**
```bash
# Create PR: develop → main
gh pr create --base main --head develop --title "Architecture v2.0" --body "Complete refactor to role-based modular configuration"

# After approval, merge
gh pr merge --merge
```

**Commit:** (PR merge)

---

## Task Summary

| Milestone | Tasks | Estimated Time | Risk Level | Commits |
|-----------|-------|----------------|------------|---------|
| 1. Foundation | 6 tasks | 2h 00m | Low | 6 |
| 2. Services | 4 tasks | 1h 35m | Low | 4 |
| 3. Roles | 4 tasks | 2h 00m | Low | 4 |
| 4. GPU | 4 tasks | 1h 45m | Low | 4 |
| 5. Packages | 5 tasks | 3h 30m | Low | 5 |
| 6. GNOME | 3 tasks | 1h 35m | Low | 3 |
| 7. Tests | 3 tasks | 1h 35m | Low | 3 |
| 8. Secrets | 2 tasks | 0h 50m | Low | 2 |
| **8.5. Dotfiles** ✅ | **8 tasks** | **3h 25m** | **Low** | **9** |
| 9. Desktop Migration | 4 tasks | 2h 00m | **High** | 1 |
| 10. Laptop Migration | 4 tasks | 2h 00m | **High** | 1 |
| 11. Cleanup | 4 tasks | 0h 50m | Low | 4 |
| 12. Flake Modernization | 3 tasks | 2h 05m | Medium | 3 |
| 13. Final Validation | 5 tasks | 2h 45m | Low | 2 |
| **TOTAL** | **63 tasks** | **27h 55m** | - | **50 commits** |

### Time Breakdown

- **Low Risk Tasks:** 51 tasks, ~22.5h (safe, parallel implementation)
- **Medium Risk Tasks:** 3 tasks, ~2.5h (tested changes)
- **High Risk Tasks:** 8 tasks, ~3h (migration, breaking changes)

**Recommended Schedule:**
- Week 1 (Mon-Fri): Milestones 1-8 (foundation, parallel modules) - 2-3h/day
- Week 1 (Weekend): Milestone 8.5 (dotfiles improvements) - 3-4h total, **optional but high value**
- Week 2 (Mon-Wed): Milestones 9-10 (migration) - 3-4h/day, **test thoroughly**
- Week 2 (Thu-Fri): Milestones 11-13 (cleanup, validation) - 2-3h/day

### Dotfiles Tasks Breakdown ✅ COMPLETE

**Milestone 8.5** - All tasks completed on October 6, 2025:
- ✅ **Task 8.5.1:** Initialize chezmoi properly (15min) - **DONE**
- ✅ **Task 8.5.2:** Make paths portable (20min) - **DONE**
- ✅ **Task 8.5.3:** SSH config templates (30min) - **DONE** (per-host SSH configs)
- ✅ **Task 8.5.4:** Git config templates (20min) - **DONE** (different emails per host)
- ✅ **Task 8.5.5:** Add missing dotfiles (25min) - **DONE** (gitignore, editorconfig, curlrc)
- ✅ **Task 8.5.6:** Validation script (30min) - **DONE** (dotfiles-check command)
- ✅ **Task 8.5.7:** Secrets integration (30min) - **DONE** (with documentation)
- ✅ **Task 8.5.8:** Auto-sync (35min) - **DONE** (systemd timers + path watchers)

---

## Timeline

**Total Estimated Time:** 28 hours over ~14 days (2h/day average)

**Recommended pace:** 4-5 tasks per day for low-risk milestones, 2-3 tasks per day for high-risk milestones

---

## Success Criteria

### System Architecture
✅ Desktop and laptop boot successfully
✅ All packages available
✅ GPU acceleration working
✅ Secrets properly encrypted
✅ Tests passing (`nix flake check`)
✅ Host configs < 60 lines each
✅ No code duplication
✅ Easy to add new hosts
✅ Documented and maintainable

### Dotfiles Management
✅ Chezmoi properly initialized on both hosts
✅ SSH configs are host-specific (desktop vs laptop)
✅ Git configs use appropriate email per host
✅ All dotfiles validated before applying
✅ Templates work correctly on both hosts
✅ Essential dotfiles present (.gitignore, .editorconfig)
✅ Optional: Secrets integrated with sops-nix
✅ Optional: Automatic sync enabled and working

---

## Next Steps After Implementation

1. **Add CI/CD:** GitHub Actions for automated testing
2. **Deploy automation:** Use deploy-rs or colmena
3. **Documentation:** Update CLAUDE.md with new structure
4. **Add server role:** When needed
5. **Per-host secrets:** Expand sops-nix usage
6. **Binary cache:** Setup personal cache for faster builds

---

## Questions & Support

**Before starting:**
1. Review this plan thoroughly
2. Backup current configuration
3. Test in VM if possible
4. Ask questions about any unclear sections

**During implementation:**
1. Commit after each phase
2. Test frequently
3. Keep old configs until new ones proven

**After completion:**
1. Update documentation
2. Share learnings
3. Iterate and improve

---

*End of Architecture Improvement Plan*
