# ~/NixOS/modules/hardware/amd.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.hardware.amd;
in {
  options.modules.hardware.amd = {
    enable = mkEnableOption "AMD GPU support with advanced VRAM management";

    # GPU Configuration
    gpu = {
      driver = mkOption {
        type = types.enum [
          "amdgpu"
          "radeon"
        ];
        default = "amdgpu";
        description = "AMD GPU driver to use";
      };

      enableOpenCL = mkOption {
        type = types.bool;
        default = true;
        description = "Enable OpenCL support for compute workloads";
      };

      enableROCm = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ROCm platform for compute workloads";
      };

      enableVulkan = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Vulkan support";
      };
    };

    # VRAM Management Configuration
    vram = {
      # Performance Profile
      profile = mkOption {
        type = types.enum [
          "minimal"
          "balanced"
          "performance"
          "extreme"
          "custom"
        ];
        default = "balanced";
        description = "VRAM optimization profile";
      };

      # Memory Management
      vmFragmentSize = mkOption {
        type = types.int;
        default = 9;
        description = "VM fragment size (4-12, larger = better for big allocations)";
      };

      vmBlockSize = mkOption {
        type = types.int;
        default = 9;
        description = "VM block size (4-12, optimized memory block sizes)";
      };

      enableLargePages = mkOption {
        type = types.bool;
        default = true;
        description = "Enable large pages for VRAM access";
      };

      gttSize = mkOption {
        type = types.int;
        default = 16384;
        description = "Graphics Translation Table size in MB";
      };

      vramLimit = mkOption {
        type = types.int;
        default = 0;
        description = "VRAM limit in MB (0 = unlimited)";
      };

      # Advanced Memory Settings
      lockupTimeout = mkOption {
        type = types.int;
        default = 10000;
        description = "GPU lockup timeout in milliseconds for large VRAM operations";
      };

      enableMemoryRetry = mkOption {
        type = types.bool;
        default = true;
        description = "Enable memory retry for stability";
      };

      # Huge Pages Configuration
      hugePages = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable huge pages for better VRAM performance";
        };

        size = mkOption {
          type = types.str;
          default = "2M";
          description = "Huge page size";
        };

        count = mkOption {
          type = types.int;
          default = 2048;
          description = "Number of huge pages to allocate";
        };
      };
    };

    # Performance Optimization
    performance = {
      # Power Management
      powerProfile = mkOption {
        type = types.enum [
          "auto"
          "low"
          "high"
          "manual"
        ];
        default = "auto";
        description = "GPU power profile for sustained VRAM performance";
      };

      # Memory Bandwidth Optimization
      enableMemoryBandwidthOptimization = mkOption {
        type = types.bool;
        default = true;
        description = "Enable memory bandwidth DPM";
      };

      # PCIe Configuration
      pcie = {
        generation = mkOption {
          type = types.int;
          default = 0;
          description = "Force PCIe generation (0 = auto)";
        };

        lanes = mkOption {
          type = types.int;
          default = 0;
          description = "Force PCIe lanes (0 = auto)";
        };

        disableASPM = mkOption {
          type = types.bool;
          default = true;
          description = "Disable PCIe ASPM for maximum performance";
        };
      };

      # Thermal Management
      thermal = {
        enableThrottling = mkOption {
          type = types.bool;
          default = true;
          description = "Enable thermal throttling";
        };

        enableFanControl = mkOption {
          type = types.bool;
          default = true;
          description = "Enable fan control";
        };
      };
    };

    # Environment Optimizations
    environment = {
      # AMD Debug Options
      amdDebug = mkOption {
        type = types.str;
        default = "nodma,nodmacopy";
        description = "AMD debug flags for DMA optimization";
      };

      # RADV Debug Options
      radvDebug = mkOption {
        type = types.str;
        default = "zerovram";
        description = "RADV debug flags for VRAM initialization";
      };

      # Mesa Configuration
      mesa = {
        glslCacheSize = mkOption {
          type = types.str;
          default = "2G";
          description = "Mesa GLSL cache size";
        };

        diskCacheSize = mkOption {
          type = types.str;
          default = "4G";
          description = "Mesa disk cache size";
        };

        memoryTypes = mkOption {
          type = types.str;
          default = "device,host";
          description = "Vulkan memory types optimization";
        };
      };

      # Gaming Optimizations
      gaming = {
        enableDXVKHUD = mkOption {
          type = types.bool;
          default = true;
          description = "Enable DXVK HUD for VRAM monitoring";
        };

        dxvkHudElements = mkOption {
          type = types.str;
          default = "memory,gpuload,fps,frametime";
          description = "DXVK HUD elements to display";
        };

        enableLargeAddressAware = mkOption {
          type = types.bool;
          default = true;
          description = "Enable large address awareness for Wine";
        };
      };

      # ROCm Configuration
      rocm = {
        gfxVersion = mkOption {
          type = types.str;
          default = "10.3.0";
          description = "HSA GFX version override for compute compatibility";
        };

        enablePreVega = mkOption {
          type = types.bool;
          default = true;
          description = "Enable pre-Vega ROCm support";
        };
      };
    };

    # Monitoring and Debugging
    monitoring = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable advanced VRAM monitoring tools";
      };

      tools = mkOption {
        type = types.listOf types.str;
        default = [
          "radeontop"
          "nvtop"
        ];
        description = "VRAM monitoring tools to install";
      };

      enableProfiling = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPU profiling tools for development";
      };

      enableBenchmarking = mkOption {
        type = types.bool;
        default = false;
        description = "Enable GPU benchmarking tools";
      };
    };

    # System Integration
    system = {
      # Memory Management
      swappiness = mkOption {
        type = types.int;
        default = 1;
        description = "VM swappiness for VRAM-intensive workloads";
      };

      vfsCachePressure = mkOption {
        type = types.int;
        default = 50;
        description = "VFS cache pressure optimization";
      };

      dirtyRatio = mkOption {
        type = types.int;
        default = 3;
        description = "Dirty page ratio for memory management";
      };

      # Shared Memory Configuration
      shmmax = mkOption {
        type = types.int;
        default = 68719476736; # 64GB
        description = "Maximum shared memory segment size";
      };

      shmall = mkOption {
        type = types.int;
        default = 4294967296;
        description = "Total pages of shared memory";
      };

      # Enable optimization services
      enableOptimizationService = mkOption {
        type = types.bool;
        default = true;
        description = "Enable systemd service for runtime GPU optimization";
      };
    };

    # Development Support
    development = {
      enableCMake = mkOption {
        type = types.bool;
        default = false;
        description = "Enable CMake with GPU development support";
      };

      enableCUDACompat = mkOption {
        type = types.bool;
        default = false;
        description = "Enable CUDA compatibility through HIP";
      };

      enableMLFrameworks = mkOption {
        type = types.bool;
        default = false;
        description = "Enable ML frameworks with AMD GPU support";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure unfree packages are allowed for some monitoring tools
    nixpkgs.config.allowUnfree = true;

    # Profile-based configuration
    modules.hardware.amd = mkMerge [
      # Minimal profile
      (mkIf (cfg.vram.profile == "minimal") {
        vram.vmFragmentSize = mkDefault 6;
        vram.vmBlockSize = mkDefault 6;
        vram.gttSize = mkDefault 4096;
        vram.hugePages.count = mkDefault 512;
        performance.powerProfile = mkDefault "low";
        monitoring.enableProfiling = mkDefault false;
        monitoring.enableBenchmarking = mkDefault false;
      })

      # Performance profile
      (mkIf (cfg.vram.profile == "performance") {
        vram.vmFragmentSize = mkDefault 10;
        vram.vmBlockSize = mkDefault 10;
        vram.gttSize = mkDefault 32768;
        vram.hugePages.count = mkDefault 4096;
        performance.powerProfile = mkDefault "high";
        monitoring.enableProfiling = mkDefault true;
      })

      # Extreme profile
      (mkIf (cfg.vram.profile == "extreme") {
        vram.vmFragmentSize = mkDefault 12;
        vram.vmBlockSize = mkDefault 12;
        vram.gttSize = mkDefault 65536;
        vram.hugePages.count = mkDefault 8192;
        performance.powerProfile = mkDefault "high";
        monitoring.enableProfiling = mkDefault true;
        monitoring.enableBenchmarking = mkDefault true;
        development.enableMLFrameworks = mkDefault true;
      })
    ];

    # Enable graphics support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs;
        [
          # AMD drivers and support
          mesa
          libva-vdpau-driver
          libvdpau-va-gl
        ]
        ++ optionals cfg.gpu.enableVulkan [
          amdvlk
          vulkan-tools
          vulkan-loader
          vulkan-validation-layers
          vulkan-caps-viewer
        ]
        ++ optionals cfg.gpu.enableOpenCL [
          clinfo
        ]
        ++ optionals cfg.gpu.enableROCm [
          rocmPackages.clr.icd
          rocmPackages.rocm-runtime
          rocmPackages.rocminfo
        ];

      extraPackages32 = with pkgs.driversi686Linux;
        [
          mesa
          libva-vdpau-driver
          libvdpau-va-gl
        ]
        ++ optionals cfg.gpu.enableVulkan [
          amdvlk
        ];
    };

    # Video drivers
    services.xserver.videoDrivers = [cfg.gpu.driver];

    # Boot configuration
    boot = {
      # Early kernel module loading
      initrd.kernelModules = [cfg.gpu.driver];

      # Kernel parameters
      kernelParams =
        [
          # Basic AMD GPU parameters
          "${cfg.gpu.driver}.ppfeaturemask=0xffffffff"
          "${cfg.gpu.driver}.si_support=1"
          "${cfg.gpu.driver}.cik_support=1"
          "${cfg.gpu.driver}.audio=1"
          "${cfg.gpu.driver}.dc=1"
          "${cfg.gpu.driver}.dpm=1"

          # VRAM optimization parameters
          "${cfg.gpu.driver}.vm_fragment_size=${toString cfg.vram.vmFragmentSize}"
          "${cfg.gpu.driver}.vm_block_size=${toString cfg.vram.vmBlockSize}"
          "${cfg.gpu.driver}.large_page_enable=${
            if cfg.vram.enableLargePages
            then "1"
            else "0"
          }"
          "${cfg.gpu.driver}.noretry=${
            if cfg.vram.enableMemoryRetry
            then "0"
            else "1"
          }"
          "${cfg.gpu.driver}.lockup_timeout=${toString cfg.vram.lockupTimeout}"

          # PCIe optimizations
        ]
        ++ optionals cfg.performance.pcie.disableASPM [
          "pcie_aspm=off"
          "pci=realloc,assign-busses"
          "iommu=pt"
        ]
        ++ optionals cfg.vram.hugePages.enable [
          "hugepagesz=${cfg.vram.hugePages.size}"
          "hugepages=${toString cfg.vram.hugePages.count}"
          "transparent_hugepage=madvise"
        ];

      # Kernel sysctl parameters
      kernel.sysctl = {
        # Virtual memory optimizations
        "vm.swappiness" = mkDefault cfg.system.swappiness;
        "vm.vfs_cache_pressure" = mkDefault cfg.system.vfsCachePressure;
        "vm.dirty_ratio" = mkDefault cfg.system.dirtyRatio;
        "vm.dirty_background_ratio" = mkDefault 1;

        # Shared memory configuration
        "kernel.shmmax" = mkDefault cfg.system.shmmax;
        "kernel.shmall" = mkDefault cfg.system.shmall;

        # Network optimizations for high-bandwidth transfers
        "net.core.rmem_max" = mkDefault 134217728;
        "net.core.wmem_max" = mkDefault 134217728;
      };
    };

    # Modprobe configuration
    environment.etc."modprobe.d/amd-gpu.conf".text = ''
      # Enable all AMD GPU features
      options ${cfg.gpu.driver} ppfeaturemask=0xffffffff

      # VRAM optimizations
      options ${cfg.gpu.driver} vm_fragment_size=${toString cfg.vram.vmFragmentSize}
      options ${cfg.gpu.driver} vm_block_size=${toString cfg.vram.vmBlockSize}
      options ${cfg.gpu.driver} large_page_enable=${
        if cfg.vram.enableLargePages
        then "1"
        else "0"
      }
      options ${cfg.gpu.driver} noretry=${
        if cfg.vram.enableMemoryRetry
        then "0"
        else "1"
      }
      options ${cfg.gpu.driver} gpu_recovery=1

      # Memory and bandwidth optimizations
      options ${cfg.gpu.driver} mem_bw_dpm=${
        if cfg.performance.enableMemoryBandwidthOptimization
        then "1"
        else "0"
      }
      ${
        optionalString (cfg.performance.pcie.generation > 0)
        "options ${cfg.gpu.driver} pcie_gen_cap=0x${toString (cfg.performance.pcie.generation * 16)}"
      }
      ${
        optionalString (cfg.performance.pcie.lanes > 0)
        "options ${cfg.gpu.driver} pcie_lane_cap=0x${toString (cfg.performance.pcie.lanes * 4096)}"
      }

      # Thermal management
      options ${cfg.gpu.driver} thermal_throttling=${
        if cfg.performance.thermal.enableThrottling
        then "1"
        else "0"
      }
      options ${cfg.gpu.driver} fan_ctrl=${
        if cfg.performance.thermal.enableFanControl
        then "1"
        else "0"
      }

      # Advanced options
      options ${cfg.gpu.driver} gtt_size=${toString cfg.vram.gttSize}
      options ${cfg.gpu.driver} vram_limit=${toString cfg.vram.vramLimit}
      options ${cfg.gpu.driver} exp_hw_support=1
    '';

    # Environment variables
    environment.sessionVariables = {
      # AMD-specific optimizations
      AMD_VULKAN_ICD = mkIf cfg.gpu.enableVulkan "RADV";
      VK_ICD_FILENAMES = mkIf cfg.gpu.enableVulkan "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json";
      VDPAU_DRIVER = "radeonsi";
      RADV_PERFTEST = "gpl,nggc,sam,ext_ms";

      # VRAM and memory optimizations
      AMD_DEBUG = cfg.environment.amdDebug;
      RADV_DEBUG = cfg.environment.radvDebug;
      MESA_VK_MEMORY_TYPES = cfg.environment.mesa.memoryTypes;
      MESA_GLSL_CACHE_MAX_SIZE = cfg.environment.mesa.glslCacheSize;
      MESA_DISK_CACHE_MAX_SIZE = cfg.environment.mesa.diskCacheSize;
      GALLIUM_DRIVER = "radeonsi";

      # ROCm environment
      HSA_OVERRIDE_GFX_VERSION = mkIf cfg.gpu.enableROCm cfg.environment.rocm.gfxVersion;
      ROC_ENABLE_PRE_VEGA = mkIf (cfg.gpu.enableROCm && cfg.environment.rocm.enablePreVega) "1";

      # Gaming optimizations
      DXVK_HUD = mkIf cfg.environment.gaming.enableDXVKHUD cfg.environment.gaming.dxvkHudElements;
      WINE_LARGE_ADDRESS_AWARE = mkIf cfg.environment.gaming.enableLargeAddressAware "1";
      __GL_THREADED_OPTIMIZATIONS = "1";
    };

    # Install monitoring and development packages
    environment.systemPackages = with pkgs; (
      # Core GPU utilities
      [
        libva-utils
        vdpauinfo
        glxinfo
        ffmpeg-full
        mesa-demos
      ]
      # Monitoring tools
      ++ optionals cfg.monitoring.enable (
        (builtins.filter (x: x != null) (
          map (
            tool:
              if tool == "nvtop"
              then pkgs.nvtopPackages.amd
              else pkgs.${tool} or null
          )
          cfg.monitoring.tools
        ))
        ++ [
          lact # AMD GPU control
        ]
      )
      # Profiling tools
      ++ optionals cfg.monitoring.enableProfiling [
        renderdoc
      ]
      # Benchmarking tools
      ++ optionals cfg.monitoring.enableBenchmarking [
        glmark2
      ]
      # Development tools
      ++ optionals cfg.development.enableCMake [
        cmake
        pkg-config
      ]
      # ROCm packages
      ++ optionals cfg.gpu.enableROCm [
        rocmPackages.clr.icd
        rocmPackages.rocm-runtime
        rocmPackages.rocminfo
      ]
    );

    # LACT configuration for AMD GPU control
    environment.etc."lact/config.yaml".text = ''
      daemon:
        log_level: warn
        admin_groups:
          - wheel
    '';

    # systemd optimization service
    systemd.user.services.amd-gpu-optimization = mkIf cfg.system.enableOptimizationService {
      description = "AMD GPU and VRAM Optimization Service";
      wantedBy = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "amd-gpu-optimize" ''
          # Set GPU power profile
          ${optionalString (cfg.performance.powerProfile == "high") ''
            echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
          ''}
          ${optionalString (cfg.performance.powerProfile == "low") ''
            echo low > /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
          ''}

          # Optimize GPU scheduling for VRAM-intensive tasks
          echo 1 > /sys/class/drm/card0/device/pp_power_profile_mode 2>/dev/null || true

          # Set memory frequency to high if performance mode
          ${optionalString (cfg.performance.powerProfile == "high") ''
            echo 1 > /sys/class/drm/card0/device/pp_mclk_od 2>/dev/null || true
          ''}
        ''}";
      };
    };

    # systemd tmpfiles rules for GPU optimization
    systemd.tmpfiles.rules =
      [
        # Huge pages configuration
        "w /sys/kernel/mm/hugepages/hugepages-${cfg.vram.hugePages.size}/nr_hugepages - - - - ${toString cfg.vram.hugePages.count}"
      ]
      ++ optionals (cfg.performance.powerProfile != "auto") [
        # GPU power management
        "w /sys/class/drm/card0/device/power_dpm_force_performance_level - - - - ${cfg.performance.powerProfile}"
      ];

    # udev rules for AMD GPU
    services.udev.extraRules = ''
      # AMD GPU power management
      SUBSYSTEM=="drm", KERNEL=="card0", ATTR{device/vendor}=="0x1002", ATTR{device/power/control}="auto"

      # Enable user access to GPU performance controls
      SUBSYSTEM=="drm", KERNEL=="card0", ATTR{device/vendor}=="0x1002", RUN+="${pkgs.coreutils}/bin/chmod 666 %S%p/device/pp_*"
    '';

    # Security configuration for GPU control
    security.sudo.extraRules = [
      {
        groups = ["wheel"];
        commands = [
          {
            command = "${pkgs.lact}/bin/lact";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    # Development framework support (empty for now, packages added above)
    # ML frameworks would be added here when available with ROCm support

    # Assertions for configuration validation
    assertions = [
      {
        assertion = cfg.vram.vmFragmentSize >= 4 && cfg.vram.vmFragmentSize <= 12;
        message = "VRAM VM fragment size must be between 4 and 12";
      }
      {
        assertion = cfg.vram.vmBlockSize >= 4 && cfg.vram.vmBlockSize <= 12;
        message = "VRAM VM block size must be between 4 and 12";
      }
      {
        assertion = cfg.vram.gttSize >= 256;
        message = "GTT size must be at least 256 MB";
      }
      {
        assertion = !(cfg.gpu.enableROCm && cfg.gpu.driver == "radeon");
        message = "ROCm requires amdgpu driver, not radeon";
      }
    ];

    # Warnings for suboptimal configurations
    warnings =
      optional (
        cfg.vram.profile == "extreme" && cfg.vram.hugePages.count < 4096
      ) "Extreme VRAM profile with less than 4096 huge pages may not provide optimal performance"
      ++ optional (
        cfg.performance.pcie.disableASPM && cfg.performance.powerProfile == "low"
      ) "Disabling PCIe ASPM with low power profile may conflict"
      ++ optional (
        cfg.development.enableMLFrameworks && !cfg.gpu.enableROCm
      ) "ML frameworks work best with ROCm enabled";
  };
}
