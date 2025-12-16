# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

<<<<<<< HEAD
## 🖥️ CURRENT HOST: LAPTOP (nixos-laptop @ 192.168.1.28) 🖥️

**⚠️ YOU ARE RUNNING ON THE LAPTOP HOST ⚠️**

**CRITICAL INFORMATION:**
- **Current System:** nixos-laptop (Physical laptop - development workstation)
- **IP Address:** 192.168.1.28
- **Hardware:** Intel CPU, NVMe storage, WiFi, touchpad, hybrid graphics (NVIDIA disabled)
- **Display:** GNOME on Wayland (X11 available as fallback)
- **Configuration:** `.#nixos-laptop` or `.#laptop`
- **Deployment Method:** Manual build + activate (see below - DO NOT use `nixos-rebuild`)
- **Sudo Password:** 123

**DEPLOYMENT COMMANDS FOR THIS HOST:**
```bash
# Build the laptop configuration
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --extra-experimental-features "nix-command flakes"

# Verify it's the laptop config (should show "nixos-laptop")
readlink result

# Activate the built configuration
echo "123" | sudo -S ./result/bin/switch-to-configuration switch
```

**DO NOT USE** `sudo nixos-rebuild switch` on this host - it has hostname auto-detection issues!

---

## 🚨 CRITICAL: MULTI-HOST ENVIRONMENT AWARENESS 🚨

**⚠️ IDENTIFY YOUR HOST BEFORE ANY OPERATIONS ⚠️**

**AVAILABLE HOSTS:**
This NixOS configuration manages THREE hosts:

1. **nixos-server** (192.168.1.169) - Proxmox VM
   - **PRODUCTION SERVER** - 24/7 uptime required
   - Hosts: qBittorrent, Plex, Audiobookshelf, media libraries
   - ⚠️ Any changes affect active users
   - Configuration: `.#nixos-server` or `.#server`

2. **nixos-laptop** (192.168.1.28) - Physical laptop **⚠️ CURRENT HOST ⚠️**
   - Development and mobile workstation
   - Intel CPU, NVMe storage, WiFi, touchpad, hybrid graphics (NVIDIA disabled)
   - GNOME on Wayland (default), X11 available as fallback
   - Configuration: `.#nixos-laptop` or `.#laptop`
   - **Deployment:** Manual build + activate (see deployment section)

3. **nixos-desktop** (IP varies) - Desktop workstation
   - AMD RX 5700 XT GPU, gaming setup
   - Full development environment
   - Configuration: `.#nixos-desktop` or `.#desktop`

**HOW TO IDENTIFY CURRENT HOST:**
```bash
hostname           # Shows: nixos-server, nixos-laptop, or nixos-desktop
ip addr show       # Check IP address
cat /etc/hostname  # Persistent hostname
```

**CURRENT HOST VERIFICATION:**
```bash
$ hostname
nixos-laptop

$ ip addr show | grep "inet 192"
inet 192.168.1.28/24 brd 192.168.1.255 scope global dynamic noprefixroute enp4s0

$ readlink /run/current-system | grep -o "nixos-.*-20"
nixos-laptop-20
```
✅ **CONFIRMED: This is the LAPTOP host**

**Sudo password (all hosts): 123**

---

## ⚠️ HOST-SPECIFIC DEPLOYMENT RULES ⚠️

### Server Host (192.168.1.169)
**THIS IS THE PRODUCTION SERVER - EXTREME CAUTION REQUIRED**

**CORRECT COMMANDS:**
- `sudo nixos-rebuild switch --flake .#nixos-server` ✅
- `sudo nixos-rebuild build --flake .#nixos-server` ✅ (test first)
- `./user-scripts/nixswitch` ✅ (auto-detects, RECOMMENDED)

**WRONG COMMANDS (WILL BREAK SERVER):**
- `sudo nixos-rebuild switch --flake .#desktop` ❌ BREAKS SERVER
- `sudo nixos-rebuild switch --flake .#laptop` ❌ BREAKS SERVER
- `sudo nixos-rebuild switch --flake .` ❌ BREAKS SERVER (defaults to desktop)

### Laptop Host (192.168.1.28) **⚠️ THIS IS YOUR CURRENT HOST ⚠️**
**IMPORTANT:** `nixos-rebuild` has hostname auto-detection issues that can deploy wrong configuration!
**YOU ARE RUNNING ON THIS SYSTEM RIGHT NOW!**

**CORRECT DEPLOYMENT METHOD:**
```bash
# 1. Build the laptop configuration explicitly
sudo nix build .#nixosConfigurations.laptop.config.system.build.toplevel --extra-experimental-features "nix-command flakes"

# 2. Verify it's the laptop config (should show "nixos-laptop")
readlink result

# 3. Activate the built configuration
echo "123" | sudo -S ./result/bin/switch-to-configuration switch
```

**WHY NOT `nixos-rebuild`?**
- `nixos-rebuild` ignores the flake attribute you specify
- It auto-detects hostname and may deploy desktop config
- Symptoms: Tries to install GRUB instead of systemd-boot
- Safe workaround: Build with `nix build`, then activate directly

**AFTER SUCCESSFUL DEPLOYMENT:**
- Hostname automatically updates to `nixos-laptop`
- Laptop-specific services start: iwd, backlight-permissions, cpufreq, zram
- System uses systemd-boot (not GRUB)

### Desktop Host
**CORRECT COMMANDS:**
- `sudo nixos-rebuild switch --flake .#nixos-desktop` ✅
- `sudo nixos-rebuild switch --flake .#desktop` ✅
- `./user-scripts/nixswitch` ✅ (auto-detects)
=======
## 🚨 CRITICAL: YOU ARE RUNNING ON THE PRODUCTION SERVER 🚨

**⚠️ ULTRA-CRITICAL AWARENESS: YOU ARE THE SERVER HOST ⚠️**

**ENVIRONMENT CONTEXT:**
- **Claude Code is executing DIRECTLY ON the NixOS production server (192.168.1.169)**
- **This is NOT a development machine, NOT a desktop, NOT a remote system**
- **You ARE the server** - Every command runs on the LIVE PRODUCTION SERVER
- **This server hosts**: qBittorrent (24/7 torrenting), Plex Media Server, Audiobookshelf, all media libraries
- **Hostname**: nixos-server (running in Proxmox VM)
- **Users depend on this system**: Media streaming, downloads, audiobooks, file serving

**WHAT THIS MEANS:**
- Any `nixos-rebuild` command will IMMEDIATELY affect the live server
- Any service restart will interrupt active users
- Any misconfiguration will break production services
- This is the ONLY server host - there is no failover

