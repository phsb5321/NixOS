# NixOS Configuration Documentation

This directory contains comprehensive documentation for the NixOS configuration.

## Quick Start

For immediate setup and common tasks, see the main [README.md](../README.md) in the project root.

## Documentation Structure

### Desktop Environment

- [GNOME Theming Guide](gnome-theming.md) - Modern theming setup, accent colors, and management tools

### System Configuration

- [Wayland Improvements](wayland-improvements.md) - Wayland setup and troubleshooting
- [Modules Documentation](modules/) - Detailed module configuration guides
- [Troubleshooting](troubleshooting/) - Common issues and solutions

## Utility Scripts

The following management scripts are available in `/user-scripts/`:

### System Management

- `nixswitch.sh` - Enhanced NixOS rebuild script with parallel processing
- `nix-shell-selector.sh` - Development environment selector

### System Utilities

- `wayland-diagnostic.sh` - Wayland troubleshooting and diagnostics
- `fix-bluetooth-headset.sh` - Bluetooth audio fixes
- `gnome-session-cleanup.sh` - GNOME session management
- `kill_port.sh` - Port management utility
- `textractor.sh` - Text extraction tool

## Getting Help

Each script includes built-in help accessible with the `--help` or `-h` flag:

```bash
./script-name.sh --help
```

## Configuration Layout

```
NixOS/
├── docs/                    # Documentation (this directory)
├── hosts/                   # Host-specific configurations
├── modules/                 # Reusable NixOS modules
├── shells/                  # Development environments
├── user-scripts/           # Management and utility scripts
├── flake.nix              # Main Nix flake configuration
└── README.md              # Project overview and quick start
```

## Contributing

When adding new features or making changes:

1. Update relevant documentation in this directory
2. Test scripts and configurations thoroughly
3. Follow existing code organization patterns
4. Update this index if adding new documentation files
