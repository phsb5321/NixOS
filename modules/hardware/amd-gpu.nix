# AMD GPU Configuration for RX 5700 XT (Navi 10)
# Optimized for GNOME 48 + Wayland + NixOS 25.11
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.hardware.amdgpu;
in {
  options.modules.hardware.amdgpu = with lib; {
    enable = mkEnableOption "AMD GPU configuration and optimization";

    model = mkOption {
      type = types.enum ["navi10" "navi21" "navi22" "navi23" "navi24" "rdna3" "other"];
      default = "navi10";
      description = "AMD GPU model for specific optimizations";
    };

    powerManagement = mkOption {
      type = types.bool;
      default = true;
      description = "Enable advanced power management";
    };
  };

  config = lib.mkIf cfg.enable {
    # AMD GPU kernel configuration
    boot = {
      # Early KMS for faster boot and better Wayland integration
      initrd.kernelModules = [ "amdgpu" ];

      # Kernel parameters optimized for AMD RX 5700 XT
      kernelParams = [
        "amdgpu.dc=1"           # Display Core (required for Wayland)
        "amdgpu.dpm=1"          # Dynamic Power Management
        "amdgpu.gpu_recovery=1" # GPU hang recovery
      ];
    };

    # Graphics configuration
    hardware.graphics = {
      enable = true;

      # AMD graphics packages
      extraPackages = with pkgs; [
        libva
        libva-utils
        vulkan-tools
        vulkan-validation-layers
        mesa
      ];

      # 32-bit support
      extraPackages32 = with pkgs.driversi686Linux; [
        mesa
      ];
    };

    # Services configuration
    services = {
      # AMD GPU driver
      xserver.videoDrivers = [ "amdgpu" ];

      # Udev rules for GPU access
      udev.extraRules = ''
        # AMD GPU device permissions
        SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
        SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
      '';
    };

    # Environment variables for AMD GPU
    environment = {
      variables = {
        # Video acceleration drivers - use mkDefault to allow laptop to override for NVIDIA
        "VDPAU_DRIVER" = lib.mkDefault "radeonsi";
        "LIBVA_DRIVER_NAME" = lib.mkDefault "radeonsi";

        # Vulkan driver
        "AMD_VULKAN_ICD" = lib.mkDefault "RADV";
      };

      # Useful AMD GPU tools
      systemPackages = with pkgs; [
        radeontop     # GPU monitoring
        vulkan-tools  # Vulkan utilities
        mesa-demos    # OpenGL testing
      ];
    };

    # User groups for GPU access
    users.groups = {
      video = {};
      render = {};
    };

    users.users.notroot = {
      extraGroups = [ "video" "render" ];
    };
  };
}