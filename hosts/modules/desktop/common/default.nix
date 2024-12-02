# hosts/modules/desktop/common/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  imports = [
    ./fonts.nix # Import the fonts module
  ];

  config = mkIf cfg.enable {
    services.xserver.xkb = {
      layout = "br";
      variant = "";
    };

    environment.systemPackages = cfg.extraPackages;

    services.printing.enable = true;

    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    networking.networkmanager.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    services.dbus.enable = true;
    security.polkit.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
