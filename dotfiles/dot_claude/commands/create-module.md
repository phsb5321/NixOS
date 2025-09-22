---
applyTo: '**'
description: "Generate new NixOS modules with proper structure and best practices"
---

# NixOS Module Generator

Create well-structured NixOS modules following best practices and conventions:

## Module Structure Analysis
1. **Determine Module Type**:
   - Service module (systemd services, daemons)
   - Package module (application configurations)
   - Hardware module (device-specific settings)
   - Desktop module (GUI applications, themes)

2. **Identify Dependencies**:
   - Required system packages
   - Service dependencies and ordering
   - Configuration file requirements
   - User/group needs

## Module Template Generation
1. **Base Structure**:
   ```nix
   { config, lib, pkgs, ... }:
   with lib;
   let
     cfg = config.modules.${category}.${moduleName};
   in {
     options.modules.${category}.${moduleName} = {
       enable = mkEnableOption "${description}";
       # Additional options...
     };

     config = mkIf cfg.enable {
       # Implementation...
     };
   }
   ```

2. **Option Definitions**:
   - Use appropriate option types (bool, str, listOf, attrsOf)
   - Provide sensible defaults with `mkDefault`
   - Add comprehensive descriptions
   - Include example configurations

3. **Implementation Patterns**:
   - Service configurations using `systemd.services`
   - Package installations via `environment.systemPackages`
   - Configuration file generation
   - User environment setup

## Best Practices Implementation
1. **Code Quality**:
   - Follow NixOS module conventions
   - Use proper indentation and formatting
   - Add comprehensive comments
   - Implement error handling

2. **Configuration Validation**:
   - Add assertion checks for conflicting options
   - Validate file paths and permissions
   - Check service dependencies

3. **Documentation**:
   - Include module purpose and usage
   - Document all options with examples
   - Add troubleshooting guidance

## Integration Setup
1. **Module Registration**:
   - Add to appropriate category in `modules/default.nix`
   - Update host configurations to enable module
   - Test module loading and option exposure

2. **Testing Framework**:
   - Create test configuration
   - Validate service startup
   - Check configuration file generation

## Arguments Support
- `$ARGUMENTS` specifies: `<category> <module-name> [description]`
- Categories: `core`, `desktop`, `packages`, `networking`, `security`

## Example Usage
```bash
# Create a desktop application module
/create-module desktop firefox "Firefox browser configuration"

# Create a service module
/create-module core monitoring "System monitoring services"

# Create a package module
/create-module packages development "Development tools collection"
```

## Output Structure
```
modules/${category}/${module-name}.nix
├── Options definition with proper types
├── Configuration implementation
├── Service definitions (if applicable)
├── Package specifications
└── Documentation comments
```

Execute this workflow autonomously, generating production-ready NixOS modules with proper structure and documentation.