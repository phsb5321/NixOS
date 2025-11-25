# ~/NixOS/modules/gpu/nvidia.nix
# NVIDIA GPU module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gpu.nvidia;
in {
  options.modules.gpu.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU configuration";

    package = lib.mkOption {
      type = lib.types.enum ["stable" "beta" "production" "legacy_470" "legacy_390"];
      default = "stable";
      description = "NVIDIA driver package version to use";
    };

    openDriver = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use open-source NVIDIA kernel modules (for RTX 2000+ series)";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA power management (useful for laptops)";
    };

    modesetting = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable kernel modesetting (required for Wayland)";
    };
  };

  config = lib.mkIf cfg.enable {
    # NVIDIA driver configuration
    services.xserver.videoDrivers = ["nvidia"];

    hardware.nvidia = {
      # Modesetting for Wayland support
      modesetting.enable = cfg.modesetting;

      # Power management
      powerManagement = {
        enable = cfg.powerManagement;
        finegrained = false; # Only enable if using hybrid graphics
      };

      # Driver package selection
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.package};

      # Open-source kernel modules (RTX 2000+ only)
      open = cfg.openDriver;

      # Settings app
      nvidiaSettings = true;
    };

    # Graphics hardware
    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs; [
        libva
        libva-utils
        vulkan-tools
        vulkan-validation-layers
      ];
    };

    # Environment variables
    environment.variables = {
      LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
      GBM_BACKEND = lib.mkDefault "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = lib.mkDefault "nvidia";
      # Wayland support
      WLR_NO_HARDWARE_CURSORS = lib.mkDefault "1";
    };

    # GPU tools
    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia # NVIDIA GPU monitoring
      vulkan-tools
      mesa-demos
    ];

    # Ensure video/render groups exist
    users.groups.video = {};
    users.groups.render = {};
  };
}
