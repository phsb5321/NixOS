# GNOME Desktop Environment Configuration
# NixOS 25.11+ Wayland implementation with enhanced portal support for Bruno
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./gnome-extensions.nix
  ];
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
        default = [];
        description = "List of GNOME Shell extensions to enable (automatically populated by gnome-extensions module)";
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
        description = "Enable Wayland session (NixOS 25.11+ default)";
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
    # NixOS 25.11+ GNOME Wayland configuration
    services.displayManager.gdm = {
      enable = true;
      wayland = config.modules.desktop.gnome.wayland.enable;
    };
    
    services.desktopManager.gnome.enable = true;

    # Comprehensive XDG Desktop Portal configuration for Bruno file dialogs
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk # Essential for FileChooser interface
      ];
      config = {
        common = {
          default = [ "gnome" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
        };
        gnome = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.Print" = [ "gtk" ];
        };
      };
    };

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

    # Optimized Wayland environment for Electron file dialogs
    environment.sessionVariables = {
      # Electron Wayland support
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "GNOME";
      
      # Portal support for file dialogs (crucial for Bruno)
      GTK_USE_PORTAL = "1";
      
      # Wayland display configuration
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
      MOZ_ENABLE_WAYLAND = "1";
      
      # Theme configuration
      XCURSOR_THEME = config.modules.desktop.gnome.theme.cursorTheme;
      XCURSOR_SIZE = "24";
    };

    # Portal service initialization
    environment.extraInit = ''
      # Ensure portal services start properly
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL 2>/dev/null || true
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL 2>/dev/null || true
    '';

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
      ];
      # Extension packages are now managed by the gnome-extensions module

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