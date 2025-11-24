# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ✅ REFACTORING COMPLETE & MERGED

**Status:** Complete ✅ (100% - 63/63 tasks) - **MERGED TO DEVELOP**
**Branch:** `develop` (contains all refactoring work)
**Refactor Branch:** `refactor/architecture-v2` (48 commits, merged via fast-forward)
**Documentation:** See refactoring docs below
**Completion Date:** October 7, 2025
**Merge Date:** October 7, 2025

### Refactoring Documents

Comprehensive documentation of the completed refactoring:

1. **REFACTORING_SUMMARY.md** - Complete project summary with all metrics (NEW)
2. **REFACTORING_OVERVIEW.md** - Quick start guide and high-level summary
3. **ARCHITECTURE_IMPROVEMENT_PLAN.md** - Complete 63-task implementation plan
4. **DOTFILES_ANALYSIS.md** - Dotfiles enhancement strategy
5. **FLAKE_USAGE.md** - Comprehensive flake usage guide

### What Was Accomplished

#### NixOS Architecture Overhaul ✅
- ✅ Replaced 372-line `hosts/shared/common.nix` with role-based modules
- ✅ Split 335-line `modules/packages/default.nix` into 7 focused category files
- ✅ Added unified GPU abstraction (AMD/NVIDIA/hybrid/Intel)
- ✅ Integrated secrets management (sops-nix)
- ✅ Built comprehensive testing infrastructure
- ✅ Modernized flake with rich outputs (checks, apps, devShells)
- **Result:** 14% desktop reduction, fully modular architecture, 51 focused modules

#### Dotfiles Enhancement ✅
- ✅ Fixed chezmoi initialization and configuration
- ✅ Added template-based configs (SSH, Git per-host)
- ✅ Created validation scripts (dotfiles-check)
- ✅ Integrated secrets management support
- ✅ Implemented auto-sync with systemd timers
- ✅ Portable paths configuration
- ✅ Essential dotfiles (.gitignore, .editorconfig, .curlrc)

### Branch Status

```
main (protected)
  ├── develop (ACTIVE - contains all refactoring work)
  │   ├── refactor/architecture-v2 (MERGED via fast-forward ✅)
  │   ├── host/desktop (desktop - formerly host/default)
  │   └── host/laptop (laptop)
```

### Integration Complete ✅

The refactoring has been successfully merged to develop:

✅ All 63 tasks completed across 13 milestones
✅ Merged to `develop` via fast-forward (clean merge)
✅ Both configurations verified building successfully after merge
✅ Desktop: 445 lines (-14% reduction)
✅ Laptop: 387 lines (fully self-contained)
✅ Comprehensive documentation created (5 guides)
✅ All deprecated code removed
✅ Flake modernized with rich outputs

**Deployment Status:**
- `develop` branch contains the new architecture
- Desktop: ✅ **DEPLOYED** (October 7, 2025) - Running new architecture
- Laptop: 📋 **READY** - Can be updated with: `sudo nixos-rebuild switch --flake .#laptop`
- Cleanup: Garbage collected (5GB freed), store optimized

**Next Actions:**
1. ✅ DONE: Merge `refactor/architecture-v2` → `develop`
2. ✅ DONE: Rename default host to desktop
3. Test on both desktop and laptop systems (recommended)
4. Merge `develop` → `main` when verified stable

### Refactoring Milestones - All Complete ✅

