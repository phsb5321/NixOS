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

    # Use PipeWire for audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # PulseAudio compatibility
      jack.enable = true; # JACK compatibility
      wireplumber.enable = true;
    };

    # Explicitly disable PulseAudio to avoid conflicts
    services.pulseaudio.enable = lib.mkForce false;

    # Enhanced Bluetooth integration with PipeWire
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;

    networking.networkmanager.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      # Ensure xdg-desktop-portal-wlr is available for screen sharing
      wlr.enable = mkDefault true;
    };

    services.dbus.enable = true;
    security.polkit.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
  };
}
