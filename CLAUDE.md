# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Host Context: LAPTOP

**This is the LAPTOP host configuration.**

**Environment:**
- **Host**: `laptop` (mobile workstation)
- **GPU**: Intel integrated + NVIDIA discrete (hybrid graphics)
- **Display**: X11 (for NVIDIA compatibility)
- **Branch**: `host/laptop`
- **Focus**: Development, portability, power management

---

## NixOS Rebuild Commands

**CORRECT COMMANDS FOR THIS HOST:**
```bash
sudo nixos-rebuild switch --flake .#laptop   # Deploy laptop configuration
sudo nixos-rebuild build --flake .#laptop    # Test build first
./user-scripts/nixswitch                      # Auto-detects host (RECOMMENDED)
```

**WRONG COMMANDS (will deploy wrong configuration):**
```bash
sudo nixos-rebuild switch --flake .#desktop     # WRONG - desktop config
sudo nixos-rebuild switch --flake .#nixos-server # WRONG - server config
sudo nixos-rebuild switch --flake .              # WRONG - defaults to desktop
```

**Sudo password: 123**

---

## Laptop Hardware Configuration

### GPU Setup (Hybrid Graphics)
- **Intel iGPU**: Primary display, power efficient
- **NVIDIA dGPU**: Available for compute/gaming via PRIME
- **Display Protocol**: X11 (required for NVIDIA compatibility)
- **Power Management**: TLP enabled for battery optimization

### Power Management
- Battery-saving GNOME settings enabled
- TLP for advanced power management
- Suspend on lid close
- Screen timeout optimized for battery

### Hardware-Specific Notes
- Uses laptop profile with power optimizations
- ZRAM enabled for memory efficiency
- WiFi power management configured

---

## Branch Strategy

**Current Branch**: `host/laptop`

This branch contains laptop-specific changes. General workflow:

```bash
# Laptop-specific changes stay on host/laptop
git checkout host/laptop
# Make changes
git commit -m "feat(laptop): description"
git push origin host/laptop
# Create PR: host/laptop → develop when ready
```

**Branch Structure:**
```
main (protected)
├── develop (integration branch)
│   ├── host/desktop (desktop workstation)
│   └── host/laptop (this branch)
```

---

## Common Development Commands

### NixOS Rebuilds
- `./user-scripts/nixswitch` - TUI-based rebuild with auto-host detection
- `sudo nixos-rebuild switch --flake .#laptop` - Manual rebuild
- `sudo nixos-rebuild test --flake .#laptop` - Test without switching
- `sudo nixos-rebuild build --flake .#laptop` - Build only

### Development Environments
- `./user-scripts/nix-shell-selector.sh` - Interactive shell selector
- `nix-shell shells/JavaScript.nix` - JavaScript development
- `nix-shell shells/Python.nix` - Python development
- `nix-shell shells/Rust.nix` - Rust development
- Available: JavaScript, Python, Golang, ESP, Rust, Elixir

### Flake Operations
- `nix flake update` - Update all inputs
- `nix flake check` - Validate configuration
- `alejandra .` - Format Nix code

### System Maintenance
- `./user-scripts/nixos-maintenance.sh` - Comprehensive maintenance
- `nix-collect-garbage -d` - Garbage collection
- `nix-store --optimise` - Deduplicate store

### Dotfiles Management (chezmoi)
- `dotfiles-init` - Initialize dotfiles
- `dotfiles-status` - Check status
- `dotfiles-check` - Validate before applying
- `dotfiles-apply` - Apply changes
- `dotfiles-add ~/.config/file` - Add new file
- `dotfiles-drift` - Check for drift

---

## Architecture Overview

### Flake Structure
```
flake.nix              # Main entry point
hosts/
├── laptop/            # This host's configuration
│   ├── configuration.nix
│   ├── hardware-configuration.nix
│   └── gnome.nix
├── desktop/           # Desktop workstation
└── nixos-server/      # Media server
modules/               # Shared modules
├── core/              # Base system config
├── desktop/gnome/     # GNOME configuration
├── hardware/          # Hardware modules
├── packages/          # Package categories
└── profiles/laptop.nix # Laptop profile
shells/                # Development environments
dotfiles/              # Chezmoi-managed configs
user-scripts/          # Custom scripts
```

### Laptop Profile Features
- Power management optimizations
- Battery-aware settings
- ZRAM for memory efficiency
- Hybrid GPU support
- WiFi power management

### Package Categories
The laptop uses a subset of available packages:
- **Development**: Editors, language servers, dev tools
- **Browsers**: Chrome, Brave, Zen
- **Media**: VLC, Spotify (optional)
- **Utilities**: System tools, disk management
- **Gaming**: Disabled by default (battery consideration)

---

## GNOME Configuration

### Laptop-Specific Settings
- **Display**: X11 for NVIDIA compatibility
- **Power**: 5-minute idle timeout, suspend on AC
- **Extensions**: 9 extensions (minimal set)
- **Workspaces**: Primary display only

### Extension List
- AppIndicator, Dash to Dock, User Themes
- Just Perfection, Vitals, Caffeine
- Clipboard Indicator, GSConnect, Workspace Indicator

---

## NO HOME MANAGER POLICY

This configuration uses **chezmoi dotfiles** for all user-level configuration.

**DO NOT suggest Home Manager.** Use dotfiles instead:
```bash
dotfiles-add ~/.config/app/config.yml
dotfiles-apply
```

See `dotfiles/README.md` for detailed usage.

---

## Key Differences from Other Hosts

| Feature | Laptop | Desktop | Server |
|---------|--------|---------|--------|
| GPU | Intel/NVIDIA hybrid | AMD RX 5700 XT | VirtIO |
| Display | X11 | Wayland | X11 |
| Gaming | Disabled | Enabled | N/A |
| Power mgmt | TLP + battery | Performance | Always-on |
| Services | Minimal | Full | Media stack |

---

## Troubleshooting

### NVIDIA Issues
```bash
# Check NVIDIA driver status
nvidia-smi
# Switch to Intel-only mode if needed
# (requires configuration change)
```

### Power/Battery Issues
```bash
# Check TLP status
sudo tlp-stat -s
# Check power profile
powerprofilectl get
```

### WiFi Issues
```bash
# Check network status
nmcli device status
# Restart NetworkManager
sudo systemctl restart NetworkManager
```

---

## Quick Reference

```bash
# Rebuild system
./user-scripts/nixswitch

# Check configuration
nix flake check

# Update flake inputs
nix flake update

# Format code
alejandra .

# Dotfiles status
dotfiles-status

# Enter dev shell
./user-scripts/nix-shell-selector.sh
```

## Active Technologies
- Nix (NixOS configuration language) + NixOS modules, nixos-hardware flake, nixpkgs (stable channel) (011-laptop-gaming-setup)
- N/A (system configuration, no database) (011-laptop-gaming-setup)

## Recent Changes
- 011-laptop-gaming-setup: Added Nix (NixOS configuration language) + NixOS modules, nixos-hardware flake, nixpkgs (stable channel)
