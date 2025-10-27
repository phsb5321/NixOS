# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚧 ACTIVE REFACTORING - READ FIRST

**Status:** Planning complete, ready to execute
**Branch:** `refactor/architecture-v2` (to be created)
**Documentation:** See refactoring docs below

### Refactoring Documents (START HERE)

Before making any changes to the architecture, READ THESE:

1. **REFACTORING_OVERVIEW.md** - Quick start guide and high-level summary
2. **ARCHITECTURE_IMPROVEMENT_PLAN.md** - Complete 63-task implementation plan
3. **DOTFILES_ANALYSIS.md** - Dotfiles enhancement strategy

### What's Being Refactored

#### NixOS Architecture (Main Focus)
- Replace 372-line `hosts/shared/common.nix` with role-based modules
- Split 335-line `modules/packages/default.nix` into 10+ focused files
- Add unified GPU abstraction (AMD/NVIDIA/hybrid)
- Add secrets management (sops-nix)
- Add testing infrastructure
- **Result:** 77-80% reduction in host config lines

#### Dotfiles Enhancement (Milestone 8.5)
- Fix chezmoi initialization (currently broken)
- Add template-based configs (SSH, Git per-host)
- Add validation scripts
- Integrate secrets management
- Optional: Auto-sync with systemd

### Current Branch Strategy During Refactoring

```
main (protected)
  ├── develop (integration branch)
  │   ├── host/default (desktop, 75 commits ahead)
  │   ├── host/laptop (laptop)
  │   └── refactor/architecture-v2 (TO BE CREATED - refactoring work)
```

### DO NOT (During Refactoring)

❌ Make architecture changes directly on `host/default` or `host/laptop`
❌ Modify `hosts/shared/common.nix` (will be deleted in refactor)
❌ Modify `modules/packages/default.nix` (will be split in refactor)
❌ Create new non-refactor features until refactor is complete

### DO (During Refactoring)

✅ Work on `refactor/architecture-v2` branch for all refactoring tasks
✅ Follow task order in ARCHITECTURE_IMPROVEMENT_PLAN.md
✅ Commit after each task (atomic commits)
✅ Push to remote after each successful task
✅ Test with `nix flake check` and `nixos-rebuild build` before committing
✅ Bug fixes can go on current branches (will merge later)

### Quick Start Refactoring

```bash
# 1. Create backup and branch
git tag backup-$(date +%Y%m%d)
git checkout -b refactor/architecture-v2

# 2. Read the plan
cat REFACTORING_OVERVIEW.md

# 3. Start with Task 1.2 (backup already done)
# Follow ARCHITECTURE_IMPROVEMENT_PLAN.md step-by-step
```

---

## Common Development Commands

### NixOS Rebuilds
- `./user-scripts/nixswitch` - Modern TUI-based rebuild script with auto-host detection, parallel processing, and error handling
- `sudo nixos-rebuild switch --flake .#default` - Manual rebuild for desktop host  
- `sudo nixos-rebuild switch --flake .#laptop` - Manual rebuild for laptop host
- `sudo nixos-rebuild test --flake .` - Test configuration without switching
- `sudo nixos-rebuild build --flake .` - Build without switching

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

### System Maintenance
- `./user-scripts/nixos-maintenance.sh` - Comprehensive maintenance: updates, cleanup, optimization, and reporting
- `nix-collect-garbage -d` - Manual garbage collection
- `nix-store --optimise` - Deduplicate Nix store
- `journalctl --vacuum-time=2w` - Clean system logs

### Dotfiles Management (chezmoi)
- `dotfiles-init` - Initialize dotfiles management
- `dotfiles-status` or `dotfiles` - Check dotfiles status
- `dotfiles-edit` - Edit dotfiles in VS Code/Cursor
- `dotfiles-apply` - Apply dotfiles changes to system
- `dotfiles-add ~/.config/file` - Add new file to dotfiles management
- `dotfiles-sync` - Sync dotfiles with git


## Architecture Overview

### ⚠️ Current Architecture (Being Refactored)

