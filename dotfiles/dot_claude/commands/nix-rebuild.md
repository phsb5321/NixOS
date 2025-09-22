---
applyTo: '**/*.nix'
description: "Smart NixOS system rebuild with host detection and validation"
---

# NixOS Smart Rebuild

Execute a comprehensive NixOS system rebuild with the following workflow:

## Pre-Build Validation
1. **Check Git Status**: Ensure no uncommitted changes that could break the build
2. **Validate Syntax**: Run `nix flake check` to validate configuration
3. **Host Detection**: Auto-detect current host (default/laptop) from hostname
4. **Disk Space**: Verify sufficient disk space (minimum 5GB free)

## Build Process
1. **Update Flakes**: `nix flake update` to get latest packages
2. **Build Configuration**: Use the modern `nixswitch` script for TUI-based rebuilding
3. **Error Handling**: If build fails, provide specific debugging steps
4. **Rollback Plan**: Show how to rollback if issues occur

## Post-Build Verification
1. **Service Status**: Check critical services are running
2. **Performance**: Verify system responsiveness
3. **Documentation**: Update CLAUDE.md with any changes made

## Command Arguments
- `$ARGUMENTS` can specify: `test`, `build`, `switch`, or `boot`
- Default: `switch` for immediate activation
- Use `test` for safe testing without bootloader changes

## Example Usage
```bash
# Standard rebuild
/nix-rebuild

# Test mode only
/nix-rebuild test

# Build without switching
/nix-rebuild build
```

Execute this workflow autonomously, providing clear status updates at each step.