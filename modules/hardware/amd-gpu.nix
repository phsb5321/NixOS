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

    # Gaming optimizations
    gaming = {
      enable = mkEnableOption "gaming optimizations for AMD GPU";

      nggCulling = mkOption {
        type = types.bool;
        default = true;
        description = "Enable NGG culling (RADV_PERFTEST=nggc) for 3-5% performance gain";
      };

      anisotropicFiltering = mkOption {
        type = types.enum [0 2 4 8 16];
        default = 16;
        description = "Anisotropic filtering level for RADV (0 = disabled, 16 = maximum quality)";
      };

      lact.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable LACT for GPU monitoring and undervolting";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # AMD GPU kernel configuration
    boot = {
      # Early KMS for faster boot and better Wayland integration
      initrd.kernelModules = ["amdgpu"];

      # Kernel parameters optimized for AMD RX 5700 XT
      kernelParams =
        [
          "amdgpu.dc=1" # Display Core (required for Wayland)
          "amdgpu.dpm=1" # Dynamic Power Management
          "amdgpu.gpu_recovery=1" # GPU hang recovery
        ]
        ++ lib.optionals cfg.gaming.enable [
          "amdgpu.ppfeaturemask=0xffffffff" # Enable all power features (required for LACT undervolting)
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
        rocmPackages.clr.icd # Better OpenCL support
      ];

      # 32-bit support
      extraPackages32 = with pkgs.driversi686Linux; [
        mesa
      ];
    };

    # Services configuration
    services = {
      # AMD GPU driver
      xserver.videoDrivers = ["amdgpu"];

      # Udev rules for GPU access
      udev.extraRules = ''
        # AMD GPU device permissions
        SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
        SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"
      '';
    };

    # Environment variables for AMD GPU
    environment = {
      variables =
        {
          # Video acceleration drivers - use mkDefault to allow laptop to override for NVIDIA
          "VDPAU_DRIVER" = lib.mkDefault "radeonsi";
          "LIBVA_DRIVER_NAME" = lib.mkDefault "radeonsi";

          # Vulkan driver
          "AMD_VULKAN_ICD" = lib.mkDefault "RADV";

          # RADV performance optimizations (base)
          "RADV_PERFTEST" = lib.mkDefault "gpl${lib.optionalString cfg.gaming.nggCulling ",nggc"}";
          "RADV_DEBUG" = lib.mkDefault "zerovram"; # Reduce VRAM usage
        }
        // lib.optionalAttrs (cfg.gaming.enable && cfg.gaming.anisotropicFiltering > 0) {
          # Anisotropic filtering for gaming
          "RADV_TEX_ANISO" = toString cfg.gaming.anisotropicFiltering;
        };

      # Useful AMD GPU tools
      systemPackages = with pkgs;
        [
          radeontop # GPU monitoring
          vulkan-tools # Vulkan utilities
          mesa-demos # OpenGL testing
        ]
        ++ lib.optionals cfg.gaming.lact.enable [
          lact # GPU monitoring and undervolting GUI
        ];
    };

    # LACT service for GPU monitoring/undervolting
    systemd.services.lact = lib.mkIf cfg.gaming.lact.enable {
      enable = true;
      description = "AMDGPU Control Daemon";
      after = ["multi-user.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.lact}/bin/lact daemon";
        Nice = -10;
        Restart = "on-failure";
      };
    };

    # User groups for GPU access
    users.groups = {
      video = {};
      render = {};
    };

    users.users.notroot = {
      extraGroups = ["video" "render"];
    };
  };
}
