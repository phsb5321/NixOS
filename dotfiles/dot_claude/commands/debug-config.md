---
applyTo: '**/*.nix'
description: "Debug NixOS configuration issues with systematic troubleshooting"
---

# NixOS Configuration Debugging

Systematic approach to diagnosing and fixing NixOS configuration issues:

## Issue Analysis Phase
1. **Error Collection**:
   - Parse build error messages for root cause
   - Check system journal: `journalctl -xe -b`
   - Review failed systemd services: `systemctl --failed`
   - Examine Nix build logs for detailed errors

2. **Configuration Validation**:
   - Run `nix flake check` for syntax validation
   - Test configuration parsing with `nix eval`
   - Verify module imports and dependencies
   - Check for conflicting options

3. **Dependency Analysis**:
   - Trace dependency chains causing issues
   - Identify version conflicts or missing packages
   - Check for circular dependencies in modules

## Systematic Debugging
1. **Binary Search Approach**:
   - Isolate problematic configuration sections
   - Temporarily disable modules to identify culprit
   - Test minimal configuration first

2. **Common Issue Patterns**:
   - Hardware configuration mismatches
   - Module option conflicts (e.g., display managers)
   - Package version incompatibilities
   - Service startup failures

3. **Build Environment Issues**:
   - Check available disk space and memory
   - Verify network connectivity for fetches
   - Examine Nix store corruption

## Solution Implementation
1. **Targeted Fixes**:
   - Apply minimal changes to resolve specific issues
   - Document workarounds for known problems
   - Update configuration with proper error handling

2. **Preventive Measures**:
   - Add validation checks to configuration
   - Implement configuration testing workflow
   - Set up monitoring for configuration drift

## Recovery Procedures
1. **Rollback Strategy**:
   - Use `nixos-rebuild --rollback` for immediate recovery
   - Boot from previous generation in GRUB
   - Emergency boot procedures

2. **Emergency Fixes**:
   - Boot from NixOS installer for rescue operations
   - Mount and chroot into broken system
   - Manual configuration repair procedures

## Arguments Support
- `$ARGUMENTS` can specify error context or system component
- Include specific error messages for targeted debugging

## Example Usage
```bash
# General configuration debugging
/debug-config

# Specific error message
/debug-config "error: attribute 'nonExistentOption' missing"

# Service-specific debugging
/debug-config systemd
```

Execute this workflow autonomously, providing clear diagnosis and step-by-step solutions.