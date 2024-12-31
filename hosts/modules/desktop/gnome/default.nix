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
    # Enable X server and GNOME desktop environment
    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Auto-login configuration
    services.displayManager.autoLogin = mkIf cfg.autoLogin.enable {
      enable = true;
      user = cfg.autoLogin.user;
    };

    # Set default session to GNOME
    services.displayManager.defaultSession = "gnome";

    # Enable Wayland support in GDM
    services.xserver.displayManager.gdm.wayland = true;

    # Exclude default gnome-shell to allow user themes
    environment.gnome.excludePackages = [pkgs.gnome-shell];

    # Additional GNOME packages and extensions
    environment.systemPackages = with pkgs; [
      gnome-shell
      gnome-shell-extensions
      gnome-tweaks
      gnomeExtensions.dash-to-dock
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      networkmanager
      wpa_supplicant
      linux-firmware
    ];

    # Enable GNOME Keyring services
    services.gnome.gnome-keyring.enable = true;
    security.pam.services = {
      gdm.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    # GNOME settings overrides as a string
    services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      gtk-theme='Adwaita-dark'
      icon-theme='Papirus-Dark'
      cursor-theme='Adwaita'
      font-name='Cantarell 11'
      monospace-font-name='Fira Code 11'

      [org.gnome.desktop.wm.preferences]
      button-layout='appmenu:minimize,maximize,close'

      [org.gnome.desktop.peripherals.touchpad]
      tap-to-click=true
      natural-scroll=true
    '';

    # Enable Flatpak support
    services.flatpak.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.freedesktop.Flatpak.app-install" ||
             action.id == "org.freedesktop.Flatpak.app-remove") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Power management settings
    services.upower = {
      enable = true;
      percentageLow = 15;
      percentageCritical = 5;
      percentageAction = 3;
    };

    # Configure NetworkManager
    networking.networkmanager = {
      enable = true;
      wifi.backend = "wpa_supplicant";
    };

    # Include firmware
    hardware.enableAllFirmware = true;

    # Enable Bluetooth support
    hardware.bluetooth.enable = true;

    # Enable DConf settings
    programs.dconf.enable = true;
  };
}