---

## ⚠️ CRITICAL: HOST CONFIGURATION WARNING ⚠️

**THIS SYSTEM IS A SERVER HOST - NOT A DESKTOP HOST**

**MANDATORY RULES:**
1. **NEVER** run `nixos-rebuild switch --flake .#default` or `.#desktop` on this system
2. **NEVER** deploy the desktop or laptop host configuration
3. **ALWAYS** use `.#nixos-server` for all builds and deployments
4. The `desktop` host configuration is for desktop machines only
5. The `server` host uses stable nixpkgs and minimal packages
6. **THINK TWICE** before running any rebuild - you are on the production server

**Sudo password: 123** (for build/deployment commands)

**CORRECT COMMANDS FOR THIS HOST:**
- `sudo nixos-rebuild switch --flake .#nixos-server` ✅ (PRODUCTION SERVER)
- `sudo nixos-rebuild build --flake .#nixos-server` ✅ (test build first)
- `./user-scripts/nixswitch` ✅ (auto-detects host, RECOMMENDED)

**WRONG COMMANDS (WILL BREAK PRODUCTION SERVER):**
- `sudo nixos-rebuild switch --flake .#desktop` ❌ WILL BREAK SERVER
- `sudo nixos-rebuild switch --flake .#laptop` ❌ WILL BREAK SERVER  
- `sudo nixos-rebuild switch --flake .` ❌ WILL BREAK SERVER (defaults to .#desktop)
>>>>>>> origin/host/server

---


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
<<<<<<< HEAD
- **Electron Titlebar Fix**: X11 mode includes `GTK_CSD=0` to prevent duplicate titlebars on Electron apps (Spotify, VS Code, Discord, etc.)
=======
>>>>>>> origin/host/server

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

## Active Technologies
- Nix 2.31.2 (functional, lazy evaluation) + nixpkgs 25.11 (nixos-unstable), flake-parts 1.0 (002-codebase-reduction)
- Git repository, `/nix/store` (immutable store) (002-codebase-reduction)
<<<<<<< HEAD
- Nix expression language (NixOS 25.11 unstable) + GNOME desktop environment modules, nixpkgs GNOME packages (001-gnome-titlebar-fix)
- N/A (configuration-only change) (001-gnome-titlebar-fix)
=======
>>>>>>> origin/host/server

## Recent Changes
- 002-codebase-reduction: Added Nix 2.31.2 (functional, lazy evaluation) + nixpkgs 25.11 (nixos-unstable), flake-parts 1.0

---

## 🚨 Server-Specific Configuration (YOU ARE RUNNING ON THIS SERVER) 🚨

**⚠️ The following configuration applies to THIS MACHINE - the production server you are executing on.**

### Storage Configuration
The server uses a dedicated 2TB disk for media storage:

**IMPORTANT: This system uses UUID-based mounting to prevent disk ordering issues!**
**These disks are physically attached to THIS SERVER that Claude Code is running on.**

**Disk Layout:**
- 128GB disk - System disk (root filesystem, bootloader)
  - Current device: `/dev/sda` (can change!)
  - UUID: `740d22cb-2333-47fd-bb66-92d573e66605`
- 2TB disk - Media disk (torrents, Plex media)
  - Current device: `/dev/sdb` (can change!)
  - UUID: `b51ce311-3e53-4541-b793-96a2615ae16e` (used in configuration)

**WARNING:** Device names (`/dev/sda`, `/dev/sdb`) are NOT stable and can swap between reboots.
Always use UUIDs in configuration files!
  - Mounted at: `/mnt/torrents`
  - Filesystem: ext4
  - Auto-mounts on boot (configured in fileSystems)

**Directory Structure:**
```
/mnt/torrents/ (2TB disk)
├── completed/         # qBittorrent finished downloads (seeding)
├── incomplete/        # Active downloads
├── watch/             # Drop .torrent files for auto-import
└── plex/              # Plex media libraries
    ├── Movies/        # Hardlinked from completed/ (173 GB, 13+ movies)
    ├── TV Shows/      # Auto-populated when TV shows download
    └── AudioBooks/    # SSHFS mount from audiobook server
```

### qBittorrent Configuration

**Service:** `qbittorrent.service`
- Status: Auto-starts on boot, always running
- User: qbittorrent:qbittorrent
- Data directory: /var/lib/qbittorrent
- Web UI: http://192.168.1.169:8080 (no authentication)

**Configuration:**
```nix
modules.services.qbittorrent = {
  enable = true;
  storage.device = "/dev/sda";  # 2TB disk
  downloadDir = "/mnt/torrents/completed";
  incompleteDir = "/mnt/torrents/incomplete";
  port = 8080;  # Web UI
  torrentPort = 6881;
  openFirewall = true;

  settings = {
    maxRatio = 2.0;
    maxSeedingTime = 10080;  # 7 days
    uploadLimit = 1024;  # 1 MB/s
  };

  webUI.bypassLocalAuth = true;  # No password for LAN
};
```

**Important Files:**
- Config: /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf
- Logs: Check with `sudo journalctl -u qbittorrent -f`
- SSH Key: /var/lib/qbittorrent/.ssh/id_ed25519 (for AudioBooks mount)

### Plex Media Server Configuration

**Service:** `plex.service`
- Status: Auto-starts on boot, always running
- User: plex:plex
- Data directory: /var/lib/plex
- Media directory: /mnt/torrents/plex
- Web UI: http://192.168.1.169:32400/web

**Configuration:**
```nix
modules.services.plex = {
  enable = true;
  dataDir = "/var/lib/plex";
  mediaDir = "/mnt/torrents/plex";
  openFirewall = true;

  libraries = {
    movies = true;
    tvShows = true;
    audiobooks = true;
  };

  integration.qbittorrent = {
    enable = true;
    autoScan = true;
    useHardlinks = true;
  };
};
```

**Libraries to Configure in Plex Web UI:**
1. **Movies**: `/mnt/torrents/plex/Movies` (13+ movies, 173 GB)
2. **TV Shows**: `/mnt/torrents/plex/TV Shows` (auto-populated)
3. **AudioBooks**: `/mnt/torrents/plex/AudioBooks` (57 audiobooks, 26 GB via SSHFS)

**Important Files:**
- Plex plugins: /var/lib/plex/Plex Media Server/Plug-ins/
- Audnexus agent: /var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle/
- Plex token: /etc/plex/token (create this after first Plex setup)

### Plex Monitor Daemon

**Service:** `plex-monitor.service`
- Status: Auto-starts on boot, polls qBittorrent every 30 seconds
- User: qbittorrent:qbittorrent
- Log: /var/log/plex-monitor.log

**How It Works:**
1. Monitors qBittorrent API for completed torrents
2. Detects if content is a movie or TV show
3. Creates hardlinks in `/mnt/torrents/plex/Movies/` or `/mnt/torrents/plex/TV Shows/`
4. Triggers Plex library scan via API
5. Maintains state in /var/lib/qbittorrent/processed_torrents.json

**Monitor Logs:**
```bash
sudo tail -f /var/log/plex-monitor.log
sudo systemctl status plex-monitor
```

### AudioBooks SSHFS Mount

**Remote Server:** 192.168.1.7 (audiobook host)
- Username: notroot
- Password: 123
- Remote path: /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged

**Mount Configuration:**
- Local mount: /mnt/torrents/plex/AudioBooks
- Type: SSHFS (fuse.sshfs)
- Authentication: SSH key (/var/lib/qbittorrent/.ssh/id_ed25519)
- Auto-mount: Yes (systemd automount)
- Auto-reconnect: Every 15 seconds if connection lost

**Systemd Units:**
- `mnt-torrents-plex-AudioBooks.mount` - SSHFS mount service
- `mnt-torrents-plex-AudioBooks.automount` - Automatic mounting on access

**Check Mount Status:**
```bash
sudo systemctl status mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks
ls /mnt/torrents/plex/AudioBooks/
```

**SSH Key Management:**
- Key location: /var/lib/qbittorrent/.ssh/id_ed25519
- Public key already added to audiobook server
- Passwordless authentication configured

**Plex AudioBooks Setup:**
- Library type: Music
- Agent: Audnexus (installed in Plex Plug-ins)
- Scanner: Plex Music Scanner
- Settings: Store track progress, use embedded tags
- Full guide: `modules/services/AUDIOBOOKS-SETUP.md`

### Audiobookshelf Configuration (RECOMMENDED)

**Service:** `audiobookshelf.service`
- Status: Auto-starts on boot, Docker container
- Port: 13378
- Data directory: /var/lib/audiobookshelf
- Web UI (Local): http://192.168.1.169:13378
- Web UI (External): https://audiobooks.home301server.com.br

**Why Audiobookshelf:**
- ✅ Purpose-built for audiobooks (not a workaround)
- ✅ Superior metadata (Audible + Google Books + Open Library)
- ✅ Automatic chapter detection and editing
- ✅ Dedicated iOS/Android apps with offline listening
- ✅ Better UI designed for audiobooks
- ✅ Multi-user with cross-device progress sync
- ✅ Actively developed (October 2025)

**Configuration:**
```nix
modules.services.audiobookshelf = {
  enable = true;
  port = 13378;
  audiobooksDir = "/mnt/torrents/plex/AudioBooks";  # Same SSHFS mount
  dataDir = "/var/lib/audiobookshelf";
};
```

**Initial Setup:**
1. Access: https://audiobooks.home301server.com.br (or http://192.168.1.169:13378 locally)
2. Create admin account (first time)
3. Add library: Books → `/audiobooks` folder
4. Download mobile app for best experience

**Cloudflare Tunnel Configuration:**
- Tunnel ID: 7d1704a0-512f-4a54-92c4-d9bf0b4561c3
- Public Domain: audiobooks.home301server.com.br
- Config: ~/.cloudflared/config.yml
- Credentials: ~/.cloudflared/7d1704a0-512f-4a54-92c4-d9bf0b4561c3.json
- Status: Running (start with: cloudflared tunnel --config ~/.cloudflared/config.yml run audiobookshelf)
- Connected to: 4 Cloudflare edge locations

**First-Time Setup:**
The "Server is not initialized" message is NORMAL - this is the admin account
creation screen. Access https://audiobooks.home301server.com.br and create
your account to initialize the server.

**Service Management:**
```bash
sudo systemctl status audiobookshelf
sudo docker logs audiobookshelf
sudo systemctl restart audiobookshelf
```

**Full Guide:** `modules/services/AUDIOBOOKSHELF-SETUP.md`
### Audiobookshelf Protection System

**CRITICAL:** Audiobookshelf will ONLY work at https://audiobooks.home301server.com.br/audiobookshelf/

The `/audiobookshelf/` path is **hardcoded** in the Docker image and cannot be changed.

#### Audiobookshelf Guardian (Protection Service)

The Audiobookshelf Guardian service ensures the application stays healthy and accessible:

**Features:**
- ✅ **Health checks every 5 minutes** - Verifies Docker container, local access, JavaScript assets
- ✅ **Daily automatic backups** - Database backed up to `/var/lib/audiobookshelf/backups/` (keeps last 7)
- ✅ **Automatic recovery** - Restarts container if it stops responding
- ✅ **Configuration validation** - Ensures correct ROUTER_BASE_PATH setting
- ✅ **Cloudflare Tunnel monitoring** - Verifies external access is working

**Monitor Guardian:**
```bash
# View health check status
systemctl status audiobookshelf-health-check.timer

# View backup status
systemctl status audiobookshelf-backup.timer

# Check guardian logs
tail -f /var/log/audiobookshelf-guardian.log

# Manual health check
sudo systemctl start audiobookshelf-health-check.service

# View backups
ls -lh /var/lib/audiobookshelf/backups/
```

**Health Check Tests:**
1. ✓ Docker container is running
2. ✓ Local access working (http://localhost:13378/audiobookshelf/)
3. ✓ JavaScript assets accessible (/_nuxt/*.js)
4. ✓ Config directory exists
5. ✓ AudioBooks directory accessible
6. ✓ Cloudflare Tunnel is active
7. ✓ Container ROUTER_BASE_PATH configuration

#### Disk Guardian Integration

The Disk Guardian also monitors Audiobookshelf every 60 seconds:

**Monitors:**
- ✅ Docker container running status
- ✅ HTTP response on port 13378
- ✅ Automatic container restart if stopped
- ✅ Cloudflare Tunnel status
- ✅ Automatic tunnel restart if stopped

**Check monitoring:**
```bash
tail -f /var/log/disk-guardian.log | grep -E "(Audiobookshelf|Cloudflare)"
```

#### What Will NEVER Break Audiobookshelf Again

**1. Wrong URL Path** ❌ PREVENTED
- Guardian validates `/audiobookshelf/` path is working
- Documentation clearly states the correct URL
- Health checks test both HTML and JavaScript assets

**2. Container Stops** ❌ PREVENTED
- Disk Guardian monitors container every 60 seconds
- Automatic restart if container stops
- Both systemd and Docker auto-restart enabled

**3. Data Loss** ❌ PREVENTED
- Daily automatic database backups
- Keeps last 7 backups (rotating cleanup)
- Backups stored in `/var/lib/audiobookshelf/backups/`

**4. Configuration Changes** ❌ PREVENTED
- NixOS module locks configuration
- ROUTER_BASE_PATH removed (uses default)
- Systemd service ensures consistent Docker run command

**5. Cloudflare Tunnel Failure** ❌ PREVENTED
- Disk Guardian monitors tunnel every 60 seconds
- Automatic restart if tunnel stops
- Systemd ensures tunnel starts on boot

**6. AudioBooks Mount Failure** ❌ PREVENTED
- Disk Guardian monitors SSHFS mount
- Automatic remount attempts
- Health check validates directory accessibility

#### Recovery from Complete Failure

If Audiobookshelf completely breaks, here's how to recover:

**1. Check Guardian Status:**
```bash
sudo systemctl status audiobookshelf-health-check.timer
sudo tail -50 /var/log/audiobookshelf-guardian.log
```

**2. Check Service and Container:**
```bash
sudo systemctl status audiobookshelf
sudo docker ps -a | grep audiobookshelf
sudo docker logs audiobookshelf
```

**3. Restart Everything:**
```bash
# Restart Audiobookshelf
sudo systemctl restart audiobookshelf

# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared-tunnel

# Run health check
sudo systemctl start audiobookshelf-health-check.service
```

**4. Restore from Backup (if needed):**
```bash
# Stop service
sudo systemctl stop audiobookshelf

# List backups
ls -lh /var/lib/audiobookshelf/backups/

# Restore database (replace TIMESTAMP with actual backup)
sudo cp /var/lib/audiobookshelf/backups/absdatabase_TIMESTAMP.sqlite \
       /var/lib/audiobookshelf/config/absdatabase.sqlite

# Start service
sudo systemctl start audiobookshelf
```

**5. Complete Reset (nuclear option):**
```bash
# Stop and remove everything
sudo systemctl stop audiobookshelf
sudo docker rm -f audiobookshelf

# Clear data (WARNING: loses all settings!)
sudo rm -rf /var/lib/audiobookshelf/*

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-server
```

#### Correct URL Reference Card

**ALWAYS use these URLs:**

✅ **External:** https://audiobooks.home301server.com.br/audiobookshelf/  
✅ **Local:** http://192.168.1.169:13378/audiobookshelf/

❌ **WRONG (will hang forever):**
- https://audiobooks.home301server.com.br/ (missing /audiobookshelf/)
- http://192.168.1.169:13378/ (missing /audiobookshelf/)

**Why?** The Audiobookshelf Docker image has this path hardcoded. It cannot be changed.

### Remote AudioBooks Server Status

**Remote Server:** 192.168.1.7 (audiobook host)
- **Status:** Check with `ping 192.168.1.7`
- If unreachable: Audiobookshelf will start WITHOUT audiobooks library
- If accessible: SSHFS mount will auto-connect

**Reconnect AudioBooks Mount (when server comes back online):**
```bash
# 1. Verify server is reachable
ping -c 3 192.168.1.7

# 2. Test SSH access
ssh -i /var/lib/qbittorrent/.ssh/id_ed25519 notroot@192.168.1.7 'ls /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged'

# 3. Restart SSHFS mount
sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks

# 4. Restart Audiobookshelf to pick up the mount
sudo systemctl restart audiobookshelf

# 5. Verify audiobooks are accessible
sudo ls /mnt/torrents/plex/AudioBooks/
```

**Note:** Audiobookshelf will work fine without the remote mount - it just won't show the audiobooks library until reconnected.

---

## 🚨 Server-Specific Configuration (YOU ARE RUNNING ON THIS SERVER) 🚨

**⚠️ The following configuration applies to THIS MACHINE - the production server you are executing on.**

### Storage Configuration
The server uses a dedicated 2TB disk for media storage:

**IMPORTANT: This system uses UUID-based mounting to prevent disk ordering issues!**
**These disks are physically attached to THIS SERVER that Claude Code is running on.**

**Disk Layout:**
- 128GB disk - System disk (root filesystem, bootloader)
  - Current device: `/dev/sda` (can change!)
  - UUID: `740d22cb-2333-47fd-bb66-92d573e66605`
- 2TB disk - Media disk (torrents, Plex media)
  - Current device: `/dev/sdb` (can change!)
  - UUID: `b51ce311-3e53-4541-b793-96a2615ae16e` (used in configuration)

**WARNING:** Device names (`/dev/sda`, `/dev/sdb`) are NOT stable and can swap between reboots.
Always use UUIDs in configuration files!
  - Mounted at: `/mnt/torrents`
  - Filesystem: ext4
  - Auto-mounts on boot (configured in fileSystems)

**Directory Structure:**
```
/mnt/torrents/ (2TB disk)
├── completed/         # qBittorrent finished downloads (seeding)
├── incomplete/        # Active downloads
├── watch/             # Drop .torrent files for auto-import
└── plex/              # Plex media libraries
    ├── Movies/        # Hardlinked from completed/ (173 GB, 13+ movies)
    ├── TV Shows/      # Auto-populated when TV shows download
    └── AudioBooks/    # SSHFS mount from audiobook server
```

### qBittorrent Configuration

**Service:** `qbittorrent.service`
- Status: Auto-starts on boot, always running
- User: qbittorrent:qbittorrent
- Data directory: /var/lib/qbittorrent
- Web UI: http://192.168.1.169:8080 (no authentication)

**Configuration:**
```nix
modules.services.qbittorrent = {
  enable = true;
  storage.device = "/dev/sda";  # 2TB disk
  downloadDir = "/mnt/torrents/completed";
  incompleteDir = "/mnt/torrents/incomplete";
  port = 8080;  # Web UI
  torrentPort = 6881;
  openFirewall = true;

  settings = {
    maxRatio = 2.0;
    maxSeedingTime = 10080;  # 7 days
    uploadLimit = 1024;  # 1 MB/s
  };

  webUI.bypassLocalAuth = true;  # No password for LAN
};
```

**Important Files:**
- Config: /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf
- Logs: Check with `sudo journalctl -u qbittorrent -f`
- SSH Key: /var/lib/qbittorrent/.ssh/id_ed25519 (for AudioBooks mount)

### Plex Media Server Configuration

**Service:** `plex.service`
- Status: Auto-starts on boot, always running
- User: plex:plex
- Data directory: /var/lib/plex
- Media directory: /mnt/torrents/plex
- Web UI: http://192.168.1.169:32400/web

**Configuration:**
```nix
modules.services.plex = {
  enable = true;
  dataDir = "/var/lib/plex";
  mediaDir = "/mnt/torrents/plex";
  openFirewall = true;

  libraries = {
    movies = true;
    tvShows = true;
    audiobooks = true;
  };

  integration.qbittorrent = {
    enable = true;
    autoScan = true;
    useHardlinks = true;
  };
};
```

**Libraries to Configure in Plex Web UI:**
1. **Movies**: `/mnt/torrents/plex/Movies` (13+ movies, 173 GB)
2. **TV Shows**: `/mnt/torrents/plex/TV Shows` (auto-populated)
3. **AudioBooks**: `/mnt/torrents/plex/AudioBooks` (57 audiobooks, 26 GB via SSHFS)

**Important Files:**
- Plex plugins: /var/lib/plex/Plex Media Server/Plug-ins/
- Audnexus agent: /var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle/
- Plex token: /etc/plex/token (create this after first Plex setup)

### Plex Monitor Daemon

**Service:** `plex-monitor.service`
- Status: Auto-starts on boot, polls qBittorrent every 30 seconds
- User: qbittorrent:qbittorrent
- Log: /var/log/plex-monitor.log

**How It Works:**
1. Monitors qBittorrent API for completed torrents
2. Detects if content is a movie or TV show
3. Creates hardlinks in `/mnt/torrents/plex/Movies/` or `/mnt/torrents/plex/TV Shows/`
4. Triggers Plex library scan via API
5. Maintains state in /var/lib/qbittorrent/processed_torrents.json

**Monitor Logs:**
```bash
sudo tail -f /var/log/plex-monitor.log
sudo systemctl status plex-monitor
```

### AudioBooks SSHFS Mount

**Remote Server:** 192.168.1.7 (audiobook host)
- Username: notroot
- Password: 123
- Remote path: /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged

**Mount Configuration:**
- Local mount: /mnt/torrents/plex/AudioBooks
- Type: SSHFS (fuse.sshfs)
- Authentication: SSH key (/var/lib/qbittorrent/.ssh/id_ed25519)
- Auto-mount: Yes (systemd automount)
- Auto-reconnect: Every 15 seconds if connection lost

**Systemd Units:**
- `mnt-torrents-plex-AudioBooks.mount` - SSHFS mount service
- `mnt-torrents-plex-AudioBooks.automount` - Automatic mounting on access

**Check Mount Status:**
```bash
sudo systemctl status mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks
ls /mnt/torrents/plex/AudioBooks/
```

**SSH Key Management:**
- Key location: /var/lib/qbittorrent/.ssh/id_ed25519
- Public key already added to audiobook server
- Passwordless authentication configured

**Plex AudioBooks Setup:**
- Library type: Music
- Agent: Audnexus (installed in Plex Plug-ins)
- Scanner: Plex Music Scanner
- Settings: Store track progress, use embedded tags
- Full guide: `modules/services/AUDIOBOOKS-SETUP.md`

### Audiobookshelf Configuration (RECOMMENDED)

**Service:** `audiobookshelf.service`
- Status: Auto-starts on boot, Docker container
- Port: 13378
- Data directory: /var/lib/audiobookshelf
- Web UI (Local): http://192.168.1.169:13378
- Web UI (External): https://audiobooks.home301server.com.br

**Why Audiobookshelf:**
- ✅ Purpose-built for audiobooks (not a workaround)
- ✅ Superior metadata (Audible + Google Books + Open Library)
- ✅ Automatic chapter detection and editing
- ✅ Dedicated iOS/Android apps with offline listening
- ✅ Better UI designed for audiobooks
- ✅ Multi-user with cross-device progress sync
- ✅ Actively developed (October 2025)

**Configuration:**
```nix
modules.services.audiobookshelf = {
  enable = true;
  port = 13378;
  audiobooksDir = "/mnt/torrents/plex/AudioBooks";  # Same SSHFS mount
  dataDir = "/var/lib/audiobookshelf";
};
```

**Initial Setup:**
1. Access: https://audiobooks.home301server.com.br (or http://192.168.1.169:13378 locally)
2. Create admin account (first time)
3. Add library: Books → `/audiobooks` folder
4. Download mobile app for best experience

**Cloudflare Tunnel Configuration:**
- Tunnel ID: 7d1704a0-512f-4a54-92c4-d9bf0b4561c3
- Public Domain: audiobooks.home301server.com.br
- Config: ~/.cloudflared/config.yml
- Credentials: ~/.cloudflared/7d1704a0-512f-4a54-92c4-d9bf0b4561c3.json
- Status: Running (start with: cloudflared tunnel --config ~/.cloudflared/config.yml run audiobookshelf)
- Connected to: 4 Cloudflare edge locations

**First-Time Setup:**
The "Server is not initialized" message is NORMAL - this is the admin account
creation screen. Access https://audiobooks.home301server.com.br and create
your account to initialize the server.

**Service Management:**
```bash
sudo systemctl status audiobookshelf
sudo docker logs audiobookshelf
sudo systemctl restart audiobookshelf
```

**Full Guide:** `modules/services/AUDIOBOOKSHELF-SETUP.md`
### Audiobookshelf Protection System

**CRITICAL:** Audiobookshelf will ONLY work at https://audiobooks.home301server.com.br/audiobookshelf/

The `/audiobookshelf/` path is **hardcoded** in the Docker image and cannot be changed.

#### Audiobookshelf Guardian (Protection Service)

The Audiobookshelf Guardian service ensures the application stays healthy and accessible:

**Features:**
- ✅ **Health checks every 5 minutes** - Verifies Docker container, local access, JavaScript assets
- ✅ **Daily automatic backups** - Database backed up to `/var/lib/audiobookshelf/backups/` (keeps last 7)
- ✅ **Automatic recovery** - Restarts container if it stops responding
- ✅ **Configuration validation** - Ensures correct ROUTER_BASE_PATH setting
- ✅ **Cloudflare Tunnel monitoring** - Verifies external access is working

**Monitor Guardian:**
```bash
# View health check status
systemctl status audiobookshelf-health-check.timer

# View backup status
systemctl status audiobookshelf-backup.timer

# Check guardian logs
tail -f /var/log/audiobookshelf-guardian.log

# Manual health check
sudo systemctl start audiobookshelf-health-check.service

# View backups
ls -lh /var/lib/audiobookshelf/backups/
```

**Health Check Tests:**
1. ✓ Docker container is running
2. ✓ Local access working (http://localhost:13378/audiobookshelf/)
3. ✓ JavaScript assets accessible (/_nuxt/*.js)
4. ✓ Config directory exists
5. ✓ AudioBooks directory accessible
6. ✓ Cloudflare Tunnel is active
7. ✓ Container ROUTER_BASE_PATH configuration

#### Disk Guardian Integration

The Disk Guardian also monitors Audiobookshelf every 60 seconds:

**Monitors:**
- ✅ Docker container running status
- ✅ HTTP response on port 13378
- ✅ Automatic container restart if stopped
- ✅ Cloudflare Tunnel status
- ✅ Automatic tunnel restart if stopped

**Check monitoring:**
```bash
tail -f /var/log/disk-guardian.log | grep -E "(Audiobookshelf|Cloudflare)"
```

#### What Will NEVER Break Audiobookshelf Again

**1. Wrong URL Path** ❌ PREVENTED
- Guardian validates `/audiobookshelf/` path is working
- Documentation clearly states the correct URL
- Health checks test both HTML and JavaScript assets

**2. Container Stops** ❌ PREVENTED
- Disk Guardian monitors container every 60 seconds
- Automatic restart if container stops
- Both systemd and Docker auto-restart enabled

**3. Data Loss** ❌ PREVENTED
- Daily automatic database backups
- Keeps last 7 backups (rotating cleanup)
- Backups stored in `/var/lib/audiobookshelf/backups/`

**4. Configuration Changes** ❌ PREVENTED
- NixOS module locks configuration
- ROUTER_BASE_PATH removed (uses default)
- Systemd service ensures consistent Docker run command

**5. Cloudflare Tunnel Failure** ❌ PREVENTED
- Disk Guardian monitors tunnel every 60 seconds
- Automatic restart if tunnel stops
- Systemd ensures tunnel starts on boot

**6. AudioBooks Mount Failure** ❌ PREVENTED
- Disk Guardian monitors SSHFS mount
- Automatic remount attempts
- Health check validates directory accessibility

#### Recovery from Complete Failure

If Audiobookshelf completely breaks, here's how to recover:

**1. Check Guardian Status:**
```bash
sudo systemctl status audiobookshelf-health-check.timer
sudo tail -50 /var/log/audiobookshelf-guardian.log
```

**2. Check Service and Container:**
```bash
sudo systemctl status audiobookshelf
sudo docker ps -a | grep audiobookshelf
sudo docker logs audiobookshelf
```

**3. Restart Everything:**
```bash
# Restart Audiobookshelf
sudo systemctl restart audiobookshelf

# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared-tunnel

# Run health check
sudo systemctl start audiobookshelf-health-check.service
```

**4. Restore from Backup (if needed):**
```bash
# Stop service
sudo systemctl stop audiobookshelf

# List backups
ls -lh /var/lib/audiobookshelf/backups/

# Restore database (replace TIMESTAMP with actual backup)
sudo cp /var/lib/audiobookshelf/backups/absdatabase_TIMESTAMP.sqlite \
       /var/lib/audiobookshelf/config/absdatabase.sqlite

# Start service
sudo systemctl start audiobookshelf
```

**5. Complete Reset (nuclear option):**
```bash
# Stop and remove everything
sudo systemctl stop audiobookshelf
sudo docker rm -f audiobookshelf

# Clear data (WARNING: loses all settings!)
sudo rm -rf /var/lib/audiobookshelf/*

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-server
```

#### Correct URL Reference Card

**ALWAYS use these URLs:**

✅ **External:** https://audiobooks.home301server.com.br/audiobookshelf/  
✅ **Local:** http://192.168.1.169:13378/audiobookshelf/

❌ **WRONG (will hang forever):**
- https://audiobooks.home301server.com.br/ (missing /audiobookshelf/)
- http://192.168.1.169:13378/ (missing /audiobookshelf/)

**Why?** The Audiobookshelf Docker image has this path hardcoded. It cannot be changed.

### Remote AudioBooks Server Status

**Remote Server:** 192.168.1.7 (audiobook host)
- **Status:** Check with `ping 192.168.1.7`
- If unreachable: Audiobookshelf will start WITHOUT audiobooks library
- If accessible: SSHFS mount will auto-connect

**Reconnect AudioBooks Mount (when server comes back online):**
```bash
# 1. Verify server is reachable
ping -c 3 192.168.1.7

# 2. Test SSH access
ssh -i /var/lib/qbittorrent/.ssh/id_ed25519 notroot@192.168.1.7 'ls /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged'

# 3. Restart SSHFS mount
sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks

# 4. Restart Audiobookshelf to pick up the mount
sudo systemctl restart audiobookshelf

# 5. Verify audiobooks are accessible
sudo ls /mnt/torrents/plex/AudioBooks/
```

**Note:** Audiobookshelf will work fine without the remote mount - it just won't show the audiobooks library until reconnected.
## 🚨 Server-Specific Configuration (YOU ARE RUNNING ON THIS SERVER) 🚨

**⚠️ The following configuration applies to THIS MACHINE - the production server you are executing on.**

### Storage Configuration
The server uses a dedicated 2TB disk for media storage:

**IMPORTANT: This system uses UUID-based mounting to prevent disk ordering issues!**
**These disks are physically attached to THIS SERVER that Claude Code is running on.**

**Disk Layout:**
- 128GB disk - System disk (root filesystem, bootloader)
  - Current device: `/dev/sda` (can change!)
  - UUID: `740d22cb-2333-47fd-bb66-92d573e66605`
- 2TB disk - Media disk (torrents, Plex media)
  - Current device: `/dev/sdb` (can change!)
  - UUID: `b51ce311-3e53-4541-b793-96a2615ae16e` (used in configuration)

**WARNING:** Device names (`/dev/sda`, `/dev/sdb`) are NOT stable and can swap between reboots.
Always use UUIDs in configuration files!
  - Mounted at: `/mnt/torrents`
  - Filesystem: ext4
  - Auto-mounts on boot (configured in fileSystems)

**Directory Structure:**
```
/mnt/torrents/ (2TB disk)
├── completed/         # qBittorrent finished downloads (seeding)
├── incomplete/        # Active downloads
├── watch/             # Drop .torrent files for auto-import
└── plex/              # Plex media libraries
    ├── Movies/        # Hardlinked from completed/ (173 GB, 13+ movies)
    ├── TV Shows/      # Auto-populated when TV shows download
    └── AudioBooks/    # SSHFS mount from audiobook server
```

### qBittorrent Configuration

**Service:** `qbittorrent.service`
- Status: Auto-starts on boot, always running
- User: qbittorrent:qbittorrent
- Data directory: /var/lib/qbittorrent
- Web UI: http://192.168.1.169:8080 (no authentication)

**Configuration:**
```nix
modules.services.qbittorrent = {
  enable = true;
  storage.device = "/dev/sda";  # 2TB disk
  downloadDir = "/mnt/torrents/completed";
  incompleteDir = "/mnt/torrents/incomplete";
  port = 8080;  # Web UI
  torrentPort = 6881;
  openFirewall = true;

  settings = {
    maxRatio = 2.0;
    maxSeedingTime = 10080;  # 7 days
    uploadLimit = 1024;  # 1 MB/s
  };

  webUI.bypassLocalAuth = true;  # No password for LAN
};
```

**Important Files:**
- Config: /var/lib/qbittorrent/qBittorrent/config/qBittorrent.conf
- Logs: Check with `sudo journalctl -u qbittorrent -f`
- SSH Key: /var/lib/qbittorrent/.ssh/id_ed25519 (for AudioBooks mount)

### Plex Media Server Configuration

**Service:** `plex.service`
- Status: Auto-starts on boot, always running
- User: plex:plex
- Data directory: /var/lib/plex
- Media directory: /mnt/torrents/plex
- Web UI: http://192.168.1.169:32400/web

**Configuration:**
```nix
modules.services.plex = {
  enable = true;
  dataDir = "/var/lib/plex";
  mediaDir = "/mnt/torrents/plex";
  openFirewall = true;

  libraries = {
    movies = true;
    tvShows = true;
    audiobooks = true;
  };

  integration.qbittorrent = {
    enable = true;
    autoScan = true;
    useHardlinks = true;
  };
};
```

**Libraries to Configure in Plex Web UI:**
1. **Movies**: `/mnt/torrents/plex/Movies` (13+ movies, 173 GB)
2. **TV Shows**: `/mnt/torrents/plex/TV Shows` (auto-populated)
3. **AudioBooks**: `/mnt/torrents/plex/AudioBooks` (57 audiobooks, 26 GB via SSHFS)

**Important Files:**
- Plex plugins: /var/lib/plex/Plex Media Server/Plug-ins/
- Audnexus agent: /var/lib/plex/Plex Media Server/Plug-ins/Audnexus.bundle/
- Plex token: /etc/plex/token (create this after first Plex setup)

### Plex Monitor Daemon

**Service:** `plex-monitor.service`
- Status: Auto-starts on boot, polls qBittorrent every 30 seconds
- User: qbittorrent:qbittorrent
- Log: /var/log/plex-monitor.log

**How It Works:**
1. Monitors qBittorrent API for completed torrents
2. Detects if content is a movie or TV show
3. Creates hardlinks in `/mnt/torrents/plex/Movies/` or `/mnt/torrents/plex/TV Shows/`
4. Triggers Plex library scan via API
5. Maintains state in /var/lib/qbittorrent/processed_torrents.json

**Monitor Logs:**
```bash
sudo tail -f /var/log/plex-monitor.log
sudo systemctl status plex-monitor
```

### AudioBooks SSHFS Mount

**Remote Server:** 192.168.1.7 (audiobook host)
- Username: notroot
- Password: 123
- Remote path: /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged

**Mount Configuration:**
- Local mount: /mnt/torrents/plex/AudioBooks
- Type: SSHFS (fuse.sshfs)
- Authentication: SSH key (/var/lib/qbittorrent/.ssh/id_ed25519)
- Auto-mount: Yes (systemd automount)
- Auto-reconnect: Every 15 seconds if connection lost

**Systemd Units:**
- `mnt-torrents-plex-AudioBooks.mount` - SSHFS mount service
- `mnt-torrents-plex-AudioBooks.automount` - Automatic mounting on access

**Check Mount Status:**
```bash
sudo systemctl status mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks
ls /mnt/torrents/plex/AudioBooks/
```

**SSH Key Management:**
- Key location: /var/lib/qbittorrent/.ssh/id_ed25519
- Public key already added to audiobook server
- Passwordless authentication configured

**Plex AudioBooks Setup:**
- Library type: Music
- Agent: Audnexus (installed in Plex Plug-ins)
- Scanner: Plex Music Scanner
- Settings: Store track progress, use embedded tags
- Full guide: `modules/services/AUDIOBOOKS-SETUP.md`

### Audiobookshelf Configuration (RECOMMENDED)

**Service:** `audiobookshelf.service`
- Status: Auto-starts on boot, Docker container
- Port: 13378
- Data directory: /var/lib/audiobookshelf
- Web UI (Local): http://192.168.1.169:13378
- Web UI (External): https://audiobooks.home301server.com.br

**Why Audiobookshelf:**
- ✅ Purpose-built for audiobooks (not a workaround)
- ✅ Superior metadata (Audible + Google Books + Open Library)
- ✅ Automatic chapter detection and editing
- ✅ Dedicated iOS/Android apps with offline listening
- ✅ Better UI designed for audiobooks
- ✅ Multi-user with cross-device progress sync
- ✅ Actively developed (October 2025)

**Configuration:**
```nix
modules.services.audiobookshelf = {
  enable = true;
  port = 13378;
  audiobooksDir = "/mnt/torrents/plex/AudioBooks";  # Same SSHFS mount
  dataDir = "/var/lib/audiobookshelf";
};
```

**Initial Setup:**
1. Access: https://audiobooks.home301server.com.br (or http://192.168.1.169:13378 locally)
2. Create admin account (first time)
3. Add library: Books → `/audiobooks` folder
4. Download mobile app for best experience

**Cloudflare Tunnel Configuration:**
- Tunnel ID: 7d1704a0-512f-4a54-92c4-d9bf0b4561c3
- Public Domain: audiobooks.home301server.com.br
- Config: ~/.cloudflared/config.yml
- Credentials: ~/.cloudflared/7d1704a0-512f-4a54-92c4-d9bf0b4561c3.json
- Status: Running (start with: cloudflared tunnel --config ~/.cloudflared/config.yml run audiobookshelf)
- Connected to: 4 Cloudflare edge locations

**First-Time Setup:**
The "Server is not initialized" message is NORMAL - this is the admin account
creation screen. Access https://audiobooks.home301server.com.br and create
your account to initialize the server.

**Service Management:**
```bash
sudo systemctl status audiobookshelf
sudo docker logs audiobookshelf
sudo systemctl restart audiobookshelf
```

**Full Guide:** `modules/services/AUDIOBOOKSHELF-SETUP.md`
### Audiobookshelf Protection System

**CRITICAL:** Audiobookshelf will ONLY work at https://audiobooks.home301server.com.br/audiobookshelf/

The `/audiobookshelf/` path is **hardcoded** in the Docker image and cannot be changed.

#### Audiobookshelf Guardian (Protection Service)

The Audiobookshelf Guardian service ensures the application stays healthy and accessible:

**Features:**
- ✅ **Health checks every 5 minutes** - Verifies Docker container, local access, JavaScript assets
- ✅ **Daily automatic backups** - Database backed up to `/var/lib/audiobookshelf/backups/` (keeps last 7)
- ✅ **Automatic recovery** - Restarts container if it stops responding
- ✅ **Configuration validation** - Ensures correct ROUTER_BASE_PATH setting
- ✅ **Cloudflare Tunnel monitoring** - Verifies external access is working

**Monitor Guardian:**
```bash
# View health check status
systemctl status audiobookshelf-health-check.timer

# View backup status
systemctl status audiobookshelf-backup.timer

# Check guardian logs
tail -f /var/log/audiobookshelf-guardian.log

# Manual health check
sudo systemctl start audiobookshelf-health-check.service

# View backups
ls -lh /var/lib/audiobookshelf/backups/
```

**Health Check Tests:**
1. ✓ Docker container is running
2. ✓ Local access working (http://localhost:13378/audiobookshelf/)
3. ✓ JavaScript assets accessible (/_nuxt/*.js)
4. ✓ Config directory exists
5. ✓ AudioBooks directory accessible
6. ✓ Cloudflare Tunnel is active
7. ✓ Container ROUTER_BASE_PATH configuration

#### Disk Guardian Integration

The Disk Guardian also monitors Audiobookshelf every 60 seconds:

**Monitors:**
- ✅ Docker container running status
- ✅ HTTP response on port 13378
- ✅ Automatic container restart if stopped
- ✅ Cloudflare Tunnel status
- ✅ Automatic tunnel restart if stopped

**Check monitoring:**
```bash
tail -f /var/log/disk-guardian.log | grep -E "(Audiobookshelf|Cloudflare)"
```

#### What Will NEVER Break Audiobookshelf Again

**1. Wrong URL Path** ❌ PREVENTED
- Guardian validates `/audiobookshelf/` path is working
- Documentation clearly states the correct URL
- Health checks test both HTML and JavaScript assets

**2. Container Stops** ❌ PREVENTED
- Disk Guardian monitors container every 60 seconds
- Automatic restart if container stops
- Both systemd and Docker auto-restart enabled

**3. Data Loss** ❌ PREVENTED
- Daily automatic database backups
- Keeps last 7 backups (rotating cleanup)
- Backups stored in `/var/lib/audiobookshelf/backups/`

**4. Configuration Changes** ❌ PREVENTED
- NixOS module locks configuration
- ROUTER_BASE_PATH removed (uses default)
- Systemd service ensures consistent Docker run command

**5. Cloudflare Tunnel Failure** ❌ PREVENTED
- Disk Guardian monitors tunnel every 60 seconds
- Automatic restart if tunnel stops
- Systemd ensures tunnel starts on boot

**6. AudioBooks Mount Failure** ❌ PREVENTED
- Disk Guardian monitors SSHFS mount
- Automatic remount attempts
- Health check validates directory accessibility

#### Recovery from Complete Failure

If Audiobookshelf completely breaks, here's how to recover:

**1. Check Guardian Status:**
```bash
sudo systemctl status audiobookshelf-health-check.timer
sudo tail -50 /var/log/audiobookshelf-guardian.log
```

**2. Check Service and Container:**
```bash
sudo systemctl status audiobookshelf
sudo docker ps -a | grep audiobookshelf
sudo docker logs audiobookshelf
```

**3. Restart Everything:**
```bash
# Restart Audiobookshelf
sudo systemctl restart audiobookshelf

# Restart Cloudflare Tunnel
sudo systemctl restart cloudflared-tunnel

# Run health check
sudo systemctl start audiobookshelf-health-check.service
```

**4. Restore from Backup (if needed):**
```bash
# Stop service
sudo systemctl stop audiobookshelf

# List backups
ls -lh /var/lib/audiobookshelf/backups/

# Restore database (replace TIMESTAMP with actual backup)
sudo cp /var/lib/audiobookshelf/backups/absdatabase_TIMESTAMP.sqlite \
       /var/lib/audiobookshelf/config/absdatabase.sqlite

# Start service
sudo systemctl start audiobookshelf
```

**5. Complete Reset (nuclear option):**
```bash
# Stop and remove everything
sudo systemctl stop audiobookshelf
sudo docker rm -f audiobookshelf

# Clear data (WARNING: loses all settings!)
sudo rm -rf /var/lib/audiobookshelf/*

# Rebuild
sudo nixos-rebuild switch --flake .#nixos-server
```

#### Correct URL Reference Card

**ALWAYS use these URLs:**

✅ **External:** https://audiobooks.home301server.com.br/audiobookshelf/  
✅ **Local:** http://192.168.1.169:13378/audiobookshelf/

❌ **WRONG (will hang forever):**
- https://audiobooks.home301server.com.br/ (missing /audiobookshelf/)
- http://192.168.1.169:13378/ (missing /audiobookshelf/)

**Why?** The Audiobookshelf Docker image has this path hardcoded. It cannot be changed.

### Remote AudioBooks Server Status

**Remote Server:** 192.168.1.7 (audiobook host)
- **Status:** Check with `ping 192.168.1.7`
- If unreachable: Audiobookshelf will start WITHOUT audiobooks library
- If accessible: SSHFS mount will auto-connect

**Reconnect AudioBooks Mount (when server comes back online):**
```bash
# 1. Verify server is reachable
ping -c 3 192.168.1.7

# 2. Test SSH access
ssh -i /var/lib/qbittorrent/.ssh/id_ed25519 notroot@192.168.1.7 'ls /home/notroot/Documents/PLEX_AUDIOBOOK/temp/untagged'

# 3. Restart SSHFS mount
sudo systemctl restart mnt-torrents-plex-AudioBooks.mount
mount | grep AudioBooks

# 4. Restart Audiobookshelf to pick up the mount
sudo systemctl restart audiobookshelf

# 5. Verify audiobooks are accessible
sudo ls /mnt/torrents/plex/AudioBooks/
```

**Note:** Audiobookshelf will work fine without the remote mount - it just won't show the audiobooks library until reconnected.
