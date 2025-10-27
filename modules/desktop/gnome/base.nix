# Shared GNOME Desktop Base Configuration
# Common GNOME setup used across all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.desktop.gnome.base = {
    enable = lib.mkEnableOption "GNOME desktop base configuration";

    displayManager = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GDM display manager";
    };

    coreServices = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable core GNOME services";
    };

    coreApplications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install core GNOME applications";
    };

    portal = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable XDG desktop portals";
    };

    themes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GNOME themes and icons";
    };

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install GNOME fonts";
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.base.enable {
    # Desktop Manager
    services.desktopManager.gnome.enable = true;

    # Display Manager (GDM)
    services.displayManager.gdm = lib.mkIf config.modules.desktop.gnome.base.displayManager {
      enable = true;
    };

    # Essential GNOME services
    services.gnome = lib.mkIf config.modules.desktop.gnome.base.coreServices {
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-remote-desktop.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      sushi.enable = true;
      tinysparql.enable = true;
    };

    # Additional services
    services.geoclue2.enable = lib.mkDefault true;
    services.upower.enable = lib.mkDefault true;

    # Essential support
    programs.dconf.enable = true;

    # Power management
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.thermald.enable = lib.mkDefault false;
    services.tlp.enable = lib.mkForce false;

    # System support
    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    # XDG Desktop Portal configuration for screen sharing and file dialogs
    xdg.portal = lib.mkIf config.modules.desktop.gnome.base.portal {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome # GNOME portal implementation
        xdg-desktop-portal-gtk # Essential for FileChooser interface
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
          default = [
            "gnome"
            "gtk"
          ];
          "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
          "org.freedesktop.impl.portal.Print" = ["gtk"];
          "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
          "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        };
      };
    };

    # Core GNOME packages
    environment.systemPackages = with pkgs;
      (lib.optionals config.modules.desktop.gnome.base.coreApplications [
        # Essential GNOME packages
        gnome-session
        gnome-settings-daemon
        gnome-control-center
        gnome-tweaks
        gnome-shell

        # GNOME applications
        gnome-terminal
        gnome-text-editor
        nautilus
        firefox

        # Portal and screen sharing support
        xdg-desktop-portal
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        gnome-remote-desktop
      ])
      ++ (lib.optionals config.modules.desktop.gnome.base.themes [
        # Theme packages
        arc-theme
        papirus-icon-theme
        bibata-cursors
        adwaita-icon-theme
        gnome-themes-extra
        gtk-engine-murrine
      ]);

    # Enhanced font configuration
    fonts = lib.mkIf config.modules.desktop.gnome.base.fonts {
      packages = with pkgs; [
        cantarell-fonts
        source-code-pro
        noto-fonts
        noto-fonts-emoji
        noto-fonts-cjk-sans
        nerd-fonts.jetbrains-mono
      ];
      fontconfig = {
        defaultFonts = {
          serif = ["Noto Serif"];
          sansSerif = ["Cantarell"];
          monospace = ["Source Code Pro"];
          emoji = ["Noto Color Emoji"];
        };
        hinting.enable = true;
        antialias = true;
      };
    };

    # Input device management
    services.libinput = {
      enable = true;
      mouse = {
        accelProfile = "adaptive";
        accelSpeed = "0";
      };
      touchpad = {
        accelProfile = "adaptive";
        accelSpeed = "0";
        tapping = true;
        naturalScrolling = lib.mkDefault false;
      };
    };

    # Qt theming integration (can be overridden by host configuration)
    qt = lib.mkDefault {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };
  };
}
