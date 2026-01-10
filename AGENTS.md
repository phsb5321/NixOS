# NixOS Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-01-09

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