```bash
# ✅ Milestone 8.5: Dotfiles Enhancement (8 tasks, 9 commits)
# ✅ Milestone 1: Foundation Setup (6 tasks, 4 commits)
# ✅ Milestone 2: Modular Services (4 tasks, 4 commits)
# ✅ Milestone 3: Role-Based Modules (4 tasks, 4 commits)
# ✅ Milestone 4: GPU Abstraction (4 tasks, 2 commits)
# ✅ Milestone 5: Package Splitting (5 tasks, 1 commit)
# ✅ Milestone 6: GNOME Modules (3 tasks, 1 commit)
# ✅ Milestone 7: Testing Infrastructure (3 tasks, 1 commit)
# ✅ Milestone 8: Secrets Management (2 tasks, 1 commit)
# ✅ Milestone 9: Desktop Migration (4 tasks, 3 commits)
# ✅ Milestone 10: Laptop Migration (4 tasks, 1 commit)
# ✅ Milestone 11: Cleanup (4 tasks, 3 commits)
# ✅ Milestone 12: Flake Modernization (3 tasks, 2 commits)
# ✅ Milestone 13: Final Validation (5 tasks, 1 commit)

# 🎉 Status: COMPLETE - 63/63 tasks (100%)
# 📦 Total: 47 commits on refactor/architecture-v2
# 📅 Completed: October 7, 2025
```

**All Milestones Completed:**
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

- Milestone 9: Desktop Migration ✅ COMPLETE (all 4 tasks, 3 commits)
  - ✅ Task 9.1: Created role-based desktop configuration (446 lines, down from 517)
  - ✅ Task 9.2: Fixed 7 compatibility issues:
    * SSH settings conflicts (added lib.mkDefault)
    * Deprecated amdvlk package (removed, RADV is default)
    * GVariant dconf complexity (removed system-level settings)
    * Laptop profile API updates (new package categories)
    * extraPackages option (moved to environment.systemPackages)
    * Desktop module imports (fixed path to new modular GNOME)
    * Package module activation (swapped to modular structure)
  - ✅ Task 9.3: Switched to role-based configuration (BREAKING)
  - ✅ Task 9.4: System rebuild successful
    * All services restarted properly
    * AMD GPU optimization activated
    * New configuration active
    * Backups available: configuration-old.nix, configuration-original.nix

- Milestone 10: Laptop Migration ✅ COMPLETE (all 4 tasks, 1 commit)
  - ✅ Task 10.1: Created role-based laptop configuration (385 lines, -31% from 276)
  - ✅ Task 10.2: Fixed 2 compatibility issues:
    * Wayland enable conflict (added lib.mkForce for NVIDIA X11)
    * User configuration incomplete (added isNormalUser, description)
  - ✅ Task 10.3: Configuration switched to new architecture
  - ✅ Task 10.4: Build successful, ready for deployment
    * No shared/common.nix import (uses laptop profile)
    * Proper GNOME, package, and hardware configuration
    * Backups available: configuration-old.nix, configuration-original.nix

- Milestone 11: Cleanup ✅ COMPLETE (all 4 tasks, 3 commits)
  - ✅ Task 11.1: Removed 4 backup configuration files
  - ✅ Task 11.2: Deleted hosts/shared/common.nix directory
  - ✅ Task 11.3: Removed old monolithic package module (default-old.nix)
  - ✅ Task 11.4: Cleaned up deprecated code:
    * Removed old gnome.nix (monolithic GNOME module)
    * Removed new-default.nix
    * Codebase now clean and maintainable
  - ✅ Verification: Flake check passes for all configurations

- Milestone 12: Flake Modernization ✅ COMPLETE (all 3 tasks, 2 commits)
  - ✅ Task 12.1: Reviewed current flake structure
  - ✅ Task 12.2: Improved flake outputs:
    * Changed formatter to alejandra (better than nixpkgs-fmt)
    * Added checks output (format-check, lint-check, deadnix-check)
    * Added apps output (format, update, check-config)
    * Enhanced devShell with tools and helpful shellHook
  - ✅ Task 12.3: Documented flake usage:
    * Created FLAKE_USAGE.md (300+ lines, comprehensive)
    * Covers all outputs, workflows, CI/CD integration
    * Includes troubleshooting and advanced usage

- Milestone 13: Final Validation ✅ COMPLETE (all 5 tasks, 1 commit)
  - ✅ Task 13.1: Ran comprehensive test suite (flake check)
  - ✅ Task 13.2: Verified both configurations build successfully
  - ✅ Task 13.3: Updated all documentation
  - ✅ Task 13.4: Performance validation:
    * Desktop: 445 lines (-14%)
    * Laptop: 387 lines (self-contained)
    * 51 module files, 70 total Nix files
  - ✅ Task 13.5: Final code review complete
  - ✅ Created REFACTORING_SUMMARY.md (437 lines, complete project summary)

