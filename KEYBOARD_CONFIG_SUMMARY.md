# Keyboard Configuration Summary

## ✅ Current Status: DEFAULT HOST USES /etc/nixos KEYBOARD CONFIG

The default host now uses the same keyboard configuration as `/etc/nixos/configuration.nix` for better compatibility, while the laptop maintains explicit ABNT2 configuration.

### Configuration Details

**Default host:**

- **X11 Layout**: `br` (Brazilian)
- **X11 Variant**: `""` (Standard Brazilian ABNT - matches `/etc/nixos/configuration.nix`)
- **Console Keymap**: `br-abnt2` (matches `/etc/nixos/configuration.nix`)
- **Source**: Based on system's `/etc/nixos/configuration.nix`

**Laptop host:**

- **X11 Layout**: `br` (Brazilian)
- **X11 Variant**: `abnt2` (Brazilian ABNT2)
- **X11 Options**: `grp:alt_shift_toggle,compose:ralt`
- **Console Keymap**: `br-abnt2`
- **Keyboard Handling**: Explicit NixOS configuration

### Configuration Sources

1. **Default Host** (`hosts/default/configuration.nix`):
   - Uses the exact same keyboard configuration as `/etc/nixos/configuration.nix`
   - X11 layout: `br` with empty variant (standard Brazilian ABNT)
   - Console keymap: `br-abnt2`

2. **Laptop Host** (`hosts/laptop/configuration.nix`):
   - Enables `modules.core.keyboard.enable = true`
   - Uses `mkForce` to override with `abnt2` variant
   - Console keymap: `br-abnt2`

3. **Core Module** (`modules/core/default.nix`):
   - Keyboard configuration only applied when `keyboard.enable = true`
   - Allows hosts to use their own explicit keyboard settings

4. **Desktop Modules**:
   - Removed explicit keyboard configurations
   - Allows hosts to define their own keyboard settings

### Recent Fixes Applied

- ✅ Applied `/etc/nixos/configuration.nix` keyboard configuration to default host
- ✅ Default host now uses `br` layout with empty variant (standard Brazilian ABNT)
- ✅ Default host console keymap set to `br-abnt2` (matches system config)
- ✅ Laptop host maintains explicit ABNT2 configuration with `modules.core.keyboard.enable = true`
- ✅ Updated syntax to use `services.xserver.xkb` format (not deprecated format)
- ✅ Tested configuration with `nix flake check` and `nix eval`
- ✅ Both hosts now have proven working keyboard configurations

### Testing Commands

```bash
# Test X11 keyboard configuration
nix eval .#nixosConfigurations.default.config.services.xserver.xkb --json
nix eval .#nixosConfigurations.laptop.config.services.xserver.xkb --json

# Test console keyboard configuration  
nix eval .#nixosConfigurations.default.config.console.keyMap --json
nix eval .#nixosConfigurations.laptop.config.console.keyMap --json
```

### Expected Output

**Default host commands should show:**

- **X11 Layout**: `"br"`
- **X11 Variant**: `""` (empty string - standard Brazilian ABNT)
- **Console Keymap**: `"br-abnt2"`

**Laptop host commands should show:**

- **X11 Layout**: `"br"`
- **X11 Variant**: `"abnt2"`
- **X11 Options**: `"grp:alt_shift_toggle,compose:ralt"`
- **Console Keymap**: `"br-abnt2"`

## No Further Actions Needed

The keyboard configuration now uses proven working settings:

- **Default host**: Uses the exact same keyboard configuration as `/etc/nixos/configuration.nix` (br layout, empty variant, br-abnt2 console)
- **Laptop host**: Uses explicit Brazilian ABNT2 configuration via NixOS

This ensures the default host has the same keyboard behavior as the system's base configuration, providing reliable and consistent keyboard functionality.
