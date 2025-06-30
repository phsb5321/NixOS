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

      # Ensure proper session packages for GDM
      services.displayManager.sessionPackages = [pkgs.gnome-session.sessions];

      # Modern audio system optimized for Wayland
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true; # Modern session manager
      };

      # Essential GNOME services (streamlined)
      services.gnome = {
        gnome-keyring.enable = true;
        core-shell.enable = true;
        core-os-services.enable = true;
        gnome-settings-daemon.enable = true;
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        tinysparql.enable = true;
        localsearch.enable = true;
      };

      # Additional required services
      services.geoclue2.enable = true;

      # Essential system environment variables with GSK_RENDERER fix
      environment.sessionVariables = {
        # Fix for GNOME white window issue in NixOS 25.05
        GSK_RENDERER = "opengl";
        # Modern theming
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
        GTK_THEME = "Orchis-Dark-Compact";
        # Wayland optimization
        NIXOS_OZONE_WL = "1";
        GDK_BACKEND = "wayland,x11";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
      };

      # Enable desktop fonts
      modules.desktop.fonts.enable = true;

      # Consolidated and optimized package list
      environment.systemPackages = with pkgs; [
        # Essential GNOME packages
        gnome-tweaks
        gnome-extension-manager
        dconf-editor

        # Core GNOME extensions (curated set)
        gnomeExtensions.dash-to-dock
        gnomeExtensions.blur-my-shell
        gnomeExtensions.user-themes
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.caffeine
        gnomeExtensions.gsconnect
        gnomeExtensions.just-perfection

        # Unified theme packages (no duplicates)
        orchis-theme
        tela-icon-theme
        bibata-cursors

        # Essential theme dependencies only
        libadwaita
        adw-gtk3
        gsettings-desktop-schemas

        # Modern fonts
        cantarell-fonts
        noto-fonts
        noto-fonts-emoji
      ];

      # Exclude unwanted GNOME packages to reduce bloat
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
      ];

      # Modern XDG portal configuration
      xdg.portal = {
        enable = true;
        extraPortals = [pkgs.xdg-desktop-portal-gnome];
        config.gnome.default = ["gnome"];
      };

      # System-wide GNOME settings with modern defaults
      services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.interface]
        gtk-theme='Orchis-Dark-Compact'
        icon-theme='Tela-dark'
        cursor-theme='Bibata-Modern-Classic'
        cursor-size=24
        color-scheme='prefer-dark'
        enable-hot-corners=false
        show-battery-percentage=true

        [org.gnome.desktop.wm.preferences]
        button-layout='appmenu:minimize,maximize,close'

        [org.gnome.shell]
        enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'clipboard-indicator@tudmotu.com', 'gsconnect@andyholmes.github.io', 'caffeine@patapon.info', 'just-perfection-desktop@just-perfection']

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

      # Streamlined Home Manager configuration
      home-manager.users.notroot = {
        # Modern GTK configuration
        gtk = {
          enable = true;
          theme = {
            name = "Orchis-Dark-Compact";
            package = pkgs.orchis-theme;
          };
          iconTheme = {
            name = "Tela-dark";
            package = pkgs.tela-icon-theme;
          };
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
            gtk-theme = "Orchis-Dark-Compact";
            icon-theme = "Tela-dark";
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
            ];
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "dash-to-dock@micxgx.gmail.com"
              "blur-my-shell@aunetx"
              "clipboard-indicator@tudmotu.com"
              "gsconnect@andyholmes.github.io"
              "caffeine@patapon.info"
              "just-perfection-desktop@just-perfection"
            ];
          };

          "org/gnome/shell/extensions/user-theme" = {
            name = "Orchis-Dark-Compact";
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
          GTK_THEME = "Orchis-Dark-Compact";
          XCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = "24";
          GSK_RENDERER = "opengl"; # Critical fix for NixOS 25.05
        };
      };
    })
  ];
}
