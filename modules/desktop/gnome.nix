# GNOME Desktop Environment Configuration
# Shared configuration for GNOME desktop across all hosts
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
        description = "Enable Wayland session";
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
    # Display manager and desktop environment
    services.displayManager.gdm = {
      enable = true;
      wayland = config.modules.desktop.gnome.wayland.enable;
    };

    services.desktopManager.gnome.enable = true;

    # Essential GNOME services
    services.gnome = {
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      evolution-data-server.enable = true;
      glib-networking.enable = true;
      sushi.enable = true; # File previews in Nautilus
      tinysparql.enable = true; # Search indexing
    };

    # Additional services for GNOME functionality
    services.geoclue2.enable = true; # Location services
    services.upower.enable = true; # Power management

    # Power management
    services.power-profiles-daemon.enable = lib.mkDefault true;
    services.thermald.enable = lib.mkDefault false; # Conflicts with power-profiles-daemon
    services.tlp.enable = lib.mkForce false; # Use power-profiles-daemon instead

    # Enable dconf for GNOME configuration management
    programs.dconf.enable = true;

    # udev packages for proper GNOME hardware support
    services.udev.packages = with pkgs; [
      gnome-settings-daemon
    ];

    # Environment variables for optimal GNOME experience
    environment.variables = {
      # Fix for GNOME GTK rendering issues on NixOS 25.05+
      GSK_RENDERER = lib.mkForce "ngl";
      # Wayland optimizations
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
      GDK_BACKEND = "wayland,x11";
      # Font rendering and DPI improvements
      FREETYPE_PROPERTIES = "truetype:interpreter-version=40";
      # Wayland debugging (can be removed if not needed)
      WAYLAND_DEBUG = "0";
    };

    environment.sessionVariables = {
      # Essential Wayland support for Electron/Chromium apps
      NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron/Chromium apps (NixOS method)
      XDG_SESSION_TYPE = "wayland";

      # Theme variables (let GNOME handle GTK theme for accent color support)
      XCURSOR_THEME = config.modules.desktop.gnome.theme.cursorTheme;
      XCURSOR_SIZE = "24";

      # Qt integration
      QT_QPA_PLATFORMTHEME = "gnome";
      QT_STYLE_OVERRIDE = "adwaita-dark";

      # Firefox Wayland support
      MOZ_ENABLE_WAYLAND = "1";

      # Display scaling and font improvements
      GDK_SCALE = "1";
      GDK_DPI_SCALE = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_SCALE_FACTOR = "1";
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

        # Additional GNOME components for accent colors and modern features
        libadwaita
        adwaita-icon-theme
        gnome-backgrounds

        # Essential GNOME applications
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
        # GNOME Extensions
        gnomeExtensions.appindicator
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

    # GNOME dconf configuration
    programs.dconf.profiles.user.databases = lib.mkIf config.modules.desktop.gnome.extensions.enable [
      {
        lockAll = false;
        settings = {
          # Enable extensions
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

          # Interface theming (allow GNOME to handle GTK theme for accent color support)
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

          # Mutter window manager settings for better scaling and spacing
          "org/gnome/mutter" = {
            edge-tiling = true;
            dynamic-workspaces = true;
            workspaces-only-on-primary = false;
            center-new-windows = true;
            experimental-features = ["scale-monitor-framebuffer"];
          };

          # Window manager preferences (allow GNOME to handle theme)
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            titlebar-font = "Cantarell Bold 11";
            focus-mode = "click";
          };

          # Dash to Dock configuration
          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-position = "BOTTOM";
            extend-height = false;
            dock-fixed = false;
            autohide = true;
            intellihide = true;
            show-apps-at-top = true;
          };

          # Just Perfection configuration
          "org/gnome/shell/extensions/just-perfection" = {
            panel-in-overview = true;
            activities-button = true;
            app-menu = false;
            clock-menu = true;
            keyboard-layout = true;
          };

          # User theme extension
          "org/gnome/shell/extensions/user-theme" = {
            name = "Arc-Dark";
          };

          # Privacy settings
          "org/gnome/desktop/privacy" = {
            report-technical-problems = false;
            send-software-usage-stats = false;
          };

          # Session settings
          "org/gnome/desktop/session" = {
            idle-delay = lib.gvariant.mkUint32 900;
          };

          # Power settings
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

    # Electron applications configuration for Wayland (simplified)
    environment.etc."electron-flags.conf".text = ''
      --ozone-platform=wayland
    '';

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
