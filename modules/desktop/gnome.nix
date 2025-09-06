# GNOME Desktop Environment Configuration  
# NixOS 25.11+ Wayland-only implementation (X11 sessions removed in 25.11+)
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.desktop.gnome = {
    enable = lib.mkEnableOption "GNOME desktop environment";

    extensions = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable GNOME Shell extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "dash-to-dock@micxgx.gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "just-perfection-desktop@just-perfection"
          "appindicatorsupport@rgcjonas.gmail.com"
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
          "Vitals@CoreCoding.com"
          "caffeine@patapon.info"
          "clipboard-indicator@tudmotu.com"
          "gsconnect@andyholmes.github.io"
          "sound-output-device-chooser@kgshank.net"
        ];
        description = "List of GNOME Shell extensions to enable";
      };
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

    wayland = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Wayland session (only option in NixOS 25.11+)";
      };
    };

    variant = lib.mkOption {
      type = lib.types.enum ["hardware" "conservative" "software"];
      default = "hardware";
      description = ''
        Hardware acceleration variant:
        - hardware: Normal operation with full hardware acceleration
        - conservative: Conservative fallback for GPU issues with tear-free
        - software: Emergency software rendering fallback
      '';
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.enable {
    # NixOS 25.11+ GNOME configuration (Wayland-only)
    services.displayManager.gdm = {
      enable = true;
      wayland = true; # Only supported mode in NixOS 25.11+
    };
    
    services.desktopManager.gnome.enable = true;

    # Essential GNOME services
    services.gnome = {
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      sushi.enable = true;
      tinysparql.enable = true;
    };

    # Additional services
    services.geoclue2.enable = true;
    services.upower.enable = true;

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

    # Wayland environment configuration for NixOS 25.11+
    environment.sessionVariables = {
      # Enable Electron Wayland support
      NIXOS_OZONE_WL = "1";
      # Ensure Wayland session
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "GNOME";
      # Basic Wayland support
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      MOZ_ENABLE_WAYLAND = "1";
      # Cursor theme
      XCURSOR_THEME = config.modules.desktop.gnome.theme.cursorTheme;
      XCURSOR_SIZE = "24";
    };

    # Core GNOME packages
    environment.systemPackages = with pkgs;
      [
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

        # Theme packages
        arc-theme
        papirus-icon-theme
        bibata-cursors
        adwaita-icon-theme
        gnome-themes-extra
        gtk-engine-murrine
      ]
      ++ lib.optionals config.modules.desktop.gnome.extensions.enable [
        # System tray support
        gnomeExtensions.appindicator
        # Extensions
        gnomeExtensions.dash-to-dock
        gnomeExtensions.user-themes
        gnomeExtensions.just-perfection
        gnomeExtensions.vitals
        gnomeExtensions.caffeine
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.gsconnect
        gnomeExtensions.workspace-indicator
        gnomeExtensions.sound-output-device-chooser
      ];

    # Extension configuration
    programs.dconf.profiles.user.databases = lib.mkIf config.modules.desktop.gnome.extensions.enable [
      {
        lockAll = false;
        settings = {
          "org/gnome/shell" = {
            enabled-extensions = config.modules.desktop.gnome.extensions.list;
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "firefox.desktop"
              "org.gnome.Terminal.desktop"
              "org.gnome.TextEditor.desktop"
              "kitty.desktop"
            ];
          };

          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            icon-theme = config.modules.desktop.gnome.theme.iconTheme;
            cursor-theme = config.modules.desktop.gnome.theme.cursorTheme;
            cursor-size = lib.gvariant.mkInt32 24;
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "Source Code Pro 10";
            enable-animations = true;
            enable-hot-corners = false;
            show-battery-percentage = true;
            clock-show-weekday = true;
          };

          "org/gnome/mutter" = {
            edge-tiling = true;
            dynamic-workspaces = true;
            workspaces-only-on-primary = false;
            center-new-windows = true;
            experimental-features = ["scale-monitor-framebuffer"];
          };

          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            titlebar-font = "Cantarell Bold 11";
            focus-mode = "click";
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-position = "BOTTOM";
            extend-height = false;
            dock-fixed = false;
            autohide = true;
            intellihide = true;
            show-apps-at-top = true;
          };

          "org/gnome/shell/extensions/just-perfection" = {
            panel-in-overview = true;
            activities-button = true;
            app-menu = false;
            clock-menu = true;
            keyboard-layout = true;
          };

          "org/gnome/shell/extensions/user-theme" = {
            name = "Arc-Dark";
          };

          "org/gnome/desktop/privacy" = {
            report-technical-problems = false;
            send-software-usage-stats = false;
          };

          "org/gnome/desktop/session" = {
            idle-delay = lib.gvariant.mkUint32 900;
          };

          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-type = "suspend";
            power-button-action = "interactive";
          };
        };
      }
    ];

    # Qt theming integration
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    # Enhanced font configuration
    fonts = {
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
        naturalScrolling = false;
      };
    };
  };
}