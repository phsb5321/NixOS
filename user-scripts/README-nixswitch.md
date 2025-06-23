# Enhanced NixSwitch Documentation

## Overview

The enhanced `nixswitch` script (v5.0.0) provides significant improvements over the previous version, focusing on performance, parallel processing, and intelligent system management.

## Key Improvements

### 🚀 Performance Enhancements

1. **Parallel Processing**: Utilizes all available CPU cores (28 in your system) for faster builds
2. **Intelligent Garbage Collection**: Multiple cleanup strategies with parallel execution
3. **Build Optimizations**: Pre-build cache warming and optimal Nix settings
4. **Store Optimization**: Automatic deduplication and integrity checks

### 🧹 Enhanced Garbage Collection

The script now includes several garbage collection strategies:

- **Standard GC**: Removes old generations and unused store paths
- **Aggressive GC**: Deep cleanup including build caches and temporary files
- **Parallel Cleanup**: Multiple cleanup tasks run simultaneously
- **Smart Disk Management**: Checks available space before operations

### ⚡ New Features

1. **Fast Build Mode** (`--fast`): Skips some optimizations for quicker rebuilds
2. **System Information** (`--info`): Shows detailed system metrics
3. **Enhanced Validation**: Security checks and configuration validation
4. **Better Error Handling**: Detailed error reporting with color coding
5. **Background Tasks**: Non-blocking maintenance operations

## Usage Examples

### Basic Usage
```bash
# Standard rebuild with all optimizations
./user-scripts/nixswitch.sh default

# Fast rebuild (skip some optimizations)
./user-scripts/nixswitch.sh --fast default

# Dry run to see what would happen
./user-scripts/nixswitch.sh --dry-run default
```

### Advanced Usage
```bash
# Aggressive cleanup with verbose output
./user-scripts/nixswitch.sh --aggressive-gc --verbose default

# Build without updating or pushing to git
./user-scripts/nixswitch.sh --no-update --no-push default

# Test configuration without applying
./user-scripts/nixswitch.sh --operation test default
```

### Maintenance Operations
```bash
# List available hosts
./user-scripts/nixswitch.sh --list

# Show system information
./user-scripts/nixswitch.sh --info

# Show generation history
./user-scripts/nixswitch.sh --generations

# Rollback to previous generation
./user-scripts/nixswitch.sh --rollback
```

## Flake Optimizations

The `flake.nix` has been enhanced with:

### Build Performance
- Automatic core detection and utilization
- Optimized cache settings
- Parallel downloading
- Store auto-optimization

### Garbage Collection
- Automatic weekly cleanup
- Configurable retention policies
- Size-based cleanup triggers

### Security
- Sandbox builds enabled
- Trusted cache sources
- Experimental feature flags for performance

## Configuration Options

### Environment Variables
- `NIX_BUILD_CORES`: Override CPU core usage
- `NIX_CONFIG`: Custom Nix configuration

### Script Options
```bash
# Keep generations for 14 days instead of 7
./user-scripts/nixswitch.sh --keep 14 default

# Skip specific operations
./user-scripts/nixswitch.sh --no-gc --no-maintenance default

# Verbose output for debugging
./user-scripts/nixswitch.sh --verbose default
```

## Performance Monitoring

The script tracks:
- Build times for each operation
- Disk space usage
- Memory consumption
- Parallel task completion

## Troubleshooting

### Common Issues

1. **Low disk space**: The script checks for minimum 5GB free space
2. **Lock file conflicts**: Prevents multiple instances from running
3. **Build failures**: Enhanced error reporting with color coding
4. **Permission issues**: Improved sudo handling with keep-alive

### Log Files

Logs are stored in `~/.local/share/nixos-rebuild/logs/` with timestamps and detailed error information.

## Alias Setup

For convenience, add to your shell configuration:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias nixswitch="$HOME/NixOS/user-scripts/nixswitch.sh"
alias nxs="$HOME/NixOS/user-scripts/nixswitch.sh"
```

## Safety Features

- **Dry run mode**: Test without making changes
- **Configuration validation**: Checks syntax and dependencies
- **Lock file protection**: Prevents concurrent executions
- **Rollback capability**: Easy recovery from failed builds
- **Backup integration**: Automatic git commits for configuration changes

## Performance Tips

1. Use `--fast` for development iterations
2. Use `--aggressive-gc` periodically for deep cleanup
3. Monitor disk space with `--info`
4. Use `--no-update` to skip input updates during testing
5. Enable `--verbose` for troubleshooting

## Migration from Old Script

The new script is backward compatible with the old `nixos-rebuild.sh`. Simply replace calls to the old script with the new one, or use the provided alias.
