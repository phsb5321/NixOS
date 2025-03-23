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

    # Explicitly disable PipeWire to avoid conflicts with PulseAudio
    services.pipewire.enable = lib.mkForce false;

    # Use PulseAudio instead of PipeWire for improved codec support
    # Define PulseAudio settings but allow overrides from host configuration
    services.pulseaudio = {
      enable = lib.mkForce true;
      # Remove package definition here to avoid conflicts
    };

    # Enhanced Bluetooth integration
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

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
