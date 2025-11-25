# ~/NixOS/modules/gpu/intel.nix
# Intel integrated GPU module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gpu.intel;
in {
  options.modules.gpu.intel = {
    enable = lib.mkEnableOption "Intel integrated GPU configuration";

    generation = lib.mkOption {
      type = lib.types.enum ["haswell" "broadwell" "skylake" "kabylake" "coffeelake" "icelake" "tigerlake" "alderlake" "raptorlake"];
      default = "tigerlake";
      description = "Intel CPU/GPU generation for driver selection";
    };

    enableVaapiDriver = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable VA-API hardware video acceleration";
    };
  };

  config = lib.mkIf cfg.enable {
    # Intel GPU kernel module
    boot.initrd.kernelModules = ["i915"];

    # Intel GPU kernel parameters
    boot.kernelParams = [
      "i915.enable_guc=3" # Enable GuC and HuC firmware loading
    ];

    # Graphics hardware
    hardware.graphics = {
      enable = true;

      extraPackages = with pkgs; [
        # VA-API drivers (choose based on generation)
        (
          if (builtins.elem cfg.generation ["haswell" "broadwell" "skylake" "kabylake" "coffeelake"])
          then intel-media-driver # Newer driver for Gen 8+
          else intel-vaapi-driver
        ) # Legacy driver for older generations

        # Additional Intel packages
        libva
        libva-utils
        intel-media-driver # iHD driver for newer Intel
        intel-vaapi-driver # i965 driver for older Intel
        vulkan-tools
        vulkan-validation-layers
        mesa
      ];
    };

    # Video driver
    services.xserver.videoDrivers = ["intel"];

    # Environment variables
    environment.variables = {
      # Use newer iHD driver for recent generations, i965 for older
      LIBVA_DRIVER_NAME = lib.mkDefault (
        if (builtins.elem cfg.generation ["tigerlake" "alderlake" "raptorlake" "icelake"])
        then "iHD"
        else "i965"
      );
    };

    # GPU tools
    environment.systemPackages = with pkgs; [
      intel-gpu-tools
      vulkan-tools
      mesa-demos
    ];

    # Ensure video/render groups exist
    users.groups.video = {};
    users.groups.render = {};
  };
}
