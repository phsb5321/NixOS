# ~/NixOS/modules/hardware/laptop/options.nix
#
# Module: Laptop Hardware Options
# Purpose: Declares all laptop-specific hardware configuration options
# Part of: 001-module-optimization (T035-T039 - hardware/laptop.nix split)
{lib, ...}: {
  options.modules.hardware.laptop = {
    enable = lib.mkEnableOption "laptop-specific hardware support";

    batteryManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable battery management tools and optimizations";
      };

      chargeThreshold = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        example = 80;
        description = "Battery charge threshold percentage (if supported)";
      };
    };

    powerManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable power management optimizations";
      };

      profile = lib.mkOption {
        type = lib.types.enum ["powersave" "balanced" "performance"];
        default = "balanced";
        description = "Default power profile";
      };

      autoSuspend = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic suspend on lid close";
      };

      suspendTimeout = lib.mkOption {
        type = lib.types.int;
        default = 900; # 15 minutes
        description = "Suspend timeout in seconds";
      };
    };

    display = {
      autoRotate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic display rotation for convertibles";
      };

      brightnessControl = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable brightness control";
      };

      nightLight = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable night light (blue light filter)";
      };
    };

    touchpad = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable touchpad support";
      };

      naturalScrolling = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable natural scrolling";
      };

      tapToClick = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable tap to click";
      };

      disableWhileTyping = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Disable touchpad while typing";
      };
    };

    graphics = {
      hybridGraphics = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable hybrid Intel/NVIDIA graphics support";
      };

      intelBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:0:2:0";
        description = "Intel GPU bus ID";
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.str;
        default = "PCI:1:0:0";
        description = "NVIDIA GPU bus ID";
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages for laptop hardware support";
    };
  };
}
