# GameMode Module - Automatic Gaming Process Priority and CPU Governor Management
# Part of 003-gaming-optimization (Phase 5: User Story 3 - CPU Optimization)
#
# GameMode automatically:
# - Switches CPU governor to 'performance' when games launch
# - Increases game process priority (renice)
# - Inhibits screensavers and power management
# - Reverts all changes when game exits
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gaming.gamemode;
in {
  options.modules.gaming.gamemode = with lib; {
    enable = mkEnableOption "GameMode automatic gaming optimization";

    enableRenice = mkOption {
      type = types.bool;
      default = true;
      description = "Enable process priority boost for games";
    };

    renice = mkOption {
      type = types.int;
      default = 10;
      description = "Nice value adjustment for game processes (-20 to 19, higher = more aggressive)";
    };

    softRealtime = mkOption {
      type = types.str;
      default = "auto";
      description = "Soft real-time scheduling mode (auto/on/off)";
    };

    inhibitScreensaver = mkOption {
      type = types.bool;
      default = true;
      description = "Inhibit screensaver during gaming";
    };

    gpuOptimizations = mkOption {
      type = types.bool;
      default = false;
      description = "Apply GPU performance optimizations (requires accept-responsibility)";
    };

    customStart = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.libnotify}/bin/notify-send 'GameMode activated'";
      description = "Custom command to run when GameMode starts";
    };

    customEnd = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.libnotify}/bin/notify-send 'GameMode deactivated'";
      description = "Custom command to run when GameMode ends";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable GameMode NixOS module
    programs.gamemode = {
      enable = true;
      inherit (cfg) enableRenice;

      settings = {
        general = {
          softrealtime = cfg.softRealtime;
          inherit (cfg) renice;
          inhibit_screensaver =
            if cfg.inhibitScreensaver
            then 1
            else 0;
        };

        gpu = lib.mkIf cfg.gpuOptimizations {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
        };

        custom = lib.mkIf (cfg.customStart != null || cfg.customEnd != null) {
          start = lib.mkIf (cfg.customStart != null) cfg.customStart;
          end = lib.mkIf (cfg.customEnd != null) cfg.customEnd;
        };
      };
    };

    # Ensure gamemode is available to all users
    environment.systemPackages = with pkgs; [
      gamemode
    ];
  };
}
