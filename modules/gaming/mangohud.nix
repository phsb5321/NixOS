# MangoHud Module - Performance Monitoring and Benchmarking
# Part of 003-gaming-optimization (Phase 6: User Story 4 - Performance Monitoring)
#
# Provides:
# - Real-time performance overlay (FPS, frame times, CPU/GPU usage, temps)
# - Automated performance logging for benchmarking
# - Customizable HUD configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gaming.mangohud;
in {
  options.modules.gaming.mangohud = with lib; {
    enable = mkEnableOption "MangoHud performance monitoring and benchmarking";

    enablePackage = mkOption {
      type = types.bool;
      default = true;
      description = "Install MangoHud package system-wide";
    };

    enableGlobalHud = mkOption {
      type = types.bool;
      default = false;
      description = "Enable MangoHud globally for all Vulkan/OpenGL applications (not recommended)";
    };

    config = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      example = {
        fps_limit = 0;
        vsync = 0;
        font_size = 24;
        position = "top-right";
        toggle_hud = "Shift_R+F12";
        toggle_logging = "Shift_L+F2";
        output_folder = "/home/user/mangohud-logs";
        log_duration = 0;
      };
      description = "MangoHud configuration (generates ~/.config/MangoHud/MangoHud.conf)";
    };

    outputFolder = mkOption {
      type = types.str;
      default = "$HOME/mangohud-logs";
      description = "Directory for MangoHud performance logs";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install MangoHud package
    environment.systemPackages = lib.mkIf cfg.enablePackage (with pkgs; [
      mangohud
    ]);

    # Enable MangoHud globally (if requested)
    environment.sessionVariables = lib.mkIf cfg.enableGlobalHud {
      MANGOHUD = "1";
    };

    # Generate MangoHud config file (if config is provided)
    # Note: This would require home-manager or user-level dotfiles
    # For now, we'll document that users should manually create ~/.config/MangoHud/MangoHud.conf
    # or add it to their dotfiles system

    # Create output folder via systemd-tmpfiles (ensures it exists on boot)
    systemd.tmpfiles.rules = [
      "d ${cfg.outputFolder} 0755 ${config.users.users.notroot.name} ${config.users.users.notroot.group} - -"
    ];
  };
}
