# Deployment Guide

## Overview

This NixOS configuration supports multiple deployment methods:

1. **nixswitch** - Local TUI-based rebuild (recommended for single-machine)
2. **nixos-rebuild** - Standard NixOS rebuild commands
3. **colmena** - Remote multi-host deployment

## Quick Reference

| Method | Use Case | Command |
|--------|----------|---------|
| nixswitch | Local rebuild with TUI | `./user-scripts/nixswitch` |
| nixos-rebuild | Manual local rebuild | `sudo nixos-rebuild switch --flake .#<host>` |
| colmena build | Build all hosts | `colmena build --impure` |
| colmena apply | Deploy to host | `colmena apply --impure --on <host>` |

## Host Overview

| Host | Description | nixpkgs Channel | Tags |
|------|-------------|-----------------|------|
| desktop | Primary workstation | nixpkgs-unstable | canary, workstation |
| laptop | Portable machine | nixpkgs (stable) | portable |
| server | Production server | nixpkgs (stable) | production |

## Migration Order

When deploying changes, follow this order to minimize risk:

1. **Desktop (canary)** - Test on primary machine first
2. **Laptop** - Validate portability
3. **Server** - Stability-critical, deploy last

## nixswitch (Recommended)

The `nixswitch` script provides an interactive TUI for local rebuilds:

```bash
./user-scripts/nixswitch
```

Features:
- Auto-detects current host
- Shows diff before applying
- Rollback support
- Progress indicators

## Manual nixos-rebuild

For direct control over rebuilds:

```bash
# Build without switching (safe, can run anywhere)
nix build .#nixosConfigurations.desktop.config.system.build.toplevel

# Test configuration (creates generation but doesn't make it default)
sudo nixos-rebuild test --flake .#desktop

# Switch to new configuration
sudo nixos-rebuild switch --flake .#desktop

# Build and boot into new configuration on next reboot
sudo nixos-rebuild boot --flake .#desktop
```

**WARNING:** Only run `nixos-rebuild switch` on the target machine. Running desktop configuration on server WILL break the system.

## Colmena Deployment

Colmena enables remote deployment to multiple hosts.

### Prerequisites

1. SSH access to target hosts as root
2. Hosts resolvable by hostname (or edit `deployment.targetHost` in hosts.nix)
3. colmena CLI (via `nix shell nixpkgs#colmena`)

### Basic Usage

```bash
# Enter shell with colmena
nix shell nixpkgs#colmena

# List all hosts
colmena eval --impure -E '{ nodes, ... }: builtins.attrNames nodes'

# Build all hosts
colmena build --impure

# Build specific host
colmena build --impure --on desktop

# Deploy to specific host
colmena apply --impure --on desktop

# Deploy to hosts by tag
colmena apply --impure --on @canary      # Desktop only
colmena apply --impure --on @portable    # Laptop only
colmena apply --impure --on @production  # Server only
```

### Deployment Modes

```bash
# switch: Build, activate, and make default (most common)
colmena apply --impure --on desktop

# boot: Build and make default, activate on next boot
colmena apply --impure --on desktop boot

# test: Build and activate, but don't make default
colmena apply --impure --on desktop test

# dry-activate: Build and show what would change
colmena apply --impure --on desktop dry-activate
```

### Remote Deployment

For remote deployment, ensure:

1. SSH keys are set up for root access
2. Target host is reachable by hostname

```bash
# Deploy to remote server
colmena apply --impure --on server

# Deploy to all hosts sequentially
colmena apply --impure

# Deploy to multiple specific hosts
colmena apply --impure --on desktop,laptop
```

### Parallel Builds

```bash
# Build all hosts in parallel
colmena build --impure --parallel

# Limit parallelism
colmena build --impure --parallel --limit 2
```

## Safety Guidelines

### Before Deploying

1. Ensure all changes are committed (dirty tree warnings are normal but track your changes)
2. Test build first: `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`
3. Review the diff: `nixos-rebuild build --flake .#<host> && nvd diff /run/current-system result`

### During Deployment

1. Deploy to desktop first (canary)
2. Verify functionality before proceeding
3. Keep SSH session open when deploying to remote hosts

### After Deployment

1. Verify critical services are running
2. Test login/sudo if user config changed
3. Check systemd journal for errors: `journalctl -b -p err`

### Rollback

If something goes wrong:

```bash
# List generations
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Switch to previous generation
sudo nixos-rebuild switch --rollback

# Or switch to specific generation
sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <number>
```

## Troubleshooting

### Colmena "pure mode" errors

Use `--impure` flag when working with dirty git tree:
```bash
colmena build --impure
```

### SSH connection refused

1. Check if SSH is enabled on target
2. Verify root login is permitted (or use `deployment.targetUser`)
3. Check firewall rules

### Build failures

1. Check the specific error message
2. Test with standard nix build first:
   ```bash
   nix build .#nixosConfigurations.<host>.config.system.build.toplevel --show-trace
   ```

### Host not found

Edit `deployment.targetHost` in `flake-modules/hosts.nix` to use IP address instead of hostname.

## Configuration Reference

### Host Configuration

Colmena configuration is in `flake-modules/hosts.nix`:

```nix
colmena = {
  meta = {
    nixpkgs = import inputs.nixpkgs { ... };
    nodeNixpkgs = {
      desktop = import inputs.nixpkgs-unstable { ... };
      # ...
    };
  };

  desktop = { ... }: {
    deployment = {
      targetHost = "nixos-desktop";
      targetUser = "root";
      tags = ["desktop" "workstation" "canary"];
    };
    imports = [../hosts/desktop/configuration.nix];
  };
  # ...
};
```

### Adding a New Host

1. Create `hosts/<hostname>/configuration.nix`
2. Add host definition to `hosts` in `flake-modules/hosts.nix`
3. Add colmena node config following existing pattern
4. Test build: `nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel`
