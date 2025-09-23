# NixOS Configuration Project

This is a comprehensive NixOS configuration managed through a flake-based approach with modular architecture and dotfiles integration.

## Project Overview

**Architecture**: Modular NixOS flake configuration with:
- Host-specific configurations (default=desktop, laptop)  
- Shared module system for reusable components
- Chezmoi-managed dotfiles for user configuration
- Performance-optimized settings for gaming and development

## Key Directories

- `hosts/`: Host-specific configurations (hardware, packages, services)
- `modules/`: Shared NixOS modules organized by category
- `shells/`: Development environment shells for different languages  
- `dotfiles/`: Chezmoi-managed user configuration files
- `user-scripts/`: Custom automation scripts (nixswitch, shell-selector)

## Current Configuration

**Primary Host**: `default` (desktop)
- AMD GPU with hardware acceleration
- 62GB RAM, swap disabled for performance
- Gaming-optimized with performance CPU governor
- Wayland-only GNOME (NixOS 25.11+ requirement)
- Tailscale mesh networking enabled

**Performance Optimizations Applied**:
- CPU governor: performance mode
- Kernel parameters: preempt=full, nohz_full=all
- Memory management: vm.swappiness=1, optimized dirty ratios
- Filesystem: noatime mounting for SSD optimization

## Development Environment

**Editors**: Zed (primary with Claude Code integration), VS Code
**Shells**: Zsh with PowerLevel10k, multiple development shells available
**Languages**: Nix, JavaScript/TypeScript, Python, Rust, Elixir, Go
**Tools**: Comprehensive development stack with language servers

## Common Tasks

Use the custom slash commands for routine operations:
- `/nix-rebuild` - Smart system rebuilding with validation
- `/optimize-performance` - System performance analysis and tuning  
- `/debug-config` - NixOS configuration troubleshooting
- `/create-module` - Generate new NixOS modules with templates
- `/best-practices` - Apply code and configuration best practices
- `/security-scan` - Comprehensive security analysis
- `/test-strategy` - Generate testing strategies and implementation

## Key Scripts

- `./user-scripts/nixswitch` - Modern TUI-based rebuild with error handling
- `./user-scripts/nix-shell-selector.sh` - Interactive development environment selector
- `dotfiles-*` commands - Chezmoi dotfiles management

## Important Notes

- Always test configuration changes with `nix flake check` before rebuilding
- Use the performance-optimized settings carefully on different hardware
- The configuration is designed for high-memory systems (62GB+)
- Gaming optimizations may not be suitable for battery-powered devices
- Security settings are tuned for desktop use, adjust for server deployments

## Project Standards

- Follow modular architecture patterns
- Use lib.mkDefault for overrideable defaults
- Maintain backward compatibility across NixOS versions
- Document all custom modules and significant changes
- Keep dotfiles and system configuration separate but coordinated