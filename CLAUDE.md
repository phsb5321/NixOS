# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## 🚧 ACTIVE REFACTORING - IN PROGRESS

**Status:** In Progress - Secrets Management Complete ✅ (61.9% complete)
**Branch:** `refactor/architecture-v2` (36+ commits pushed)
**Documentation:** See refactoring docs below
**Last Updated:** October 6, 2025

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

#### Dotfiles Enhancement ✅ COMPLETE (Milestone 8.5)
- ✅ Fix chezmoi initialization - **DONE**
- ✅ Add template-based configs (SSH, Git per-host) - **DONE**
- ✅ Add validation scripts (dotfiles-check) - **DONE**
- ✅ Integrate secrets management - **DONE**
- ✅ Auto-sync with systemd timers - **DONE**
- ✅ Portable paths configuration - **DONE**
- ✅ Essential dotfiles (.gitignore, .editorconfig, .curlrc) - **DONE**

### Current Branch Strategy During Refactoring

```
main (protected)
  ├── develop (integration branch)
  │   ├── host/default (desktop, 75 commits ahead)
  │   ├── host/laptop (laptop)
  │   └── refactor/architecture-v2 (ACTIVE - 20 commits, services complete)
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

### Refactoring Progress

```bash
# ✅ Milestone 8.5 Complete (Dotfiles - 8 tasks, 9 commits)
# ✅ Milestone 1 Complete (Foundation - 6 tasks, 4 commits)
# ✅ Milestone 2 Complete (Services - 4 tasks, 4 commits)
# ✅ Milestone 3 Complete (Roles - 4 tasks, 4 commits)
# ✅ Milestone 4 Complete (GPU - 4 tasks, 2 commits)
# ✅ Milestone 5 Complete (Packages - 5 tasks, 1 commit)
# ✅ Milestone 6 Complete (GNOME - 3 tasks, 1 commit)
# ✅ Milestone 7 Complete (Tests - 3 tasks, 1 commit)
# ✅ Milestone 8 Complete (Secrets - 2 tasks, 1 commit)
# Already on refactor/architecture-v2 branch

