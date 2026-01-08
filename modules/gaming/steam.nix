# Steam and Proton Gaming Configuration
# Provides Steam with GE-Proton support and gaming optimizations
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gaming.steam;
in {
  options.modules.gaming.steam = with lib; {
    # Enable Steam with Proton
    enable = mkEnableOption "Steam with Proton gaming support";

    # Enable protontricks tool
    protontricks.enable = mkOption {
      type = types.bool;
      default = cfg.enable;
      description = "Enable protontricks for Proton prefix management";
    };

    # Install GE-Proton
    geProton.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install GE-Proton custom compatibility tool";
    };

    # Additional Steam FHS packages
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages to include in Steam FHS environment";
    };

    # Remote Play support
    remotePlay.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall for Steam Remote Play";
    };

    # Gamescope session
    gamescopeSession.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Gamescope compositor session for Steam";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Steam with Proton
    programs.steam = {
      enable = true;

      # Remote Play firewall
      remotePlay.openFirewall = cfg.remotePlay.enable;

      # Dedicated server firewall (disabled by default)
      dedicatedServer.openFirewall = false;

      # Gamescope session
      gamescopeSession.enable = cfg.gamescopeSession.enable;

      # GE-Proton compatibility tool
      extraCompatPackages = lib.optionals cfg.geProton.enable [
        pkgs.proton-ge-bin
      ];
    };

    # Ensure 32-bit GPU drivers for Steam games
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Environment variables for Steam
    environment.sessionVariables = {
      # Enable heavy runtime for better compatibility
      STEAM_RUNTIME_HEAVY = "1";

      # MangoHud library paths for Steam FHS environment
      # This ensures MangoHud can be found by Proton games
      MANGOHUD_DLSYM = "1";
    };

    # Install protontricks if enabled
    environment.systemPackages =
      lib.optionals cfg.protontricks.enable [
        pkgs.protontricks
      ]
      ++ cfg.extraPackages;
  };
}
