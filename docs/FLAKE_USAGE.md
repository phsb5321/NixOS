# Flake Usage Guide

This document describes how to use the NixOS flake configuration system.

## Overview

This flake provides a modular NixOS configuration with support for multiple hosts, modern package management, and development tools.

## Flake Outputs

### NixOS Configurations

Build and deploy NixOS systems:

```bash
# Build for default host (desktop)
nixos-rebuild build --flake .#default

# Switch to new configuration
sudo nixos-rebuild switch --flake .#default

# Build for laptop
nixos-rebuild build --flake .#laptop
```

Available hosts:
- `default` - Desktop system (nixos-desktop) using nixpkgs-unstable
- `laptop` - Laptop system (nixos-laptop) using stable nixpkgs
- `nixos` - Alias for default (compatibility)

### Formatter

Format all Nix files using alejandra:

```bash
# Format entire repository
nix fmt

# Or use directly
alejandra .
```

### Checks

Run validation checks:

```bash
# Run all checks
nix flake check

# Run specific checks
nix build .#checks.x86_64-linux.format-check
nix build .#checks.x86_64-linux.lint-check
nix build .#checks.x86_64-linux.deadnix-check
```

Available checks:
- `format-check` - Verify Nix file formatting
- `lint-check` - Run statix linter
- `deadnix-check` - Find unused code

### Apps

Run common tasks with apps:

```bash
# Format all files
nix run .#format

# Update flake inputs
nix run .#update

# Check configuration
nix run .#check-config
```

### Development Shell

Enter development environment:

```bash
# Enter default shell
nix develop

# Or use direnv (if configured)
direnv allow
```

The dev shell includes:
- `alejandra` - Nix formatter
- `statix` - Nix linter
- `deadnix` - Dead code detection
- `nixos-rebuild` - System rebuild tools
- `git` - Version control

### Packages

Helper scripts for deployment:

```bash
# Deploy to a host
nix run .#deploy -- hostname

# Build without switching
nix run .#build -- hostname
```

## Common Workflows

### Daily Development

```bash
# Enter dev shell
nix develop

# Make changes to configuration
# ...

# Format code
alejandra .

# Check for issues
statix check .
deadnix .

# Verify configuration
nix flake check

# Build and test
nixos-rebuild build --flake .#default
```

### Adding a New Host

1. Create host directory:
   ```bash
   mkdir -p hosts/newhost
   ```

2. Add configuration:
   ```nix
   # hosts/newhost/configuration.nix
   { config, pkgs, lib, ... }: {
     imports = [ ./hardware-configuration.nix ../../modules ];
     # Your configuration...
   }
   ```

3. Register in flake.nix:
   ```nix
   hosts = {
     # ...existing hosts...
     newhost = {
       system = "x86_64-linux";
       hostname = "my-hostname";
       configPath = "newhost";
     };
   };
   ```

4. Build and test:
   ```bash
   nixos-rebuild build --flake .#newhost
   ```

### Updating Dependencies

```bash
# Update all inputs
nix flake update

# Or use the app
nix run .#update

# Update specific input
nix flake lock --update-input nixpkgs

# Review changes
git diff flake.lock

# Test with new inputs
nix flake check
```

### CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: CI
on: [push, pull_request]

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Check flake
        run: nix flake check

      - name: Build configurations
        run: |
          nix build .#nixosConfigurations.default.config.system.build.toplevel
          nix build .#nixosConfigurations.laptop.config.system.build.toplevel
```

## Flake Structure

```
flake.nix           # Main flake configuration
├── inputs          # External dependencies
│   ├── nixpkgs     # Stable NixOS packages
│   ├── nixpkgs-unstable # Latest packages
│   ├── firefox-nightly
│   ├── zen-browser
│   ├── flake-utils
│   ├── flake-parts (ready for future use)
│   └── sops-nix    # Secrets management
│
└── outputs
    ├── nixosConfigurations  # System configurations
    ├── formatter            # Code formatter (alejandra)
    ├── checks               # Validation checks
    ├── devShells           # Development environments
    ├── apps                # Runnable applications
    └── packages            # Helper scripts
```

## Advanced Usage

### Using Different nixpkgs Versions

Each host can use a different nixpkgs version:

```nix
hosts = {
  myhost = {
    system = "x86_64-linux";
    hostname = "my-host";
    configPath = "myhost";
    nixpkgsInput = nixpkgs;        # Stable
    # nixpkgsInput = nixpkgs-unstable; # Or unstable
  };
};
```

### Custom Special Args

Pass additional arguments to host configurations:

```nix
hosts = {
  myhost = {
    # ...
    extraSpecialArgs = {
      myCustomArg = "value";
    };
  };
};
```

### Testing Changes

```bash
# Build without activating
nixos-rebuild build --flake .#default

# Test in VM
nixos-rebuild build-vm --flake .#default
./result/bin/run-nixos-vm

# Dry run (show what would change)
nixos-rebuild dry-run --flake .#default
```

## Troubleshooting

### Flake Evaluation Errors

```bash
# Show full trace
nix flake check --show-trace

# Verbose output
nix flake check -vv
```

### Build Failures

```bash
# Clear cache
nix-collect-garbage -d

# Rebuild from scratch
nixos-rebuild switch --flake .#default --rebuild
```

### Format Issues

```bash
# Check formatting without changing
alejandra --check .

# Format specific file
alejandra path/to/file.nix
```

## References

- [Nix Flakes Manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Alejandra Formatter](https://github.com/kamadorueda/alejandra)
- [Statix Linter](https://github.com/nerdypepper/statix)
