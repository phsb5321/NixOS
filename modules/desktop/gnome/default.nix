# ~/NixOS/modules/desktop/gnome/default.nix
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

    # GNOME-specific configuration for NixOS 25.05
    (mkIf (cfg.enable && cfg.environment == "gnome") {
      # Core GNOME desktop environment
      services.xserver = {
        enable = true; # Required for XWayland compatibility
        desktopManager.gnome.enable = true;
      };

      # Display manager with Wayland support
      services.gnome.core-shell.enable = true;
      services.gnome.core-os-services.enable = true;

      # Modern audio system optimized for Wayland
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
      };

      # Essential GNOME services (streamlined)
      services.gnome = {
        gnome-keyring.enable = true;
        gnome-settings-daemon.enable = true;
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        tinysparql.enable = true;
        localsearch.enable = true;
      };

      # Additional required services
      services.geoclue2.enable = true;

      # Essential system environment variables with graphics fixes
      environment.sessionVariables = {
        # Fix for GNOME rendering issues in NixOS 25.05
        GSK_RENDERER = "opengl";
        # Unified cursor configuration
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
        # Wayland optimization
        NIXOS_OZONE_WL = "1";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
      };

      # Streamlined package list - only essentials
      environment.systemPackages = with pkgs; [
        # Core GNOME tools
        gnome-tweaks
        gnome-extension-manager
        dconf-editor

        # Essential GNOME extensions
        gnomeExtensions.dash-to-dock
        gnomeExtensions.user-themes
        gnomeExtensions.caffeine

        # Unified cursor theme
        bibata-cursors

        # Essential dependencies
        libadwaita
        adw-gtk3
        gsettings-desktop-schemas
      ];

      # Remove unwanted GNOME packages
      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        epiphany
        geary
        evince
        gnome-music
        gnome-maps
        gnome-weather
        simple-scan
        totem
        cheese
        gnome-contacts
        gnome-calendar
      ];

      # Modern XDG portal configuration
      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gnome];
        config.gnome.default = ["gnome"];
      };

      # Minimal system-wide GNOME settings
      services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.interface]
        cursor-theme='Bibata-Modern-Classic'
        cursor-size=24
        color-scheme='prefer-dark'
        enable-hot-corners=false
        show-battery-percentage=true

        [org.gnome.desktop.wm.preferences]
        button-layout='appmenu:minimize,maximize,close'

        [org.gnome.shell]
        enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'caffeine@patapon.info']

        [org.gnome.shell.extensions.dash-to-dock]
        dock-position='BOTTOM'
        autohide=true
        transparency-mode='DYNAMIC'
        dash-max-icon-size=48

        [org.gnome.desktop.peripherals.touchpad]
        tap-to-click=true
        natural-scroll=true
      '';

      # Enable essential services
      services.flatpak.enable = true;
      services.upower.enable = true;
      programs.dconf.enable = true;

      # Simplified Home Manager configuration
      home-manager.users.notroot = {
        # Unified cursor theme configuration
        home.pointerCursor = {
          gtk.enable = true;
          x11.enable = true;
          name = "Bibata-Modern-Classic";
          size = 24;
          package = pkgs.bibata-cursors;
        };

        # Minimal GTK configuration
        gtk = {
          enable = true;
          cursorTheme = {
            name = "Bibata-Modern-Classic";
            package = pkgs.bibata-cursors;
            size = 24;
          };
          gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
        };

        # Essential DConf settings
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            cursor-theme = "Bibata-Modern-Classic";
            cursor-size = 24;
            color-scheme = "prefer-dark";
            enable-hot-corners = false;
            show-battery-percentage = true;
          };

          "org/gnome/shell" = {
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "org.gnome.Console.desktop"
              "firefox.desktop"
              "ghostty.desktop"
            ];
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "dash-to-dock@micxgx.gmail.com"
              "caffeine@patapon.info"
            ];
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-position = "BOTTOM";
            autohide = true;
            transparency-mode = "DYNAMIC";
            dash-max-icon-size = 48;
          };

          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
            natural-scroll = true;
          };
        };

        # Environment variables for consistent theming
        home.sessionVariables = {
          XCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = "24";
          GSK_RENDERER = "opengl"; # Critical fix for NixOS 25.05
        };
      };
    })
  ];
}
