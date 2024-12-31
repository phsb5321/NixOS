{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.gaming;
in {
  options.modules.core.gaming = {
    # Enable option to turn the gaming module on or off
    enable = mkEnableOption "Gaming configuration module";

    # Option to enable Steam specifically
    enableSteam = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Steam installation and configuration";
    };

    # Option to include additional gaming-related packages
    extraGamingPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional gaming-related packages to install";
    };
  };

  config = mkIf cfg.enable {
    # Enable Steam if `enableSteam` is true
    programs.steam.enable = cfg.enableSteam;

    # Append gaming-related packages to `environment.systemPackages`
    environment.systemPackages = with pkgs;
      [
        lutris
        mangohud
        vkBasalt
        gamemode
        libstrangle
        vulkan-loader # Replaces libvulkan
        vulkan-validation-layers
        mesa-demos # Replaces mesa-utils
      ]
      ++ cfg.extraGamingPackages;

    # Set environment variables for gaming applications
    environment.variables = {
      STEAM_RUNTIME_HEAVY = "1"; # Use full runtime for compatibility
      ENABLE_VK_LAYER_MANGOHUD = "1"; # Enable MangoHud by default
      GAMEMODE_AUTO = "1"; # Enable GameMode automatically
    };

    # Start GameMode as a systemd service
    systemd.services.gamemoded = {
      enable = true;
      description = "GameMode Daemon";
      after = ["network.target"];
      serviceConfig.ExecStart = "${pkgs.gamemode}/bin/gamemoded";
    };
  };
}
