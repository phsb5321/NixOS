{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
in {
  config = mkMerge [
    # Base configuration when desktop module is enabled
    (mkIf (cfg.enable) {
      # Common configuration needed for all desktop environments
    })

    # GNOME-specific configuration
    (mkIf (cfg.enable && cfg.environment == "gnome") {
      # Enable X server and GNOME desktop environment with GDM
      services.xserver = {
        enable = true;
        desktopManager.gnome.enable = true;

        # Configure GDM as the display manager
        displayManager = {
          gdm = {
            enable = true;
            wayland = true;
          };
        };
      };

      # Auto-login configuration
      services.displayManager.autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };

      # Set default session
      services.displayManager.defaultSession = "gnome";

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
        # Core GNOME packages
        gnome-tweaks
        gnome-shell-extensions
        adwaita-icon-theme
        dconf-editor
        gnome-backgrounds
        gnome-themes-extra
        gnome-extension-manager

        # Python GTK bindings - fix for "No module named 'gi'" errors
        python3Packages.pygobject3
        python3Packages.pycairo
        gobject-introspection
        glib
        gtk3

        # Missing dependencies identified in logs
        ibus
        libdbusmenu-gtk3
        libappindicator
        libappindicator-gtk3
        libsoup_2_4 # Updated from libsoup
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

        # Themes
        material-cursors
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

        [org.gnome.desktop.screensaver]
        lock-enabled=true

        [org.gnome.desktop.lockdown]
        disable-lock-screen=false
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
    })
  ];
}
