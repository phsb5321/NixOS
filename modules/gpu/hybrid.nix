# ~/NixOS/modules/gpu/hybrid.nix
# Hybrid GPU module (NVIDIA + Intel switching)
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.gpu.hybrid;
in {
  options.modules.gpu.hybrid = {
    enable = lib.mkEnableOption "hybrid GPU configuration (NVIDIA + Intel)";

    primaryGpu = lib.mkOption {
      type = lib.types.enum ["nvidia" "intel"];
      default = "intel";
      description = "Primary GPU to use by default";
    };

    offloadMode = lib.mkOption {
      type = lib.types.enum ["offload" "sync" "reverse-prime"];
      default = "offload";
      description = "GPU switching mode (offload = on-demand, sync = always both, reverse-prime = NVIDIA primary)";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable power management to turn off NVIDIA GPU when not in use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable both Intel and NVIDIA modules
    modules.gpu.intel.enable = true;
    modules.gpu.nvidia.enable = true;

    # NVIDIA Prime configuration for hybrid graphics
    hardware.nvidia = {
      prime = {
        # Offload mode - NVIDIA GPU used on-demand
        offload = lib.mkIf (cfg.offloadMode == "offload") {
          enable = true;
          enableOffloadCmd = true;  # Provides nvidia-offload command
        };

        # Sync mode - Both GPUs always active
        sync.enable = lib.mkIf (cfg.offloadMode == "sync") true;

        # Reverse PRIME - NVIDIA as primary
        reverseSync.enable = lib.mkIf (cfg.offloadMode == "reverse-prime") true;

        # Note: Bus IDs need to be configured per-machine in host config
        # Find with: lspci | grep -E 'VGA|3D'
        # Example:
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:1:0:0";
      };

      # Power management for battery life
      powerManagement = lib.mkIf cfg.powerManagement {
        enable = true;
        finegrained = (cfg.offloadMode == "offload");
      };
    };

    # Helper script for NVIDIA offload
    environment.systemPackages = lib.optionals (cfg.offloadMode == "offload") [
      (pkgs.writeShellScriptBin "nvidia-offload" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '')
    ];

    # Environment variables based on primary GPU
    environment.variables = lib.mkMerge [
      (lib.mkIf (cfg.primaryGpu == "intel") {
        # Use Intel by default
        LIBVA_DRIVER_NAME = lib.mkDefault "iHD";
      })
      (lib.mkIf (cfg.primaryGpu == "nvidia") {
        # Use NVIDIA by default
        LIBVA_DRIVER_NAME = lib.mkDefault "nvidia";
      })
    ];
  };
}
