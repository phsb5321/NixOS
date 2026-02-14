# ESP32 Hardware Development Workflow

This guide covers ESP32/Arduino development on NixOS using PlatformIO with AI-agent-friendly scripts.

## Prerequisites

1. **Enable ESP device support** in your NixOS host configuration:

```nix
# In your host configuration (e.g., hosts/desktop/configuration.nix)
modules.hardware.espDevices.enable = true;
```

2. **Rebuild and re-login**:

```bash
sudo nixos-rebuild switch --flake .#desktop
# Log out and back in for dialout group membership
```

3. **Verify group membership**:

```bash
groups | grep dialout
# Should show: dialout
```

## Quick Start

### Enter Development Shell

```bash
cd ~/my-esp-project
nix-shell ~/NixOS/shells/ESP.nix
```

### Setup Project Scripts (First Time)

```bash
# Copy AI-friendly scripts to your project
cp -r ~/.config/esp-scripts ./scripts
cp ~/.config/esp-scripts/Makefile.template ./Makefile
```

### Flash and Monitor

```bash
# One command to flash and verify
make flash-monitor

# Or step by step:
./scripts/device-list          # Check device detected
./scripts/flash                # Upload firmware
./scripts/monitor --timeout 10 # View serial output
```

## Scripts Reference

### device-list

Detect connected ESP32 devices and recommend the best port.

```bash
# Human-readable output
./scripts/device-list

# JSON output (for parsing)
./scripts/device-list --json

# Just the port path
./scripts/device-list --first

# Filter by description
./scripts/device-list --filter CP210
```

**Exit codes:**
- `0` - Device(s) found
- `1` - No devices found
- `2` - PlatformIO not available

### pio-env

Resolve PlatformIO environment settings.

```bash
# Shell-sourceable output
./scripts/pio-env

# JSON output
./scripts/pio-env --json

# Specific environment
./scripts/pio-env --env esp32cam-release
```

**Exit codes:**
- `0` - Success
- `1` - platformio.ini not found
- `2` - Environment not found
- `3` - No devices for auto-detection

### flash

Build and upload firmware with automatic port detection.

```bash
# Auto-detect everything
./scripts/flash

# Specify environment
./scripts/flash --env esp32cam

# Specify port
./scripts/flash --port /dev/ttyUSB0

# Skip post-upload reset
./scripts/flash --no-reset

# Verbose output
./scripts/flash --verbose
```

**Exit codes:**
- `0` - Upload successful
- `1` - User-fixable error (permissions, bootloader mode needed)
- `2` - Environment error (no port, PlatformIO error)
- `3` - Hardware error (upload failed)

### reset

Reset the ESP32 out of bootloader/download mode.

```bash
# Default: DTR/RTS toggle
./scripts/reset

# Use esptool
./scripts/reset --method esptool

# Prompt for manual button press
./scripts/reset --method manual

# Skip boot verification
./scripts/reset --no-verify
```

**Exit codes:**
- `0` - Reset successful, boot detected
- `1` - Reset failed, manual action needed
- `2` - Port not found

### monitor

Serial monitor with file logging.

```bash
# Interactive (Ctrl+C to stop)
./scripts/monitor

# With timeout (for automation)
./scripts/monitor --timeout 30

# Custom baud rate
./scripts/monitor --baud 9600

# Disable logging
./scripts/monitor --no-log
```

**Environment variables:**
- `MONITOR_SECONDS` - Timeout in seconds
- `MONITOR_PORT` - Override port
- `BAUD_RATE` - Override baud rate

### serial-snapshot

Time-limited serial capture for boot verification.

```bash
# 5-second capture (default)
./scripts/serial-snapshot

# 10-second capture
./scripts/serial-snapshot --seconds 10

# Quiet mode (no header, just output)
./scripts/serial-snapshot --quiet
```

**Exit codes:**
- `0` - Boot output detected (contains `rst:` or `boot:`)
- `1` - No boot output (may be stuck in download mode)
- `2` - Port error

## Makefile Targets

If you copied `Makefile.template` to your project:

```bash
make help          # Show all targets
make device        # List devices
make flash         # Build and upload
make monitor       # Start serial monitor
make flash-monitor # Flash then verify boot
make reset         # Reset the board
make snapshot      # 10-second serial capture
make clean-logs    # Remove logs older than 7 days
```

