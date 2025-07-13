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
      variant = mkDefault ""; # Default to standard Brazilian ABNT (no variant)
    };

    environment.systemPackages = cfg.extraPackages;

    services.printing.enable = true;

    # Let specific desktop environments handle audio configuration
    # Removed PipeWire configuration to avoid conflicts with GNOME module

    # Enhanced Bluetooth integration
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    networking.networkmanager.enable = true;

    # XDG portals handled by specific DE modules to avoid conflicts
    # Removed xdg.portal configuration

    services.dbus.enable = true;
    security.polkit.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
