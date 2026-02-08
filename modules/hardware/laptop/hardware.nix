# ~/NixOS/modules/hardware/laptop/hardware.nix
#
# Module: Laptop Hardware Support
# Purpose: Touchpad, graphics, WiFi, brightness, firmware configuration
# Part of: 001-module-optimization (T035-T039 - hardware/laptop.nix split)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.laptop;
in {
  config = lib.mkIf cfg.enable {
    # Touchpad configuration
    services.libinput = lib.mkIf cfg.touchpad.enable {
      enable = true;
      touchpad = {
        inherit (cfg.touchpad) naturalScrolling;
        tapping = cfg.touchpad.tapToClick;
        inherit (cfg.touchpad) disableWhileTyping;
        scrollMethod = "twofinger";
        accelSpeed = "0";
      };
    };

    # Essential laptop packages
    environment.systemPackages = with pkgs;
      [
        # Power management
        powertop
        acpi

        # Display control
        brightnessctl
        xorg.xbacklight
        light

        # Battery monitoring
        acpitool

        # System monitoring
        lm_sensors
      ]
      ++ lib.optionals cfg.batteryManagement.enable [
        # Battery specific tools
        upower
      ]
      ++ cfg.extraPackages;

    # Hardware support
    hardware = {
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;

      # Graphics configuration
      graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Enable firmware updates and latest Intel WiFi firmware
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    # WiFi rfkill fix for Intel CNVi cards (8086:06f0)
    boot.kernelParams = [
      "rfkill.default_state=1" # Unblock WiFi by default
      "acpi_osi=Linux" # ACPI compatibility for WiFi
      "acpi_backlight=video" # Use video backlight interface
    ];

    # Module configuration for Intel hardware
    boot.extraModprobeConfig = ''
      # iwlmvm power scheme (1=active, 2=balanced, 3=low-power)
      options iwlmvm power_scheme=1

      # Intel graphics GuC submission
      options i915 enable_guc=2
    '';

    # Blacklist problematic modules that can cause rfkill issues
    boot.blacklistedKernelModules = [
      "ideapad_laptop" # Can cause rfkill issues on some laptops
    ];

    # Ensure latest Intel WiFi firmware is available
    hardware.firmware = with pkgs; [
      linux-firmware # Latest firmware
      wireless-regdb # WiFi regulatory database
    ];

    # Systemd services for laptop hardware
    systemd.services = lib.mkMerge [
      # WiFi unblock service
      {
        wifi-unblock = {
          description = "Aggressively unblock WiFi on boot";
          wantedBy = ["multi-user.target"];
          after = ["systemd-modules-load.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "wifi-unblock" ''
              # Multiple attempts to unblock WiFi
              ${pkgs.util-linux}/bin/rfkill unblock wifi
              ${pkgs.util-linux}/bin/rfkill unblock all

              # Try direct sysfs approach if available
              if [ -w /sys/class/rfkill/rfkill1/soft ]; then
                echo 0 > /sys/class/rfkill/rfkill1/soft
              fi

              # Reload iwlwifi module
              ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
              sleep 2
              ${pkgs.kmod}/bin/modprobe iwlwifi

              # Final unblock attempt
              ${pkgs.util-linux}/bin/rfkill unblock wifi
            '';
          };
        };
      }
      # NOTE: NVIDIA suspend/resume services are automatically provided by
      # hardware.nvidia.powerManagement.enable = true (set above)
      # No manual service configuration needed for nvidia-only mode
      # Backlight permissions service
      (lib.mkIf cfg.display.brightnessControl {
        backlight-permissions = {
          description = "Set backlight permissions";
          wantedBy = ["graphical.target"];
          after = ["systemd-backlight@backlight:intel_backlight.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "backlight-permissions" ''
              # Wait for backlight device
              sleep 2

              # Try to find any backlight device
              for device in /sys/class/backlight/*; do
                if [ -e "$device/brightness" ]; then
                  echo "Found backlight device: $device"
                  chmod 666 "$device/brightness" || true
                  chgrp video "$device/brightness" || true
                fi
              done

              # Load i915 module if not loaded
              if ! lsmod | grep -q "^i915 "; then
                ${pkgs.kmod}/bin/modprobe i915
                sleep 2
              fi

              # Check again after loading i915
              for device in /sys/class/backlight/*; do
                if [ -e "$device/brightness" ]; then
                  chmod 666 "$device/brightness" || true
                fi
              done
            '';
          };
        };
      })
    ];

    # NVIDIA configuration for hybrid laptops
    hardware.nvidia = lib.mkIf cfg.graphics.hybridGraphics {
      # Required for Wayland
      modesetting.enable = true;

      # Power management (critical for suspend/resume)
      powerManagement.enable = true;

      # Fine-grained power management only works with offload mode
      # In nvidia-only mode, GPU is always on
      powerManagement.finegrained = cfg.graphics.primeMode == "offload";

      # Use open kernel modules for Turing+ (GTX 16xx, RTX 20xx+)
      # GTX 1650 is Turing, so open = true is recommended
      open = true;

      nvidiaSettings = true;

      # Use production driver (stable)
      package = config.boot.kernelPackages.nvidiaPackages.production;

      # PRIME configuration - only for offload mode
      # nvidia-only mode doesn't use PRIME at all (NVIDIA renders everything natively)
      prime = lib.mkIf (cfg.graphics.primeMode == "offload") {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        inherit (cfg.graphics) intelBusId;
        inherit (cfg.graphics) nvidiaBusId;
      };
    };

    # Video drivers - NVIDIA only for nvidia-only mode
    services.xserver.videoDrivers = lib.mkIf cfg.graphics.hybridGraphics (
      if cfg.graphics.primeMode == "nvidia-only"
      then ["nvidia"]
      else ["modesetting" "nvidia"]
    );

    # Early KMS for nvidia-only mode (required for Wayland)
    boot.initrd.kernelModules = lib.mkIf (cfg.graphics.hybridGraphics && cfg.graphics.primeMode == "nvidia-only") [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
      "i915" # Intel still needed for display output (panel connection)
    ];

    # Environment variables for nvidia-only Wayland rendering
    environment.sessionVariables = lib.mkIf (cfg.graphics.hybridGraphics && cfg.graphics.primeMode == "nvidia-only") {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      # VA-API via Intel for video decode (more power efficient)
      LIBVA_DRIVER_NAME =
        if (builtins.elem cfg.graphics.intelGeneration ["tigerlake" "alderlake" "raptorlake" "icelake"])
        then "iHD"
        else "i965";
    };

    # Enable firmware updates
    services.fwupd.enable = true;

    # ACPI event handling
    services.acpid = {
      enable = true;
      handlers = {
        # Handle brightness keys if needed
        brightnessUp = lib.mkIf cfg.display.brightnessControl {
          event = "video/brightnessup";
          action = "${pkgs.brightnessctl}/bin/brightnessctl set +10%";
        };
        brightnessDown = lib.mkIf cfg.display.brightnessControl {
          event = "video/brightnessdown";
          action = "${pkgs.brightnessctl}/bin/brightnessctl set 10%-";
        };
      };
    };

    # Udev rules for brightness control permissions
    services.udev.extraRules = lib.mkIf cfg.display.brightnessControl ''
      # Allow users to control brightness
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="intel_backlight", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="acpi_video0", MODE="0666", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"

      # Grant video group access to backlight control
      SUBSYSTEM=="backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      SUBSYSTEM=="backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

      # Alternative approach for Intel graphics
      SUBSYSTEM=="drm", ACTION=="change", ENV{HOTPLUG}=="1", RUN+="${pkgs.systemd}/bin/systemctl --no-block start backlight-permissions.service"
    '';
  };
}
