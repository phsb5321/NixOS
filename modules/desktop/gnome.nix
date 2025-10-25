# GNOME Desktop Environment Configuration
# NixOS 25.11+ Wayland implementation with enhanced portal support for Bruno
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
        description = "Enable Wayland session (NixOS 25.11+ default)";
      };
    };

    variant = lib.mkOption {
      type = lib.types.enum [
        "hardware"
        "conservative"
        "software"
      ];
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
    # NixOS 25.11+ GNOME configuration with conditional Wayland/X11 support
    services.displayManager.gdm = {
      enable = true;
      wayland = config.modules.desktop.gnome.wayland.enable;
      settings = lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
        daemon = {
          # Disable Wayland in GDM for X11-only mode
          WaylandEnable = false;
          # Force X11 session selection
          DefaultSession = "gnome-xorg.desktop";
        };
        security = {
          # Disable user switching to prevent session conflicts
          AllowGuestAccount = false;
          AllowUserList = true;
        };
      };
    };

    services.desktopManager.gnome.enable = true;

    # X11 support for non-Wayland configurations
    # Note: Even with Wayland, xserver may be needed for video driver configuration
    services.xserver.enable = lib.mkDefault (!config.modules.desktop.gnome.wayland.enable);

    # Comprehensive XDG Desktop Portal configuration for screen sharing and file dialogs
    xdg.portal = {
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

    # Essential GNOME services
    services.gnome = {
      gnome-keyring.enable = true;
      gnome-settings-daemon.enable = true;
      gnome-remote-desktop.enable = true;
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

    # Environment variables conditional on Wayland/X11 mode
    environment.sessionVariables = lib.mkMerge [
      # Common variables for both modes
      {
        XCURSOR_THEME = config.modules.desktop.gnome.theme.cursorTheme;
        XCURSOR_SIZE = "24";
        GTK_USE_PORTAL = "1"; # Portal support for file dialogs
      }

      # Wayland-specific variables
      (lib.mkIf config.modules.desktop.gnome.wayland.enable {
        # Electron Wayland support
        NIXOS_OZONE_WL = "1";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "GNOME";

        # WebRTC PipeWire screen sharing support
        WEBRTC_PIPEWIRE_CAPTURER = "1";

        # Wayland display configuration (fix for GTK regression)
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        MOZ_ENABLE_WAYLAND = "1";

        # Basic GTK configuration
        "GTK_CSD" = "1";                # Enable client-side decorations

        # AMD GPU optimizations for Wayland
        "WLR_DRM_NO_ATOMIC" = "1";      # Compatibility for older compositors
        "CLUTTER_BACKEND" = "wayland";   # Force Wayland for GNOME Shell

        # Hardware acceleration for AMD GPU
        "LIBVA_DRIVER_NAME" = "radeonsi";
        "VDPAU_DRIVER" = "radeonsi";

        # Chrome/Electron specific fixes for tab bar rendering
        "CHROME_OZONE_PLATFORM_WAYLAND" = "1";
        "ELECTRON_ENABLE_WAYLAND" = "1";
      })

      # X11-specific variables
      (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
        # Force GNOME to use X11
        GDK_BACKEND = "x11";
        # Disable Wayland for all applications
        MOZ_ENABLE_WAYLAND = "0";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        # Set renderer for GTK apps (ngl fixes GNOME 47+ rendering issues)
        GSK_RENDERER = "ngl"; # Use new GL renderer for better compatibility
        # Explicitly disable Wayland
        QT_QPA_PLATFORM = "xcb";
        # Force X11 for session
        XDG_SESSION_TYPE = "x11";
        # Note: Hardware-specific variables (NVIDIA, AMD, Intel) should be set
        # in host configurations, not in this shared module
      })
    ];

    # Portal service initialization
    environment.extraInit = ''
      # Ensure portal services start properly
      systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL XDG_SESSION_TYPE 2>/dev/null || true
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP GTK_USE_PORTAL XDG_SESSION_TYPE 2>/dev/null || true
    '';

    # Ensure portal services are available with proper environment
    # Environment variables must match the actual display server (Wayland or X11)
    systemd.user.services.xdg-desktop-portal-gnome = {
      wantedBy = ["default.target"];
      environment = lib.mkMerge [
        {
          XDG_CURRENT_DESKTOP = "GNOME";
        }
        (lib.mkIf config.modules.desktop.gnome.wayland.enable {
          WAYLAND_DISPLAY = "wayland-0";
          XDG_SESSION_TYPE = "wayland";
        })
        (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
          DISPLAY = ":0";
          XDG_SESSION_TYPE = "x11";
        })
      ];
    };

    systemd.user.services.xdg-desktop-portal-gtk = {
      wantedBy = ["default.target"];
      environment = lib.mkMerge [
        {
          XDG_CURRENT_DESKTOP = "GNOME";
        }
        (lib.mkIf config.modules.desktop.gnome.wayland.enable {
          WAYLAND_DISPLAY = "wayland-0";
          XDG_SESSION_TYPE = "wayland";
        })
        (lib.mkIf (!config.modules.desktop.gnome.wayland.enable) {
          DISPLAY = ":0";
          XDG_SESSION_TYPE = "x11";
        })
      ];
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

        # Portal and screen sharing support
        xdg-desktop-portal
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        gnome-remote-desktop

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
            # GNOME 48 optimizations for AMD GPU (RX 5700 XT)
            experimental-features = [
              "scale-monitor-framebuffer"
              "rt-scheduler"  # Real-time scheduler for smoother animations
            ];
            # Dynamic triple buffering for better performance (GNOME 48 feature)
            dynamic-triple-buffering = true;
            # Optimize for AMD GPU performance
            force-sync = false;  # Let AMD GPU handle vsync
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

    # Qt theming integration (can be overridden by host configuration)
    qt = lib.mkDefault {
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
        naturalScrolling = lib.mkDefault false;
      };
    };
  };
}
