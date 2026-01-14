# ESP32/Arduino USB-serial device support module
#
# Provides udev rules, dialout group membership, and optional stable symlinks
# for ESP32-CAM and similar microcontroller development boards.
#
# Usage in host configuration:
#   modules.hardware.espDevices.enable = true;
#
# Optional stable symlinks for multiple devices:
#   modules.hardware.espDevices.stableSymlinks = [
#     { vendor = "10c4"; product = "ea60"; symlink = "esp32cam"; }
#   ];
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.espDevices;

  # Official PlatformIO udev rules (fetched at build time)
  platformioUdevRules = pkgs.stdenv.mkDerivation {
    name = "platformio-udev-rules";
    src = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules";
      sha256 = "sha256-CfOs4g5GoNXeRUmkKY7Kw9KdgOqX5iRLMvmP+u3mqx8=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/lib/udev/rules.d
      cp $src $out/lib/udev/rules.d/99-platformio-udev.rules
    '';
  };

  # Common USB-serial chip rules
  # Sets permissions and tells ModemManager to ignore these devices
  baseUdevRules = ''
    # CP210x (Silicon Labs) - Common on TTGO, NodeMCU, etc.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # CH340/CH341 - Common on ESP32-CAM-MB, cheap NodeMCU clones
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # CH9102 - Newer CH340 variant
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # FTDI FT232 - Common on Arduino Uno, quality USB-TTL adapters
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # FTDI FT232H - High-speed variant
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # ESP32 native USB (S2, S3, C3, C6) - All Espressif native USB devices
    SUBSYSTEM=="tty", ATTRS{idVendor}=="303a", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"

    # Prolific PL2303 - Older USB-TTL adapters
    SUBSYSTEM=="tty", ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", \
      MODE="0666", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"
  '';

  # Generate symlink rules from config
  symlinkRules = lib.concatMapStrings (dev: ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="${dev.vendor}", ATTRS{idProduct}=="${dev.product}"${
      lib.optionalString (dev.serial != "") ", ATTRS{serial}==\"${dev.serial}\""
    }, SYMLINK+="${dev.symlink}", MODE="0666", GROUP="dialout"
  '') cfg.stableSymlinks;
in {
  options.modules.hardware.espDevices = {
    enable = lib.mkEnableOption "ESP32/Arduino USB-serial device support";

    enableUdev = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install udev rules for common USB-serial chips";
    };

    usePlatformioRules = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use official PlatformIO udev rules instead of the built-in rules.
        Covers more devices but requires network access during build.
        See: https://docs.platformio.org/en/latest/core/installation/udev-rules.html
      '';
    };

    disableModemManager = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Completely disable ModemManager service.
        Usually not needed since udev rules set ID_MM_DEVICE_IGNORE.
        Only enable if ModemManager still interferes with your devices.
      '';
    };

    stableSymlinks = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          vendor = lib.mkOption {
            type = lib.types.str;
            description = "USB Vendor ID (4 hex digits, lowercase)";
            example = "10c4";
          };
          product = lib.mkOption {
            type = lib.types.str;
            description = "USB Product ID (4 hex digits, lowercase)";
            example = "ea60";
          };
          serial = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "USB Serial number (optional, for unique device identification)";
          };
          symlink = lib.mkOption {
            type = lib.types.str;
            description = "Symlink name to create under /dev/ (e.g., 'esp32cam' creates /dev/esp32cam)";
            example = "esp32cam";
          };
        };
      });
      default = [];
      description = ''
        Create stable device symlinks for specific USB devices.
        Useful when you have multiple ESP devices and want predictable port names.
        Use `lsusb` to find VID:PID and `udevadm info /dev/ttyUSB0` for serial.
      '';
      example = lib.literalExpression ''
        [
          { vendor = "10c4"; product = "ea60"; symlink = "esp32cam"; }
          { vendor = "1a86"; product = "7523"; serial = "ABC123"; symlink = "esp32dev"; }
        ]
      '';
    };

    # Users to add to dialout group (in addition to primary user)
    extraUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional users to add to the dialout group";
      example = ["developer" "ci"];
    };
  };

  config = lib.mkIf cfg.enable {
    # Install udev rules - either official PlatformIO or built-in
    services.udev.packages = lib.mkIf (cfg.enableUdev && cfg.usePlatformioRules) [
      platformioUdevRules
    ];

    services.udev.extraRules = lib.mkIf cfg.enableUdev (
      lib.optionalString (!cfg.usePlatformioRules) ''
        # ESP32/Arduino USB-serial device rules
        # Generated by modules.hardware.espDevices
        ${baseUdevRules}
      ''
      + lib.optionalString (cfg.stableSymlinks != []) ''
        # Custom stable symlinks
        ${symlinkRules}
      ''
    );

    # Ensure dialout group exists
    users.groups.dialout = {};

    # Add primary user and any extra users to dialout group
    # Note: User must log out and back in for group membership to take effect
    users.users = lib.mkMerge (
      [
        # Primary user
        {notroot.extraGroups = lib.mkAfter ["dialout"];}
      ]
      ++ map (user: {
        ${user}.extraGroups = lib.mkAfter ["dialout"];
      }) cfg.extraUsers
    );

    # Disable ModemManager if requested
    systemd.services.ModemManager = lib.mkIf cfg.disableModemManager {
      enable = false;
      wantedBy = lib.mkForce [];
    };

    # Useful packages for ESP development diagnostics
    environment.systemPackages = with pkgs; [
      usbutils # lsusb for device identification
      picocom # Lightweight serial terminal
      python3Packages.pyserial # Python serial library (for reset script)
    ];
  };
}
