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
    services.xserver.displayManager.gdm = {
      enable = true;
      wayland = false; # Force X11 mode for stability
    };
    services.xserver.desktopManager.gnome.enable = true;
    services.displayManager.defaultSession = "gnome-xorg"; # Use X11 session

    # Auto-login configuration
    services.displayManager.autoLogin = mkIf cfg.autoLogin.enable {
      enable = true;
      user = cfg.autoLogin.user;
    };

    # GNOME-specific services
    services.gnome = {
      gnome-keyring.enable = true;
      core-shell.enable = true;
      core-utilities.enable = true;
      gnome-settings-daemon.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      tinysparql.enable = true; # Renamed from tracker.enable
      localsearch.enable = true; # Renamed from tracker-miners.enable
    };

    # Additional services needed by GNOME
    services.geoclue2.enable = true;
    services.dbus = {
      enable = true;
      packages = with pkgs; [
        dconf
        gnome-settings-daemon
      ];
    };

    # Add udev rules for GNOME
    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    # GNOME-specific packages
    environment.systemPackages = with pkgs; [
      # Core GNOME packages - updated with top-level packages
      gnome-tweaks
      gnome-shell-extensions
      adwaita-icon-theme
      dconf-editor
      gnome-backgrounds
      gnome-themes-extra
      gnome-extension-manager

      # Missing dependencies identified in logs
      ibus
      libdbusmenu-gtk3
      libappindicator
      libappindicator-gtk3
      libsoup
      glib
      dconf

      # Extensions from the configuration
      gnomeExtensions.dash-to-dock
      gnomeExtensions.clipboard-indicator
      gnomeExtensions.sound-output-device-chooser
      gnomeExtensions.gsconnect
      gnomeExtensions.blur-my-shell
      gnomeExtensions.caffeine
      gnomeExtensions.forge
      gnomeExtensions.user-themes
    ];

    # Configure XDG portal specifically for GNOME
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-gnome
      ];
      config = {
        gnome = {
          default = ["gtk"];
          "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
        };
      };
    };

    # Fontconfig fix for the error in logs
    fonts.fontconfig = {
      enable = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Your font configurations -->
        </fontconfig>
      '';
    };

    # GNOME settings overrides
    services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      gtk-theme='Adwaita-dark'
      icon-theme='Adwaita'
      cursor-theme='Adwaita'
      font-name='Cantarell 11'
      monospace-font-name='JetBrainsMono Nerd Font Mono 11'

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

    # Enable DConf settings
    programs.dconf.enable = true;
  };
}
