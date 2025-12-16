# Shader Cache Module - RADV GPL and Shader Compilation Optimization
# Part of 003-gaming-optimization (Phase 3: User Story 1 - Shader Compilation)
#
# Enables:
# - RADV Graphics Pipeline Library (GPL) for compile-time shader processing
# - Next-Gen Geometry Culling (NGGC) for AMD GPUs
# - Steam shader pre-caching integration
# - Persistent shader cache across NixOS rebuilds
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gaming.shaderCache;
in {
  options.modules.gaming.shaderCache = with lib; {
    enable = mkEnableOption "shader compilation optimization with RADV GPL";

    enableRADVGPL = mkOption {
      type = types.bool;
      default = true;
      description = "Enable RADV Graphics Pipeline Library (GPL) for compile-time shader processing";
    };

    enableNGGC = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Next-Gen Geometry Culling (NGGC) for AMD GPUs";
    };

    enableSteamPreCache = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Steam's built-in Vulkan shader pre-caching";
    };

    additionalRADVFeatures = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["rt" "nir"];
      description = "Additional RADV_PERFTEST features to enable (comma-separated)";
    };

    cacheLocation = mkOption {
      type = types.str;
      default = "$HOME/.cache/mesa_shader_cache";
      readOnly = true;
      description = "Location of RADV shader cache (read-only, determined by Mesa)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Set RADV_PERFTEST environment variable for shader optimization
    environment.sessionVariables = let
      radvFeatures =
        lib.optional cfg.enableRADVGPL "gpl"
        ++ lib.optional cfg.enableNGGC "nggc"
        ++ cfg.additionalRADVFeatures;

      radvPerfTest = lib.concatStringsSep "," radvFeatures;
    in
      lib.mkIf (radvPerfTest != "") {
        RADV_PERFTEST = radvPerfTest;
      };

    # Steam shader pre-caching is enabled by default in Steam settings
    # Users can verify: Steam → Settings → Shader Pre-Caching → "Allow background processing of Vulkan shaders"
    # This option just ensures the environment is configured correctly
    environment.etc."profile.d/steam-shader-cache.sh" = lib.mkIf cfg.enableSteamPreCache {
      text = ''
        # Steam shader pre-caching environment
        # Ensures Steam can properly cache shaders
        export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0
      '';
    };

    # Shader cache persists across NixOS rebuilds because it's in ~/.cache/
    # No special configuration needed - Mesa handles this automatically
  };
}