---

## Common Development Commands

### NixOS Rebuilds
- `./user-scripts/nixswitch` - Modern TUI-based rebuild script with auto-host detection, parallel processing, and error handling
- `sudo nixos-rebuild switch --flake .#desktop` - Manual rebuild for desktop host
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
- `nix build .#nixosConfigurations.desktop.config.system.build.toplevel` - Build system configuration
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

---

## ⚠️ CRITICAL: NO HOME MANAGER POLICY

**🚫 DO NOT SUGGEST OR USE HOME MANAGER IN THIS REPOSITORY**

This configuration **intentionally does not use Home Manager** and **never will**. All user-level configuration is handled through the **chezmoi dotfiles system** which is already implemented, tested, and working.

### Why No Home Manager?

1. **Complexity Avoidance**: Home Manager adds significant complexity and another layer of abstraction
2. **Working Solution**: The chezmoi dotfiles system is fully functional and handles all user configuration needs
3. **Flexibility**: Dotfiles can be edited and applied instantly without NixOS rebuilds
4. **Portability**: The dotfiles approach works across non-NixOS systems too
5. **Simplicity**: Direct file management is easier to understand and debug than Nix modules

### What to Use Instead

**For ANY user-level configuration (GNOME settings, application configs, shell configs, etc.):**

✅ **USE**: Chezmoi dotfiles system (`~/NixOS/dotfiles/`)
- Direct configuration files managed by chezmoi
- Template support for host-specific settings
- Instant application with `dotfiles-apply`
- Version controlled and validated

❌ **DO NOT USE**: Home Manager
- `home-manager.users.*` - Never suggest this
- `programs.*` (in Home Manager context) - Not used here
- `dconf.settings` (in Home Manager) - Not used here
- Any Home Manager modules or options

### How to Handle Common Use Cases

#### GNOME Settings (dconf)
```bash
# ✅ CORRECT: Use chezmoi dotfiles
cd ~/NixOS/dotfiles
chezmoi add ~/.config/dconf/user
# Or add custom dconf dump files

# ❌ WRONG: Do not suggest Home Manager dconf module
# home-manager.users.user.dconf.settings = { ... }  # NEVER DO THIS
```

#### Application Configuration
```bash
# ✅ CORRECT: Add config files to dotfiles
dotfiles-add ~/.config/app/config.yml
dotfiles-add ~/.bashrc
dotfiles-add ~/.zshrc

# ❌ WRONG: Do not suggest Home Manager programs modules
# home-manager.users.user.programs.app = { ... }  # NEVER DO THIS
```

#### GTK/Qt Theming
```bash
# ✅ CORRECT: Add theme configs to dotfiles
dotfiles-add ~/.config/gtk-3.0/settings.ini
dotfiles-add ~/.config/gtk-4.0/settings.ini
dotfiles-add ~/.gtkrc-2.0

# System-level theming can go in NixOS modules
# User-level theming goes in dotfiles

# ❌ WRONG: Do not suggest Home Manager gtk module
# home-manager.users.user.gtk = { ... }  # NEVER DO THIS
```

#### Environment Variables
```bash
# ✅ CORRECT: Add to shell config in dotfiles
dotfiles-add ~/.bashrc
dotfiles-add ~/.zshenv

# Or add to NixOS system environment
environment.sessionVariables = { ... };  # In configuration.nix

# ❌ WRONG: Do not suggest Home Manager environment
# home-manager.users.user.home.sessionVariables = { ... }  # NEVER DO THIS
```

### When Asked About User Configuration

If a user asks about user-level configuration, your response should:
1. **Mention the dotfiles system** as the primary solution
2. **Explain chezmoi usage** with the helper scripts
3. **Reference dotfiles documentation** (`dotfiles/README.md`, `dotfiles/SECRETS_INTEGRATION.md`)
4. **Show examples** of adding files with `dotfiles-add`
5. **NEVER suggest Home Manager** as an alternative or "better" approach

