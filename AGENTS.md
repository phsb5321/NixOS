# NixOS Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-09

## Git Branch Workflow (CRITICAL)

**AI agents MUST follow this workflow. Never stay on feature branches indefinitely.**

### Branch Structure

```
main                    # Production-ready, rarely touched directly
├── host/desktop        # Desktop machine configuration (PRIMARY)
├── host/laptop         # Laptop configuration  
├── host/server         # Server configuration
└── feature branches    # Temporary, merge back quickly
```

### Workflow Rules

1. **Start from host branch**: Always begin work from the appropriate `host/*` branch
   ```bash
   git checkout host/desktop
   git pull origin host/desktop
   ```

2. **Create feature branch for significant work**:
   ```bash
   git checkout -b NNN-feature-name  # NNN = issue number or sequential ID
   ```

3. **Small changes**: Commit directly to host branch (no feature branch needed)

4. **Before ending session**: ALWAYS merge completed work back to host branch
   ```bash
   # Verify build passes
   nix build .#nixosConfigurations.desktop.config.system.build.toplevel --dry-run
   
   # Merge to host branch
   git checkout host/desktop
   git merge feature-branch-name
   
   # Delete feature branch if done
   git branch -d feature-branch-name
   ```

5. **Never leave work stranded**: If work is incomplete, either:
   - Merge what's working to host branch
   - Document clearly in handoff.md what remains
   - Push feature branch to remote for continuity

### Branch Check Command

Run this at session start and before committing:
```bash
./scripts/branch-check
```

This script will:
- Show current branch status
- Warn if on a feature branch (exit code 1)
- Provide merge instructions if needed
- Show uncommitted changes

### Merge Checklist

Before merging to host branch:
- [ ] `nix flake check` passes (or at least dry-run build)
- [ ] No syntax errors in .nix files
- [ ] New modules are imported in default.nix
- [ ] Documentation updated if adding features

### Current Host Branches

| Branch | Machine | nixpkgs |
|--------|---------|---------|
| `host/desktop` | Primary workstation | unstable |
| `host/laptop` | Portable machine | stable |
| `host/server` | Home server | stable |

## Active Technologies

- Nix (NixOS flake configuration) + nixpkgs (stable for server/laptop, unstable for desktop), GNOME 45+ (001-gnome-suite-packages)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Nix (NixOS flake configuration)

## Code Style

Nix (NixOS flake configuration): Follow standard conventions

## Recent Changes
- 001-gnome-suite-packages: Added [if applicable, e.g., PostgreSQL, CoreData, files or N/A]

- 001-gnome-suite-packages: Added Nix (NixOS flake configuration) + nixpkgs (stable for server/laptop, unstable for desktop), GNOME 45+

<!-- MANUAL ADDITIONS START -->

## ESP32-CAM Hardware Workflow

AI agents working with ESP32/Arduino projects should use the scripts in `dotfiles/dot_config/esp-scripts/`.

### Setup (One-time)

```bash
# Copy scripts to your PlatformIO project
cp -r ~/.config/esp-scripts ./scripts
cp ~/.config/esp-scripts/Makefile.template ./Makefile
```

### Flash Firmware (Primary Workflow)

```bash
# Detect device and flash
./scripts/flash

# Or with make
make flash-monitor
```

### Available Scripts

| Script | Purpose | JSON Output |
|--------|---------|-------------|
| `device-list` | Detect ESP32 devices | `--json` |
| `pio-env` | Resolve PlatformIO settings | `--json` |
| `flash` | Upload firmware with reset | N/A |
| `reset` | Reset board from bootloader | N/A |
| `monitor` | Serial monitor with logging | N/A |
| `serial-snapshot` | Time-limited serial capture | N/A |

### Exit Codes

All scripts use standardized exit codes:
- `0` - Success
- `1` - User-fixable error (permissions, bootloader mode)
- `2` - Environment error (missing tools, no port)
- `3` - Hardware error (upload failed)

### Common Issues & Fixes

| Issue | Command to Diagnose | Fix |
|-------|---------------------|-----|
| Port not found | `./scripts/device-list` | Check USB cable |
| Permission denied | `groups \| grep dialout` | Enable `modules.hardware.espDevices.enable = true;`, rebuild, logout/login |
| Upload hangs | Board stuck | Hold BOOT, tap RESET, release BOOT, then flash |
| No serial output | Board in download mode | Run `./scripts/reset` or press RESET button |

### Agent-Friendly Patterns

```bash
# Get recommended port as plain text
PORT=$(./scripts/device-list --first)

# Get full device info as JSON
./scripts/device-list --json

# Flash with timeout for verification
./scripts/flash && MONITOR_SECONDS=5 ./scripts/serial-snapshot --quiet

# Check if boot was successful (exit code 0 = boot detected)
./scripts/serial-snapshot --seconds 5 --quiet && echo "Boot OK"
```

### NixOS Module

Enable ESP device support in your host configuration:

```nix
modules.hardware.espDevices = {
  enable = true;
  # Optional: stable symlinks for multiple devices
  stableSymlinks = [
    { vendor = "10c4"; product = "ea60"; symlink = "esp32cam"; }
  ];
};
```

<!-- MANUAL ADDITIONS END -->
