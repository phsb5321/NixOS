# modules/desktop/coordinator.nix
# This file coordinates between different desktop environments to avoid conflicts
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  config = mkIf cfg.enable {
    # Configure display managers based on the chosen environment
    services.displayManager = {
      # Set default session based on the desktop environment
      defaultSession =
        if cfg.environment == "gnome"
        then "gnome"
        else if cfg.environment == "kde"
        then "plasma"
        else if cfg.environment == "hyprland"
        then "hyprland"
        else "gnome";
    };

    # Safety measures to ensure desktop environments don't conflict
    assertions = [
      {
        assertion =
          (cfg.environment == "gnome" -> !config.services.xserver.desktopManager.plasma5.enable)
          && (cfg.environment == "kde" -> !config.services.xserver.desktopManager.gnome.enable);
        message = "You cannot enable multiple desktop environments simultaneously.";
      }
    ];
  };
}