# ⚠️ Next: Milestone 9 - Desktop Migration (HIGH RISK - Breaking Changes)
# Follow ARCHITECTURE_IMPROVEMENT_PLAN.md Task 9.1 onwards
```

**Completed:**
- Milestone 8.5: Dotfiles Enhancement (all 8 tasks)
  - Chezmoi initialization and configuration
  - SSH/Git config templates with host detection
  - Validation script (dotfiles-check)
  - Secrets integration support
  - Auto-sync with systemd
  - Essential dotfiles and documentation

- Milestone 1: Foundation Setup (all 6 tasks)
  - flake-parts input added
  - flake-utils input (already present)
  - lib/ directory with helper functions
  - System builders (mkSystem, mkPackageCategory)
  - Utility functions (mergeWithPriority, pkgsIf, enableAll)
  - sops-nix input for secrets

- Milestone 2: Modular Services (all 4 tasks)
  - Services directory created with module structure
  - Syncthing service extracted (file sync)
  - SSH service extracted (OpenSSH with security options)
  - Printing service extracted (CUPS + Avahi discovery)
  - Original configs kept in common.nix (parallel implementation)

- Milestone 3: Role-Based Modules (all 4 tasks)
  - Roles directory created with module structure
  - Desktop role (gaming, full features, syncthing, printing, dotfiles)
  - Laptop role (power management, battery optimizations, zram)
  - Server/minimal roles for future use
  - All roles disabled by default (parallel implementation)

- Milestone 4: GPU Abstraction (all 4 tasks)
  - GPU directory created with module structure
  - AMD GPU module (RX 5700 XT, Navi 10/21/22/23/24, RDNA3 support)
  - Hybrid GPU module (NVIDIA Prime with offload/sync/reverse-prime modes)
  - Intel GPU module (generation detection, iHD vs i965 driver selection)
  - NVIDIA GPU module (stable/beta/legacy drivers, open-source support)
  - All modules disabled by default with configurable options

- Milestone 5: Package Splitting (all 5 tasks)
  - Created modules/packages/categories/ directory
  - Browsers module: Chrome, Brave, LibreWolf, Zen (individual toggles)
  - Development module: 10+ options (editors, runtimes, compilers, LSPs, Git, utilities)
  - Media module: VLC, Spotify, Discord, OBS, GIMP
  - Gaming module: performance tools, launchers, Wine, GPU control, Minecraft
  - Utilities module: disk management, compression, security, fonts
  - Audio-Video module: PipeWire, EasyEffects, control tools
  - Terminal module: fonts, shell, themes, plugins, applications
  - New modular system with 696 lines across 7 category files
  - Old monolithic module (335 lines) preserved for migration

- Milestone 6: GNOME Modules (all 3 tasks)
  - Created modules/desktop/gnome/ subdirectory
  - Base module: GDM, core services, portal, themes, power management
  - Extensions module: 10+ extensions with individual toggles + productivity bundle
  - Settings module: dark mode, animations, hot corners, battery, weekday
  - Wayland module: Wayland/X11 switching, Electron support, screen sharing, variants
  - Modular system with 515 lines across 3 files (base, extensions, wayland)
  - Old monolithic gnome.nix preserved for migration

- Milestone 7: Testing Infrastructure (all 3 tasks)
  - Created tests/ directory with modular structure
  - Formatting tests: format-check, format-fix, lint-check, pre-commit-check
  - Boot tests: boot-test-all, boot-test-default, boot-test-laptop
  - VM tests: vm-test-default for QEMU testing
  - Evaluation tests: eval-test for configuration validation
  - Full test suite: test-all combining all checks
  - Test scripts ready for CI/CD integration (385 lines across 5 files)
  - Comprehensive README.md with usage examples

- Milestone 8: Secrets Management (all 2 tasks)
  - Created secrets/ directory with sops-nix integration
  - Secrets module with configurable options (enable, defaultSopsFile, ageKeyFile)
  - Comprehensive README.md with setup, usage, security best practices
  - Example configuration files: .sops.yaml.example, example.yaml
  - .gitignore to prevent committing unencrypted secrets
  - Ready for age encryption and per-host secret files
  - Integration with dotfiles and services
  - 434 lines of documentation and configuration

**Next:**
- ⚠️ Milestone 9: Desktop Migration (4 tasks - HIGH RISK)
  - Migrate desktop host to role-based configuration
  - Breaking changes - requires careful testing
  - Test configuration before switching
  - Verify all services and packages work

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

### Dotfiles Management (chezmoi) ✨ Enhanced
- `dotfiles-init` - Initialize dotfiles management (✅ now working)
- `dotfiles-status` or `dotfiles` - Check dotfiles status
- `dotfiles-check` - ✨ NEW: Validate dotfiles before applying (checks SSH, Git syntax, scans for secrets)
- `dotfiles-edit` - Edit dotfiles in VS Code/Cursor
- `dotfiles-apply` - Apply dotfiles changes to system
- `dotfiles-add ~/.config/file` - Add new file to dotfiles management
- `dotfiles-sync` - Show dotfiles management info

**New Features:**
- 📝 **Templates:** SSH and Git configs adapt per-host (desktop/laptop)
- 🔒 **Secrets:** Ready for sops-nix integration (see `dotfiles/SECRETS_INTEGRATION.md`)
- ✅ **Validation:** Automatic syntax checking and secret scanning
- ⚙️ **Auto-sync:** Optional systemd timers for automatic application
- 📦 **Essential files:** .gitignore_global, .editorconfig, .curlrc included


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

### NixOS 25.11+ GNOME Configuration
- **Wayland-only**: NixOS 25.11+ removes X11 session support entirely
- **Portal Integration**: Comprehensive XDG desktop portal configuration for file dialogs
- **Electron Support**: Proper NIXOS_OZONE_WL and GTK_USE_PORTAL configuration
- **Multi-host**: Desktop (Wayland), Laptop (X11 for NVIDIA compatibility)

### Bruno API Client
- Desktop: Wayland mode with enhanced portal configuration for file dialogs
- Laptop: X11 mode for better file picker compatibility
- Portal backend: GTK FileChooser interface for Electron applications

### Dotfiles Integration ✨ Enhanced
- Project-local dotfiles using chezmoi stored in `~/NixOS/dotfiles/`
- Independent of NixOS rebuilds for instant configuration changes
- Git-managed with helper scripts for common operations
- **✨ NEW:** Template-based configs with host detection (isDesktop/isLaptop)
- **✨ NEW:** Validation script prevents broken configs (SSH, Git syntax checking)
- **✨ NEW:** Secrets integration ready (environment variables for templates)
- **✨ NEW:** Optional auto-sync with systemd timers and path watchers
- **✨ NEW:** Portable configuration (configurable paths, not hardcoded)
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