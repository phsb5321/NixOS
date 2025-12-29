# NixOS Configuration Project

This is a comprehensive NixOS configuration managed through a flake-based approach with modular architecture and dotfiles integration.

## CRITICAL: NixOS Rebuild Commands

**ALWAYS use the correct flake target when rebuilding:**

```bash
# Desktop host (primary workstation)
sudo nixos-rebuild switch --flake .#desktop

# Laptop host
sudo nixos-rebuild switch --flake .#laptop

# Server host
sudo nixos-rebuild switch --flake .#server
```

**NEVER use:**
- `sudo nixos-rebuild switch --flake .` (missing host target)
- `sudo nixos-rebuild switch` (not using flake)

The flake defines multiple hosts and requires explicit target specification.

## Project Overview

**Architecture**: Modular NixOS flake configuration with:
- Host-specific configurations (desktop, laptop, server)
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

**Primary Host**: `desktop`
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

## Dotfiles Management

Chezmoi-based dotfiles management with validation, drift detection, and mutable file support.

### Core Commands

| Command | Description |
|---------|-------------|
| `dotfiles-init` | Initialize chezmoi with NixOS project dotfiles |
| `dotfiles-apply` | Apply dotfiles from source to target (skips mutable with drift) |
| `dotfiles-status` | Show status with drift indicators and mutability info |
| `dotfiles-add <file>` | Add new file to managed dotfiles |
| `dotfiles-edit` | Open dotfiles directory in editor |

### Validation & Sync Commands

| Command | Description |
|---------|-------------|
| `dotfiles-validate [--fix]` | Validate JSON/JSONC files for syntax and duplicate keys |
| `dotfiles-check` | Full validation including sensitive data and hardcoded paths |
| `dotfiles-drift [--diff] [--json]` | Show drift between source and target dotfiles |
| `dotfiles-capture [--dry-run]` | Capture runtime changes back to source |

### Command Options

**dotfiles-apply**:
- `--diff` - Show diff without applying
- `--force-all` - Force apply all files, including mutable files with drift
- `<file>...` - Apply specific files only

**dotfiles-validate**:
- `--fix` - Automatically fix duplicate keys (keeps last value)
- `--source/--target/--both` - Choose which locations to validate
- `-q, --quiet` - Only output errors

**dotfiles-drift**:
- `--diff` - Show full unified diff for each changed file
- `--json` - Output in JSON format for scripting
- `--mutable-only` - Only show mutable files

**dotfiles-capture**:
- `--dry-run` - Preview changes without modifying source
- `--all` - Include immutable files in capture
- `--force` - Skip confirmation prompts

### Configuration Options

Configure in NixOS configuration:
```nix
modules.dotfiles = {
  enable = true;
  validateJson = true;  # Enable JSON validation
  mutableFiles = [      # Files that can be modified at runtime
    ".config/zed/settings.json"
    ".config/Code/User/settings.json"
  ];
};
```

### Workflow Examples

**Capture GUI changes back to source**:
```bash
# Make changes via application GUI
dotfiles-drift          # See what changed
dotfiles-capture        # Adopt changes to source
cd ~/NixOS && git commit -am "Update settings"
```

**Fix duplicate key errors**:
```bash
dotfiles-validate --fix  # Auto-fix duplicate keys
dotfiles-apply           # Apply fixed config
```

## Important Notes

- **Always use explicit flake targets** when rebuilding (e.g., `.#desktop`, `.#laptop`)
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