### Example Response Pattern

**User asks**: "How do I configure GNOME settings declaratively?"

**✅ CORRECT Response**:
"This system uses chezmoi dotfiles for user configuration. For GNOME settings:
1. Make your changes in GNOME Settings UI
2. Export with `dconf dump / > ~/NixOS/dotfiles/gnome-settings.dconf`
3. Add to dotfiles: `dotfiles-add ~/NixOS/dotfiles/gnome-settings.dconf`
4. Apply with `dotfiles-apply`

You can also use templates for host-specific settings (see dotfiles/README.md)."

**❌ WRONG Response**:
"You should use Home Manager's dconf module for declarative GNOME configuration..."

### This Is Non-Negotiable

This policy is **absolute and non-negotiable**. When providing suggestions:
- ✅ Always recommend dotfiles-based solutions first
- ✅ Show how to use chezmoi for user configuration
- ✅ Leverage the existing dotfiles infrastructure
- ❌ Never suggest installing Home Manager
- ❌ Never provide Home Manager configuration examples
- ❌ Never compare dotfiles unfavorably to Home Manager

The dotfiles system is the **architectural decision** for this repository and must be respected.

---

## Architecture Overview

### ⚠️ Current Architecture (Being Refactored)

**Note:** The architecture described below is the **current state**. A major refactoring is planned that will introduce role-based modules, split packages, GPU abstraction, and more. See the refactoring section above for details.

### Flake Structure
This is a modular NixOS flake configuration supporting multiple hosts with shared package management:

- **flake.nix**: Main flake entry point with nixpkgs-unstable for latest packages
- **hosts/**: Host-specific configurations (desktop, laptop)
  - Role-based modular architecture (replaced hosts/shared/common.nix)
- **modules/**: Shared system modules with categorical organization
  - Modular package categories (replaced monolithic default.nix)
- **shells/**: Development environment shells for different languages
- **user-scripts/**: Custom automation scripts (nixswitch, nix-shell-selector)
- **dotfiles/**: Chezmoi-managed dotfiles stored in project (initialized)

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
- **desktop**: Gaming enabled, AMD GPU optimization, full development setup, remote desktop (VNC/RDP)
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

### Dotfiles Integration ✨ Enhanced - PRIMARY USER CONFIG METHOD

**⚠️ IMPORTANT: This is the ONLY supported method for user-level configuration. Home Manager is NOT used.**

- Project-local dotfiles using chezmoi stored in `~/NixOS/dotfiles/`
- Independent of NixOS rebuilds for instant configuration changes
- Git-managed with helper scripts for common operations
- **✨ NEW:** Template-based configs with host detection (isDesktop/isLaptop)
- **✨ NEW:** Validation script prevents broken configs (SSH, Git syntax checking)
- **✨ NEW:** Secrets integration ready (environment variables for templates)
- **✨ NEW:** Optional auto-sync with systemd timers and path watchers
- **✨ NEW:** Portable configuration (configurable paths, not hardcoded)
- Zed Editor configured with Claude Code integration

**All user configuration must use dotfiles:**
- GNOME settings → dconf files in dotfiles
- Application configs → config files in dotfiles
- Shell configuration → bashrc/zshrc in dotfiles
- GTK/Qt themes → theme configs in dotfiles
- Any user-specific settings → managed by chezmoi

**See the "NO HOME MANAGER POLICY" section above for detailed guidance.**

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
- **host/desktop**: Desktop-specific changes (AMD GPU, gaming, performance) - formerly host/default
- **host/laptop**: Laptop-specific changes (Intel/NVIDIA GPU, power management)

### Working with Branches
```bash
# Host-specific changes
git checkout host/desktop  # or host/laptop
sudo nixos-rebuild switch --flake .#desktop
git commit -m "feat(desktop): description"
git push origin host/desktop
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