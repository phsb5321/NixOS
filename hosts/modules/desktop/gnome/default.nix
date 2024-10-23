{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  config = mkIf (cfg.enable && cfg.environment == "gnome") {
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };

    services.xserver.displayManager.gdm.autoLogin = mkIf cfg.autoLogin.enable {
      enable = true;
      user = cfg.autoLogin.user;
    };
  };
}