## Troubleshooting

### Port Not Found

```bash
# Check USB connection
lsusb | grep -i serial

# List detected devices
./scripts/device-list

# Check if device shows in system
ls -la /dev/ttyUSB* /dev/ttyACM*
```

**Common causes:**
- USB cable is data-only (no data lines)
- Wrong USB port
- Device not powered

### Permission Denied

```bash
# Check group membership
groups | grep dialout

# If missing, ensure NixOS module is enabled:
# modules.hardware.espDevices.enable = true;

# After rebuild, you must logout/login
# Quick test without logout:
newgrp dialout
```

### Upload Hangs at "Connecting..."

The board needs to be in bootloader mode:

1. **Hold** the **BOOT** button (IO0)
2. **Tap** the **RESET** button
3. **Release** BOOT
4. Run `./scripts/flash` within 5 seconds

Some boards (ESP32-CAM-MB) do this automatically via DTR/RTS.

### No Serial Output After Flash

The board may be stuck in download mode:

```bash
# Try software reset
./scripts/reset

# Or press the physical RESET button

# Verify boot output
./scripts/serial-snapshot --seconds 5
```

### Wrong Baud Rate / Garbage Output

```bash
# ESP32 default is 115200
./scripts/monitor --baud 115200

# Some bootloaders use 74880
./scripts/monitor --baud 74880
```

### "Resource Busy" Error

Another process is using the port:

```bash
# Find the process
lsof /dev/ttyUSB0

# Kill it or close the application
# Common culprits: screen, minicom, another monitor
```

## Board-Specific Notes

### ESP32-CAM (AI-Thinker)

- Uses CH340 USB-serial chip
- Requires external USB-TTL adapter (unless using ESP32-CAM-MB)
- GPIO0 must be grounded for bootloader mode

### ESP32-CAM-MB (with programmer board)

- Integrated CH340 with auto-reset circuit
- Usually works with just `./scripts/flash`
- May occasionally need manual bootloader mode

### ESP32-S3/C3/C6 (Native USB)

- Uses built-in USB-OTG
- VID:PID is 303a:xxxx
- May appear as /dev/ttyACM0 instead of /dev/ttyUSB0

## Environment Variables

| Variable | Description |
|----------|-------------|
| `UPLOAD_PORT` | Override serial port |
| `MONITOR_PORT` | Override monitor port |
| `PIO_ENV` | Override PlatformIO environment |
| `BAUD_RATE` | Override baud rate |
| `MONITOR_SECONDS` | Monitor timeout |
| `ESP_RESET_METHOD` | Reset method: `dtr`, `esptool`, `manual` |
| `ESP_LOG_DIR` | Log directory (default: `./logs`) |

## NixOS Module Options

```nix
modules.hardware.espDevices = {
  # Enable ESP device support (required)
  enable = true;
  
  # Install udev rules (default: true)
  enableUdev = true;
  
  # Disable ModemManager entirely (usually not needed)
  disableModemManager = false;
  
  # Create stable device symlinks
  stableSymlinks = [
    { vendor = "10c4"; product = "ea60"; symlink = "esp32cam"; }
    { vendor = "1a86"; product = "7523"; serial = "ABC123"; symlink = "esp32dev"; }
  ];
  
  # Add extra users to dialout group
  extraUsers = ["developer"];
};
```

## Supported USB-Serial Chips

| Chip | VID:PID | Common On |
|------|---------|-----------|
| CP2102 | 10c4:ea60 | NodeMCU, TTGO |
| CH340 | 1a86:7523 | ESP32-CAM-MB, clones |
| CH9102 | 1a86:55d4 | Newer CH340 variant |
| FT232R | 0403:6001 | Quality USB-TTL adapters |
| FT232H | 0403:6014 | High-speed variant |
| ESP32-S2 | 303a:1001 | Native USB |
| ESP32-S3 | 303a:1002 | Native USB |
| ESP32-C3 | 303a:80d1 | Native USB |
| PL2303 | 067b:2303 | Older adapters |

## See Also

- [PlatformIO Documentation](https://docs.platformio.org/)
- [ESP-IDF Programming Guide](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [esptool Documentation](https://docs.espressif.com/projects/esptool/)
