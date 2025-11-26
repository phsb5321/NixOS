# ~/NixOS/modules/gpu/amd.nix
# AMD GPU abstraction module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gpu.amd;
in {
  options.modules.gpu.amd = {
    enable = lib.mkEnableOption "AMD GPU configuration";

    model = lib.mkOption {
      type = lib.types.enum ["navi10" "navi21" "navi22" "navi23" "navi24" "rdna3" "other"];
      default = "navi10";
      description = "AMD GPU model for specific optimizations (RX 5700 XT = navi10)";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable advanced power management";
    };

    gaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable gaming optimizations (32-bit support, performance tweaks)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Early KMS for faster boot and better Wayland
    boot.initrd.kernelModules = ["amdgpu"];

    # AMD GPU kernel parameters
    boot.kernelParams =
      [
        "amdgpu.dc=1" # Display Core (required for Wayland)
        "amdgpu.dpm=1" # Dynamic Power Management
        "amdgpu.gpu_recovery=1" # GPU hang recovery
      ]
      ++ lib.optionals cfg.powerManagement [
        "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features
      ];

    # Graphics hardware
    hardware.graphics = {
      enable = true;
      enable32Bit = cfg.gaming;

      extraPackages = with pkgs; [
        libva
        libva-utils
        vulkan-tools
        vulkan-validation-layers
        mesa
        # RADV is enabled by default, amdvlk has been deprecated
      ];

      extraPackages32 = lib.optionals cfg.gaming (with pkgs.driversi686Linux; [
        mesa
        # RADV is enabled by default, amdvlk has been deprecated
      ]);
    };

    # Video driver configuration
    services.xserver.videoDrivers = ["amdgpu"];

    # Udev rules for GPU access
    services.udev.extraRules = ''
      # AMD GPU device permissions
      SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
      SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
    '';

    # Environment variables
    environment.variables = {
      VDPAU_DRIVER = lib.mkDefault "radeonsi";
      LIBVA_DRIVER_NAME = lib.mkDefault "radeonsi";
      AMD_VULKAN_ICD = lib.mkDefault "RADV";
    };

    # GPU monitoring and testing tools
    environment.systemPackages = with pkgs; [
      radeontop
      vulkan-tools
      mesa-demos
      clinfo # OpenCL info
    ];

    # Ensure video/render groups exist
    users.groups.video = {};
    users.groups.render = {};
  };
}
