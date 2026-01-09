# ~/NixOS/modules/desktop/gnome/base.nix
# Base GNOME desktop environment configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.gnome;
  coreAppsCfg = cfg.coreApps;
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

    # GNOME Core Applications Suite (T001-T008)
    # Provides granular control over GNOME application installation
    coreApps = {
      # Master switch for all GNOME core applications
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GNOME core applications suite";
      };

      # Full suite toggle - when false, disables productivity, media, scanner, connections
      fullSuite = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable full application suite (set false for minimal server installs)";
      };

      # Utilities: calculator, clocks, weather, characters, font viewer, decibels
      utilities = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME utility applications";
        };
        calculator = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Calculator";
        };
        clocks = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Clocks";
        };
        weather = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Weather";
        };
        characters = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Characters";
        };
        fontViewer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Font Viewer";
        };
        decibels = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Decibels audio player";
        };
      };

      # Productivity: calendar, contacts, maps (depends on fullSuite)
      productivity = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME productivity applications";
        };
        calendar = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Calendar";
        };
        contacts = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Contacts";
        };
        maps = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Maps";
        };
      };

      # Media: loupe (image), showtime (video), snapshot (camera)
      media = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME media applications";
        };
        imageViewer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Loupe image viewer";
        };
        videoPlayer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Showtime video player";
        };
        camera = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Snapshot camera";
        };
      };

      # Documents: papers (PDF viewer), simple-scan (scanner)
      documents = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME document applications";
        };
        viewer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Papers PDF viewer";
        };
        scanner = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Simple Scan";
        };
      };

      # System Tools: system monitor, logs, console, help, connections, dconf-editor
      systemTools = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME system tools";
        };
        systemMonitor = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME System Monitor";
        };
        logs = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Logs";
        };
        console = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Console";
        };
        help = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Yelp help viewer";
        };
        connections = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Connections (remote desktop client)";
        };
        dconfEditor = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable dconf Editor";
        };
      };

      # File Management: baobab (disk analyzer), gnome-disk-utility
      fileManagement = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME file management tools";
        };
        diskAnalyzer = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Baobab disk analyzer";
        };
        diskUtility = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable GNOME Disk Utility";
        };
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
    # Conditionally exclude apps based on coreApps settings
    environment.gnome.excludePackages = with pkgs;
      # Always excluded apps (replaced by modern alternatives or unwanted)
      [
        gnome-photos # Replaced by loupe
        gnome-tour
        cheese # Replaced by snapshot
        gnome-music # Replaced by decibels
        gedit # Replaced by gnome-text-editor
        epiphany # GNOME Web browser
        geary # Email client
        totem # Replaced by showtime
        eog # Replaced by loupe
        evince # Replaced by papers
      ]
      # Conditionally exclude productivity apps when fullSuite is disabled
      ++ (lib.optionals (!(coreAppsCfg.enable && coreAppsCfg.fullSuite && coreAppsCfg.productivity.enable && coreAppsCfg.productivity.calendar)) [
        gnome-calendar
      ])
      ++ (lib.optionals (!(coreAppsCfg.enable && coreAppsCfg.fullSuite && coreAppsCfg.productivity.enable && coreAppsCfg.productivity.contacts)) [
        gnome-contacts
      ])
      ++ (lib.optionals (!(coreAppsCfg.enable && coreAppsCfg.fullSuite && coreAppsCfg.productivity.enable && coreAppsCfg.productivity.maps)) [
        gnome-maps
      ])
      # Conditionally exclude characters when utilities.characters is disabled
      ++ (lib.optionals (!(coreAppsCfg.enable && coreAppsCfg.utilities.enable && coreAppsCfg.utilities.characters)) [
        gnome-characters
      ])
      # Games - always excluded
      ++ [
        tali # Poker game
        iagno # Go game
        hitori # Sudoku game
        atomix # Puzzle game
        gnome-chess
        gnome-mahjongg
        gnome-mines
        gnome-sudoku
        gnome-tetravex
        quadrapassel # Tetris
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
    # JUSTIFIED: TLP conflicts with power-profiles-daemon, must be disabled when GNOME power is on
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
        adw-gtk3 # Adwaita-like theme for GTK3
      ])
      # =====================================================
      # GNOME Core Apps Suite (T009-T016)
      # =====================================================
      # Utilities: calculator, clocks, weather, characters, font viewer, decibels
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.utilities.enable) (
        (lib.optional coreAppsCfg.utilities.calculator gnome-calculator)
        ++ (lib.optional coreAppsCfg.utilities.clocks gnome-clocks)
        ++ (lib.optional coreAppsCfg.utilities.weather gnome-weather)
        ++ (lib.optional coreAppsCfg.utilities.characters gnome-characters)
        ++ (lib.optional coreAppsCfg.utilities.fontViewer gnome-font-viewer)
        ++ (lib.optional coreAppsCfg.utilities.decibels decibels)
      ))
      # Productivity: calendar, contacts, maps (only when fullSuite enabled)
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.fullSuite && coreAppsCfg.productivity.enable) (
        (lib.optional coreAppsCfg.productivity.calendar gnome-calendar)
        ++ (lib.optional coreAppsCfg.productivity.contacts gnome-contacts)
        ++ (lib.optional coreAppsCfg.productivity.maps gnome-maps)
      ))
      # Media: loupe (image viewer), showtime (video), snapshot (camera)
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.fullSuite && coreAppsCfg.media.enable) (
        (lib.optional coreAppsCfg.media.imageViewer loupe)
        ++ (lib.optional coreAppsCfg.media.videoPlayer showtime)
        ++ (lib.optional coreAppsCfg.media.camera snapshot)
      ))
      # Documents: papers (PDF viewer), simple-scan (scanner)
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.documents.enable) (
        (lib.optional coreAppsCfg.documents.viewer papers)
        ++ (lib.optional (coreAppsCfg.fullSuite && coreAppsCfg.documents.scanner) simple-scan)
      ))
      # System Tools: monitor, logs, console, help, connections, dconf-editor
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.systemTools.enable) (
        (lib.optional coreAppsCfg.systemTools.systemMonitor gnome-system-monitor)
        ++ (lib.optional coreAppsCfg.systemTools.logs gnome-logs)
        ++ (lib.optional coreAppsCfg.systemTools.console gnome-console)
        ++ (lib.optional coreAppsCfg.systemTools.help yelp)
        ++ (lib.optional (coreAppsCfg.fullSuite && coreAppsCfg.systemTools.connections) gnome-connections)
        ++ (lib.optional coreAppsCfg.systemTools.dconfEditor dconf-editor)
      ))
      # File Management: baobab (disk analyzer), gnome-disk-utility
      ++ (lib.optionals (coreAppsCfg.enable && coreAppsCfg.fileManagement.enable) (
        (lib.optional coreAppsCfg.fileManagement.diskAnalyzer baobab)
        ++ (lib.optional coreAppsCfg.fileManagement.diskUtility gnome-disk-utility)
      ));
  };
}
