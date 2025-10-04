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

    overdrive = mkOption {
      type = types.bool;
      default = false;
      description = "Enable GPU overclocking (OverDrive)";
    };

    powerManagement = mkOption {
      type = types.bool;
      default = true;
      description = "Enable advanced power management";
    };
  };

  config = lib.mkIf cfg.enable {
    # 2025 AMD GPU best practices for NixOS
    boot = {
      # Early KMS for faster boot and better Wayland integration
      initrd.kernelModules = [ "amdgpu" ];

      # Kernel parameters optimized for AMD RX 5700 XT / GNOME 48
      kernelParams = [
        # Enable all AMD GPU features
        "amdgpu.si_support=1"
        "amdgpu.cik_support=1"
        "amdgpu.dc=1"           # Display Core (required for Wayland)
        "amdgpu.dpm=1"          # Dynamic Power Management
        "amdgpu.ppfeaturemask=0xffffffff"  # Enable all PowerPlay features

        # Performance optimizations for Navi 10 (RX 5700 XT)
        "amdgpu.gpu_recovery=1" # GPU hang recovery
        "amdgpu.ras_enable=0"   # Disable RAS for performance (safe for desktop)
        "amdgpu.tmz=1"          # Enable Trusted Memory Zone
      ] ++ lib.optionals cfg.overdrive [
        "amdgpu.ppfeaturemask=0xffffffbf"  # Enable overclocking
      ];

      # Enable hardware optimizations
      kernel.sysctl = lib.mkIf cfg.powerManagement {
        # AMD GPU power management
        "kernel.sched_rt_runtime_us" = 980000;  # RT scheduler for GPU
        "vm.max_map_count" = 2147483642;        # For VRAM mapping
      };
    };

    # Graphics configuration optimized for 2025
    hardware = {
      graphics = {
        enable = true;

        # Mesa drivers with all AMD optimizations
        extraPackages = with pkgs; [
          # AMD hardware video acceleration
          libvdpau-va-gl
          vaapiVdpau

          # AMD Vulkan drivers (latest Mesa)
          amdvlk    # AMD official Vulkan driver

          # Additional acceleration libraries
          libva
          libva-utils
          vulkan-tools
          vulkan-validation-layers
        ];

        # 32-bit support for gaming/compatibility
        extraPackages32 = with pkgs.driversi686Linux; [
          libvdpau-va-gl
          vaapiVdpau
          amdvlk
        ];
      };

      # OpenGL configuration
      opengl = {
        driSupport = true;
        driSupport32Bit = true;

        # Mesa configuration for AMD
        extraPackages = with pkgs; [
          rocm-opencl-icd    # OpenCL support
          rocm-opencl-runtime
        ];
      };
    };

    # X11/Wayland driver configuration
    services.xserver = {
      # Use AMDGPU driver (not radeon)
      videoDrivers = [ "amdgpu" ];

      # Device configuration for RX 5700 XT
      deviceSection = lib.mkIf (cfg.model == "navi10") ''
        # RX 5700 XT optimizations
        Option "TearFree" "true"
        Option "ColorTiling" "on"
        Option "ColorTiling2D" "on"
        Option "DRI" "3"
        Option "EnablePageFlip" "on"
      '';
    };

    # Environment variables for optimal AMD GPU performance
    environment = {
      # GPU-specific variables
      variables = {
        # Force AMD GPU for applications
        "DRI_PRIME" = "1";

        # Video acceleration
        "VDPAU_DRIVER" = "radeonsi";
        "LIBVA_DRIVER_NAME" = "radeonsi";

        # Vulkan driver selection
        "VK_ICD_FILENAMES" = "/run/opengl-driver/share/vulkan/icd.d/amd_icd64.json";

        # OpenCL optimization
        "ROCR_VISIBLE_DEVICES" = "0";

        # Performance settings
        "RADV_PERFTEST" = "aco,llvm";
        "AMD_VULKAN_ICD" = "RADV";
      } // lib.optionalAttrs cfg.overdrive {
        # Overclocking support
        "AMDGPU_OVERDRIVE" = "1";
      };

      # System packages for AMD GPU management
      systemPackages = with pkgs; [
        # GPU monitoring and control
        radeontop         # AMD GPU usage monitor
        lm_sensors        # Temperature monitoring

        # ROCm tools for compute workloads
        rocm-smi         # AMD GPU system management

        # Graphics tools
        vulkan-tools     # Vulkan utilities
        mesa-demos       # OpenGL testing

        # Performance monitoring
        mangohud         # Gaming overlay
      ] ++ lib.optionals cfg.overdrive [
        corectrl         # GPU overclocking interface
      ];
    };

    # Power management optimizations
    powerManagement = lib.mkIf cfg.powerManagement {
      enable = true;

      # CPU governor for GPU workloads
      cpuFreqGovernor = lib.mkDefault "performance";

      # Power profiles
      powerProfiles = {
        performance = {
          cpuGovernor = "performance";
          scaling = "performance";
        };
        balanced = {
          cpuGovernor = "powersave";
          scaling = "powersave";
        };
      };
    };

    # Specialized gaming/performance services
    services = {
      # GameMode integration for performance
      gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
            softrealtime = "auto";
            inhibit_screensaver = 1;
          };

          gpu = lib.mkIf (cfg.model == "navi10") {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            amd_performance_level = "high";
          };
        };
      };
    } // lib.optionalAttrs cfg.overdrive {
      # CoreCtrl for overclocking (if enabled)
      corectrl = {
        enable = true;
        gpuOverclock = {
          enable = true;
          ppfeaturemask = "0xffffffff";
        };
      };
    };

    # Udev rules for GPU access
    services.udev.extraRules = ''
      # AMD GPU device permissions
      SUBSYSTEM=="drm", KERNEL=="card*", GROUP="video", MODE="0664"
      SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0664"

      # ROCm devices
      SUBSYSTEM=="kfd", KERNEL=="kfd", GROUP="render", MODE="0666"
    '' + lib.optionalString cfg.overdrive ''
      # Overclocking permissions
      KERNEL=="card*", SUBSYSTEM=="drm", DRIVERS=="amdgpu", TAG+="uaccess"
    '';

    # User groups for GPU access
    users.groups = {
      video = {};
      render = {};
    };

    # Add user to necessary groups
    users.users.notroot = {
      extraGroups = [ "video" "render" ] ++ lib.optionals cfg.overdrive [ "corectrl" ];
    };
  };
}