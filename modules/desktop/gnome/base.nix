# ~/NixOS/modules/desktop/gnome/base.nix
# Base GNOME desktop environment configuration
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";

    displayManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GDM display manager";
    };

    coreServices = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable essential GNOME services (keyring, settings daemon, etc.)";
    };

    coreApplications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install core GNOME applications (Nautilus, Terminal, etc.)";
    };

    themes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GNOME themes and icon packs";
    };

    portal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure XDG Desktop Portal for file dialogs and screen sharing";
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable power management (power-profiles-daemon)";
    };

    theme = {
      iconTheme = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        description = "Icon theme name";
      };

      cursorTheme = lib.mkOption {
        type = lib.types.str;
        default = "Bibata-Modern-Ice";
        description = "Cursor theme name";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Display Manager
    services.displayManager.gdm = lib.mkIf cfg.displayManager {
      enable = true;
    };

    # Desktop Manager
    services.desktopManager.gnome.enable = true;

    # XDG Desktop Portal
    xdg.portal = lib.mkIf cfg.portal {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
      ];
      config = {
        common = {
          default = ["gnome"];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
          "org.freedesktop.impl.portal.Print" = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        };
        gnome = {
          default = ["gnome" "gtk"];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
          "org.freedesktop.impl.portal.Print" = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        };
      };
    };

    # Essential GNOME services
    services.gnome = lib.mkIf cfg.coreServices {
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-remote-desktop.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      sushi.enable = true;
      tinysparql.enable = true;

      # Disable bloat
      core-apps.enable = false;
      games.enable = false;
      core-developer-tools.enable = false;
    };

    # Additional services
    services.geoclue2.enable = lib.mkIf cfg.coreServices true;
    services.upower.enable = lib.mkIf cfg.coreServices true;

    # Exclude unwanted GNOME packages
    environment.gnome.excludePackages = with pkgs; [
      # Apps
      gnome-photos
      gnome-tour
      cheese          # Webcam app
      gnome-music
      gedit
      epiphany        # GNOME Web browser
      geary           # Email client
      gnome-characters
      totem           # Video player
      gnome-calendar
      gnome-contacts
      gnome-maps

      # Games
      tali            # Poker game
      iagno           # Go game
      hitori          # Sudoku game
      atomix          # Puzzle game
      gnome-chess
      gnome-mahjongg
      gnome-mines
      gnome-sudoku
      gnome-tetravex
      quadrapassel    # Tetris
      five-or-more
      four-in-a-row
      gnome-taquin
      gnome-klotski
      gnome-nibbles
      gnome-robots
      lightsoff
      swell-foop
    ];

    # dconf support
    programs.dconf.enable = true;

    # Power management
    services.power-profiles-daemon.enable = lib.mkIf cfg.powerManagement (lib.mkDefault true);
    services.thermald.enable = lib.mkIf cfg.powerManagement (lib.mkDefault false);
    services.tlp.enable = lib.mkIf cfg.powerManagement (lib.mkForce false);

    # System support
    services.udev.packages = lib.mkIf cfg.coreServices (with pkgs; [
      gnome-settings-daemon
    ]);

    # Environment variables
    environment.sessionVariables = {
      XCURSOR_THEME = cfg.theme.cursorTheme;
      XCURSOR_SIZE = "24";
      GTK_USE_PORTAL = lib.mkIf cfg.portal "1";
    };

    # Portal service initialization
    environment.extraInit = lib.mkIf cfg.portal ''
      # Ensure portal services start properly
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL 2>/dev/null || true
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL 2>/dev/null || true
    '';

    # Portal services
    systemd.user.services = lib.mkIf cfg.portal {
      xdg-desktop-portal-gnome = {
        wantedBy = ["default.target"];
        environment = {
          XDG_CURRENT_DESKTOP = "GNOME";
          WAYLAND_DISPLAY = "wayland-0";
        };
      };

      xdg-desktop-portal-gtk = {
        wantedBy = ["default.target"];
        environment = {
          XDG_CURRENT_DESKTOP = "GNOME";
          WAYLAND_DISPLAY = "wayland-0";
        };
      };
    };

    # Core GNOME packages
    environment.systemPackages = with pkgs;
      # Essential packages
      (lib.optionals cfg.coreApplications [
        gnome-session
        gnome-settings-daemon
        gnome-control-center
        gnome-tweaks
        gnome-shell
        gnome-terminal
        gnome-text-editor
        nautilus
      ])

      # Portal packages
      ++ (lib.optionals cfg.portal [
        xdg-desktop-portal
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        gnome-remote-desktop
      ])

      # Theme packages
      ++ (lib.optionals cfg.themes [
        arc-theme
        papirus-icon-theme
        bibata-cursors
        adwaita-icon-theme
        gnome-themes-extra
        gtk-engine-murrine
        adw-gtk3  # Adwaita-like theme for GTK3
      ]);
  };
}