**Note:** The architecture described below is the **current state**. A major refactoring is planned that will introduce role-based modules, split packages, GPU abstraction, and more. See the refactoring section above for details.

### Flake Structure
This is a modular NixOS flake configuration supporting multiple hosts with shared package management:

- **flake.nix**: Main flake entry point with nixpkgs-unstable for latest packages
- **hosts/**: Host-specific configurations (default=desktop, laptop)
  - **hosts/shared/common.nix**: ⚠️ Will be replaced by role modules in refactor
- **modules/**: Shared system modules with categorical organization
  - **modules/packages/default.nix**: ⚠️ Will be split into multiple files in refactor
- **shells/**: Development environment shells for different languages
- **user-scripts/**: Custom automation scripts (nixswitch, nix-shell-selector)
- **dotfiles/**: Chezmoi-managed dotfiles stored in project (needs initialization)

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
- **networking.nix**: Base network configuration

#### Hardware Modules (`modules/hardware/`)
- **amd-gpu.nix**: AMD GPU configuration with Wayland optimization for RX 5700 XT (Navi 10)
- **laptop.nix**: Laptop-specific hardware optimizations

#### Networking Modules (`modules/networking/`)
- **tailscale.nix**: Tailscale VPN configuration
- **remote-desktop.nix**: VNC and RDP server configuration
- **dns.nix**: DNS configuration and resolver settings
- **firewall.nix**: Firewall rules and port management

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
- **default** (desktop): Gaming enabled, AMD GPU optimization, full development setup, remote desktop (VNC/RDP)
- **laptop**: Gaming disabled, Intel graphics, minimal package set, Tailscale enabled

#### Profiles System (`modules/profiles/`)
Pre-configured profiles for different use cases:
- **laptop**: Optimizations and settings specific to laptop hardware

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

### Key Design Principles
1. **DRY Configuration**: Shared packages prevent duplication between hosts
2. **Modular Architecture**: Each system area is independently configurable  
3. **Host Flexibility**: Easy to add new hosts that inherit common configuration
4. **Development Focus**: First-class support for multiple programming languages
5. **Modern Tools**: Uses latest packages from nixpkgs-unstable when beneficial

## Special Notes

### Package Management
- Uses both nixpkgs (stable) and nixpkgs-unstable (latest) inputs
- Packages are categorized and can be enabled/disabled per host
- Add new categories in `modules/packages/default.nix` following existing patterns
- Host-specific packages go in `extraPackages` array

### Hardware Configuration
- Desktop uses AMD RX 5700 XT (Navi 10) with AMDGPU driver and Wayland optimization
- Laptop uses Intel graphics with power management (NVIDIA support via profiles)
- GPU variant system allows fallback configurations for desktop (hardware/conservative/software)
- Remote desktop support: VNC (port 5900) and RDP (port 3389) on desktop host

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

### External Binary Compatibility
- **steam-run**: For running external binaries with library dependencies
  ```bash
  steam-run ./external-binary  # Provides FHS environment
  ```
- **ADB Support**: Android development enabled on all devices
  ```bash
  adb devices  # Android Debug Bridge ready
  ```
- **nix-ld**: Alternative compatibility layer for dynamic linking

## Git Workflow

### Branch Strategy
This repository uses a structured branch workflow for managing multi-host configurations:

- **main**: Production-ready stable configuration (protected, requires PR approval)
- **develop**: Integration branch for features affecting multiple hosts or shared modules
- **host/default**: Desktop-specific changes (AMD GPU, gaming, performance)
- **host/laptop**: Laptop-specific changes (Intel/NVIDIA GPU, power management)

### Working with Branches
```bash
# Host-specific changes
git checkout host/default  # or host/laptop
sudo nixos-rebuild switch --flake .#default
git commit -m "feat(desktop): description"
git push origin host/default
# Create PR: host/* → develop

# Shared module changes
git checkout develop
git commit -m "feat(core): description"
git push origin develop
# Create PR: develop → main
```

### Emergency Hotfixes
```bash
git checkout -b hotfix/description main
# Make minimal fix
# Create PR to main
# Merge main back to develop and host branches
```