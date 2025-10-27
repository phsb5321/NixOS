# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ CRITICAL: HOST CONFIGURATION WARNING ⚠️

**THIS SYSTEM IS A SERVER HOST - NOT A DESKTOP HOST**

**MANDATORY RULES:**
1. **NEVER** run `nixos-rebuild switch --flake .#default` on this system
2. **NEVER** deploy the default (desktop) host configuration
3. **ALWAYS** use `.#server` for all builds and deployments
4. The `default` host configuration is for desktop machines only
5. The `server` host uses stable nixpkgs and minimal packages

**Sudo password: 123** (for build/deployment commands)

**CORRECT COMMANDS FOR THIS HOST:**
- `sudo nixos-rebuild switch --flake .#nixos-server` ✅
- `sudo nixos-rebuild build --flake .#nixos-server` ✅
- `./user-scripts/nixswitch` ✅ (auto-detects host)

**WRONG COMMANDS (WILL BREAK SYSTEM):**
- `sudo nixos-rebuild switch --flake .#default` ❌
- `sudo nixos-rebuild switch --flake .` ❌ (defaults to .#default)

## Common Development Commands

### NixOS Rebuilds
- `./user-scripts/nixswitch` - Modern TUI-based rebuild script (auto-detects host) (RECOMMENDED)
- `sudo nixos-rebuild switch --flake .#nixos-server` - Manual rebuild for server host (DEFAULT HOST)
- `sudo nixos-rebuild switch --flake .#default` - Manual rebuild for desktop host
- `sudo nixos-rebuild switch --flake .#laptop` - Manual rebuild for laptop host
- `sudo nixos-rebuild test --flake .#nixos-server` - Test server configuration without switching
- `sudo nixos-rebuild build --flake .#nixos-server` - Build server configuration without switching

**NOTE: This system is configured as a SERVER HOST. Always use nixos-server configuration for deployments.**

### Development Environments
- `./user-scripts/nix-shell-selector.sh` - Interactive shell selector with multi-environment support
- `nix-shell shells/JavaScript.nix` - Enter JavaScript development environment
- `nix-shell shells/Python.nix` - Enter Python development environment  
- `nix-shell shells/Rust.nix` - Enter Rust development environment
- Available shells: JavaScript, Python, Golang, ESP, Rust, Elixir

### Flake Operations
- `nix flake update` - Update all flake inputs
- `nix flake check` - Validate flake syntax and configuration
- `nix build .#nixosConfigurations.default.config.system.build.toplevel` - Build system configuration
- `alejandra .` - Format Nix code
- `nixpkgs-fmt .` - Alternative Nix formatter
- `nix develop` - Enter development shell with linting tools (statix, deadnix)

### Dotfiles Management (chezmoi)
- `dotfiles-init` - Initialize dotfiles management
- `dotfiles-status` or `dotfiles` - Check dotfiles status
- `dotfiles-edit` - Edit dotfiles in VS Code/Cursor
- `dotfiles-apply` - Apply dotfiles changes to system
- `dotfiles-add ~/.config/file` - Add new file to dotfiles management
- `dotfiles-sync` - Sync dotfiles with git

## Architecture Overview

### Flake Structure
This is a modular NixOS flake configuration supporting multiple hosts with shared package management:

- **flake.nix**: Main flake entry point with nixpkgs-unstable for latest packages
- **hosts/**: Host-specific configurations (default=desktop, laptop)
- **modules/**: Shared system modules with categorical organization
- **shells/**: Development environment shells for different languages
- **user-scripts/**: Custom automation scripts (nixswitch, nix-shell-selector)
- **dotfiles/**: Chezmoi-managed dotfiles stored in project

### Module System
The configuration uses a modular approach with:

#### Core Modules (`modules/core/`)
- **default.nix**: Base system configuration, Nix settings, security, SSH
- **fonts.nix**: System font management  
- **gaming.nix**: Gaming-related system configuration
- **java.nix**: Java runtime and Android development tools
- **pipewire.nix**: Audio system configuration with high-quality profiles
- **document-tools.nix**: LaTeX, Typst, and Markdown tooling
- **docker-dns.nix**: Container DNS resolution fixes
- **monitor-audio.nix**: Audio routing for external monitors

#### Package Management (`modules/packages/`)
Categorical package management with per-host enable/disable:
- **browsers**: Chrome, Firefox, Brave, Zen browser
- **development**: VS Code, language servers, dev tools, compilers
- **media**: Spotify, VLC, OBS, GIMP, Discord
- **utilities**: gparted, syncthing, system tools
- **gaming**: Steam, Lutris, Wine, performance tools
- **audioVideo**: PipeWire, EasyEffects, audio tools
- **terminal**: Shell tools, fonts, terminal applications

#### Host Configurations
- **server**: Minimal configuration, uses stable nixpkgs for reliability (THIS HOST - DEFAULT)
- **default** (desktop): Gaming enabled, AMD GPU optimization, full development setup, uses nixpkgs-unstable
- **laptop**: Gaming disabled, Intel graphics, minimal package set, Tailscale enabled, uses stable nixpkgs

**IMPORTANT: This system is running as the SERVER host configuration. All rebuilds should target the server configuration.**

### GPU Variants System
The desktop host supports multiple GPU configurations:
- **hardware**: Full AMD GPU acceleration (default)
- **conservative**: Fallback with tear-free settings
- **software**: Emergency software rendering fallback

### Development Environment Strategy
- Language-specific Nix shells in `shells/` directory
- Multi-shell combination support via nix-shell-selector
- Development tools integrated into main package modules
- Language servers pre-configured for Zed editor

### Shell Configuration (`modules/shell/`)
- **Centralized ZSH Management**: All shell configuration is handled by the dedicated shell module
- **PowerLevel10k Theme**: Properly configured with instant prompt support and Nix store paths
- **Plugin System**: Modular plugin configuration (autosuggestions, syntax highlighting, you-should-use)
- **Modern Tools**: Integrated modern CLI replacements (eza, bat, fd, ripgrep, zoxide, etc.)
- **Per-Host Customization**: Shell features can be enabled/disabled per host
- **Clean Dotfiles**: Separated `.zshenv` (environment) from `.zshrc` (interactive configuration)

### Key Design Principles
1. **DRY Configuration**: Shared packages prevent duplication between hosts
2. **Modular Architecture**: Each system area is independently configurable  
3. **Host Flexibility**: Easy to add new hosts that inherit common configuration
4. **Development Focus**: First-class support for multiple programming languages
5. **Modern Tools**: Uses latest packages from nixpkgs-unstable when beneficial

## Special Notes

### Package Management
- Uses both nixpkgs (stable) and nixpkgs-unstable (latest) inputs
- Desktop uses nixpkgs-unstable for latest packages, laptop/server use stable
- Packages are categorized and can be enabled/disabled per host
- Add new categories in `modules/packages/default.nix` following existing patterns
- Host-specific packages go in `extraPackages` array
- Additional inputs: firefox-nightly, zen-browser, flake-utils

### Hardware Configuration  
- Desktop uses AMD GPU with performance optimizations
- Laptop uses Intel graphics with power management
- GPU variant system allows fallback configurations for desktop

### GNOME Desktop Environment (Modular Architecture)

#### Architecture Overview
The GNOME configuration follows a **modular host-specific architecture** to eliminate duplication while allowing complete customization per host.

```
modules/desktop/gnome/
├── base.nix        ← Shared infrastructure (GDM, services, portals, fonts)
├── extensions.nix  ← Extension package installation
└── default.nix     ← Main orchestrator (Wayland/X11, env vars)

hosts/*/gnome.nix   ← Host-specific complete configurations
```

#### Shared Modules (`modules/desktop/gnome/`)

**base.nix** - Core GNOME infrastructure:
- Display manager (GDM)
- Essential services (keyring, settings-daemon, evolution-data-server, etc.)
- XDG desktop portals (file dialogs, screen sharing)
- Base packages (gnome-shell, control-center, nautilus, etc.)
- Fonts (Cantarell, Source Code Pro, Noto fonts)
- Input device management (libinput)

**extensions.nix** - Extension management:
- Granular enable/disable options for each extension
- Package installation when enabled
- Available extensions: appIndicator, dashToDock, userThemes, justPerfection,
  vitals, caffeine, clipboard, gsconnect, workspaceIndicator, soundOutput

**default.nix** - Display protocol & environment:
- Wayland/X11 switching logic
- Session-specific environment variables
- Portal service configuration
- Theme management (icon theme, cursor theme)

#### Host-Specific Configurations

Each host defines its **complete GNOME configuration** in `hosts/<hostname>/gnome.nix`:

**Desktop** (`hosts/default/gnome.nix`):
- Wayland-only (NixOS 25.11+)
- AMD RX 5700 XT optimizations (dynamic triple buffering, rt-scheduler)
- Full extension set (10 extensions)
- Gaming-focused favorite apps (Steam, etc.)
- Performance-oriented settings

**Laptop** (`hosts/laptop/gnome.nix`):
- X11 for Intel GPU compatibility
- Battery-saving settings (no triple buffering, 5min idle, suspend on AC)
- Minimal extension set (9 extensions, no sound-output-device-chooser)
- Power-conscious configuration
- Workspaces only on primary display

**Server** (`hosts/server/gnome.nix`):
- X11 for Proxmox VM compatibility
- VirtIO-GPU optimizations (GSK_RENDERER auto-detect for llvmpipe)
- Minimal extension set (6 extensions, server-focused)
- Always-on power settings (no idle, no sleep, ignore power button)
- Fixed 2 workspaces

#### Key Design Principles

1. **No dconf Merging**: Each host defines one complete `programs.dconf.profiles.user.databases`
   - Prevents GVariant construction errors from merging multiple databases
   - Each host has full control over all dconf settings

2. **Shared Infrastructure**: Base services and packages defined once in `base.nix`
   - DRY principle for common GNOME components
   - Consistent portal and service configuration

3. **Extension Flexibility**: Enable/disable extensions per host
   - Packages installed only when enabled
   - Extension IDs managed in host-specific enabled-extensions list

4. **Environment Isolation**: Host-specific environment variables override shared ones
   - Example: Server uses `GSK_RENDERER = ""` for VM auto-detection
   - Example: Desktop sets AMD GPU hardware acceleration vars

#### GNOME Version Notes
- **NixOS 25.11+**: X11 sessions still available when `wayland.enable = false`
- **Portal Integration**: Comprehensive XDG desktop portal configuration for file dialogs
- **Electron Support**: Proper NIXOS_OZONE_WL and GTK_USE_PORTAL configuration

### Bruno API Client
- Desktop: Wayland mode with enhanced portal configuration for file dialogs
- Laptop: X11 mode for better file picker compatibility
- Portal backend: GTK FileChooser interface for Electron applications

### Dotfiles Integration
- Project-local dotfiles using chezmoi stored in `~/NixOS/dotfiles/`
- Independent of NixOS rebuilds for instant configuration changes
- Git-managed with helper scripts for common operations
- Zed Editor configured with Claude Code integration

### Development Workflow
- Use `nixswitch` for system rebuilds (handles validation, cleanup, error recovery)
- Use `nix-shell-selector.sh` for development environments
- Dotfiles changes apply immediately without rebuilds
- Language servers and tools are pre-configured for modern development
- Zed Editor with Claude Code ACP agent integration