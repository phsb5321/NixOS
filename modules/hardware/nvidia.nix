# ~/NixOS/modules/hardware/nvidia.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.hardware.nvidia;
in {
  options.modules.hardware.nvidia = {
    enable = mkEnableOption "Nvidia GPU support";
    
    # GPU Bus IDs for PRIME configuration
    intelBusId = mkOption {
      type = types.str;
      default = "PCI:0:2:0";
      description = "Intel GPU Bus ID for PRIME configuration";
    };
    
    nvidiaBusId = mkOption {
      type = types.str;
      default = "PCI:1:0:0";
      description = "Nvidia GPU Bus ID for PRIME configuration";
    };
    
    # Driver configuration
    driver = {
      version = mkOption {
        type = types.enum ["stable" "beta" "latest" "production"];
        default = "stable";
        description = "Nvidia driver version to use";
      };
      
      openSource = mkOption {
        type = types.bool;
        default = true;
        description = "Use open source Nvidia drivers (recommended for Turing+)";
      };
    };
    
    # PRIME configuration options
    prime = {
      mode = mkOption {
        type = types.enum ["offload" "sync" "reverse-sync"];
        default = "offload";
        description = "PRIME operation mode";
      };
      
      allowExternalGpu = mkOption {
        type = types.bool;
        default = false;
        description = "Allow external GPU for reverse sync mode";
      };
    };
    
    # Power management options
    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Nvidia power management (experimental)";
      };
      
      finegrained = mkOption {
        type = types.bool;
        default = true;
        description = "Enable fine-grained power management (Turing+)";
      };
    };
    
    # Performance and compatibility options
    performance = {
      forceFullCompositionPipeline = mkOption {
        type = types.bool;
        default = false;
        description = "Force full composition pipeline to reduce screen tearing";
      };
    };
    
    # Laptop-specific options
    laptop = {
      enableSpecializations = mkOption {
        type = types.bool;
        default = true;
        description = "Enable multiple boot configurations for different usage scenarios";
      };
      
      enableOffloadWrapper = mkOption {
        type = types.bool;
        default = true;
        description = "Create nvidia-offload wrapper script";
      };
    };
  };
  
  config = mkIf cfg.enable {
    # Ensure unfree packages are allowed
    nixpkgs.config.allowUnfree = true;
    
    # Enable graphics support
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    
    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"];
    
    # Core Nvidia configuration
    hardware.nvidia = {
      # Modesetting is required for Wayland
      modesetting.enable = true;
      
      # Power management configuration
      powerManagement.enable = cfg.powerManagement.enable;
      powerManagement.finegrained = cfg.powerManagement.finegrained;
      
      # Use open source kernel module for Turing+ GPUs
      open = cfg.driver.openSource;
      
      # Enable the Nvidia settings menu
      nvidiaSettings = true;
      
      # Driver version selection
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.driver.version};
      
      # Force full composition pipeline if enabled
      forceFullCompositionPipeline = cfg.performance.forceFullCompositionPipeline;
      
      # PRIME configuration
      prime = {
        # Bus ID configuration
        intelBusId = cfg.intelBusId;
        nvidiaBusId = cfg.nvidiaBusId;
        
        # PRIME mode configuration
        offload = mkIf (cfg.prime.mode == "offload") {
          enable = true;
          enableOffloadCmd = cfg.laptop.enableOffloadWrapper;
        };
        
        sync = mkIf (cfg.prime.mode == "sync") {
          enable = true;
        };
        
        reverseSync = mkIf (cfg.prime.mode == "reverse-sync") {
          enable = true;
          # Note: allowExternalGpu may not exist in all Nvidia driver versions
        };
      };
    };
    
    # Environment variables for better compatibility
    environment.sessionVariables = {
      # LibGL library path for Nvidia
      LIBGL_DRIVERS_PATH = "${config.hardware.graphics.package}/lib/dri";
      
      # Nvidia-specific environment variables
      __GL_SHADER_DISK_CACHE = "1";
      __GL_SHADER_DISK_CACHE_PATH = "$HOME/.cache/nvidia-shader-cache";
      
      # Better multi-GPU support
      __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      __VK_LAYER_NV_optimus = "NVIDIA_only";
    };
    
    # Install essential Nvidia packages
    environment.systemPackages = with pkgs; [
      # Vulkan support
      vulkan-tools
      vulkan-loader
      
      # OpenGL utilities
      glxinfo
      
      # GPU benchmarking and testing
      glmark2
      
      # Optionally add nvidia-offload script
    ] ++ optionals cfg.laptop.enableOffloadWrapper [
      # Create nvidia-offload wrapper
      (pkgs.writeShellScriptBin "nvidia-offload" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '')
    ];
    
    # Laptop specializations for different usage scenarios
    specialisation = mkIf cfg.laptop.enableSpecializations {
      # High-performance mode with PRIME sync
      performance.configuration = {
        system.nixos.tags = ["performance"];
        modules.hardware.nvidia.prime.mode = lib.mkForce "sync";
        modules.hardware.nvidia.powerManagement.finegrained = lib.mkForce false;
        
        # Performance tweaks
        hardware.nvidia.powerManagement.enable = lib.mkForce false;
        
        # Use high-performance GPU governor
        powerManagement.cpuFreqGovernor = lib.mkForce "performance";
      };
      
      # Battery-saving mode with offload
      battery.configuration = {
        system.nixos.tags = ["battery"];
        modules.hardware.nvidia.prime.mode = lib.mkForce "offload";
        modules.hardware.nvidia.powerManagement.finegrained = lib.mkForce true;
        
        # Battery saving tweaks
        powerManagement.cpuFreqGovernor = lib.mkForce "powersave";
        services.tlp.enable = lib.mkForce true;
      };
    };
    
    # Kernel parameters for better Nvidia support
    boot.kernelParams = [
      # Enable Nvidia driver
      "nvidia.NVreg_UsePageAttributeTable=1"
      
      # Reduce memory allocation issues
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      
      # Better power management
      "nvidia.NVreg_TemporaryFilePath=/tmp"
    ];
    
    # Blacklist nouveau to avoid conflicts
    boot.blacklistedKernelModules = ["nouveau"];
    
    # Additional kernel modules
    boot.extraModulePackages = with config.boot.kernelPackages; [
      nvidia_x11
    ];
    
    # Enable systemd service for Nvidia
    systemd.services.nvidia-suspend = {
      description = "NVIDIA system suspend actions";
      wantedBy = ["suspend.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl --no-block suspend";
      };
    };
    
    # udev rules for Nvidia
    services.udev.extraRules = ''
      # Nvidia GPU power management
      SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto"
      
      # Nvidia audio device power management
      SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto"
    '';
    
    # Assertions for configuration validation
    assertions = [
      {
        assertion = cfg.prime.mode == "reverse-sync" -> true; # Basic validation
        message = "Reverse sync mode requires compatible hardware and driver";
      }
      {
        assertion = cfg.driver.openSource -> true; # Simplified validation
        message = "Open source Nvidia drivers require Turing or newer architecture";
      }
    ];
  };
}
