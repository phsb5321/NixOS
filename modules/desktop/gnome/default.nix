# ~/NixOS/modules/desktop/gnome/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
  inherit (lib.gvariant) mkInt32 mkUint32;
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
        displayManager.gdm = {
          enable = true;
          wayland = cfg.displayManager.wayland;
          autoSuspend = cfg.displayManager.autoSuspend;
        };
      };

      # Ensure proper session packages for GDM (critical fix for login issue)
      services.displayManager.sessionPackages = [pkgs.gnome-session];

      # Ensure only GDM is enabled
      services.displayManager.sddm.enable = lib.mkForce false;

      # Complete GNOME services suite
      services.gnome = {
        core-shell.enable = true;
        core-os-services.enable = true;
        core-apps.enable = true;
        gnome-keyring.enable = true;
        gnome-settings-daemon.enable = true;
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        tinysparql.enable = true;
        localsearch.enable = true;
        sushi.enable = true; # File previews
        gnome-remote-desktop.enable = true;
        gnome-user-share.enable = true;
        rygel.enable = true; # DLNA media sharing
      };

      # Essential system services
      services = {
        geoclue2.enable = true;
        upower.enable = true;
        power-profiles-daemon.enable = true;
        thermald.enable = true;

        # Hardware support
        fwupd.enable = cfg.hardware.enableBluetooth; # Firmware updates

        # Bluetooth (if enabled)
        blueman.enable = cfg.hardware.enableBluetooth;

        # Printing (if enabled)
        printing = mkIf cfg.hardware.enablePrinting {
          enable = true;
          drivers = with pkgs; [gutenprint hplip epson-escpr];
        };
        avahi = mkIf cfg.hardware.enablePrinting {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };

        # Scanning (if enabled)
        saned.enable = cfg.hardware.enableScanning;

        # Accessibility (if enabled)
        speechd.enable = lib.mkDefault cfg.accessibility.enable;
      };

      # Audio system optimized for GNOME
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.enable = true;
        jack.enable = true;
      };

      # Environment variables - X11 focused since Wayland is disabled in shared config
      environment.sessionVariables = {
        # Critical fix for GNOME rendering issues in NixOS 25.05
        GSK_RENDERER = "opengl";

        # X11 specific settings (since wayland = false in shared config)
        GDK_BACKEND = mkIf (!cfg.displayManager.wayland) "x11";
        QT_QPA_PLATFORM = mkIf (!cfg.displayManager.wayland) "xcb";

        # Wayland optimization (when enabled)
        NIXOS_OZONE_WL = mkIf cfg.displayManager.wayland "1";
        GDK_BACKEND = mkIf cfg.displayManager.wayland "wayland,x11";
        QT_QPA_PLATFORM = mkIf cfg.displayManager.wayland "wayland;xcb";
        MOZ_ENABLE_WAYLAND = mkIf cfg.displayManager.wayland "1";
        ELECTRON_OZONE_PLATFORM_HINT = mkIf cfg.displayManager.wayland "wayland";

        # Common settings
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
        GTK_THEME = mkIf cfg.theming.preferDark "Adwaita:dark";
      };

      # Comprehensive GNOME package set
      environment.systemPackages = with pkgs; [
        # Core GNOME applications
        gnome-text-editor
        gnome-calculator
        gnome-calendar
        gnome-contacts
        gnome-maps
        gnome-weather
        gnome-music
        gnome-photos
        simple-scan
        seahorse # Keyring management

        # GNOME utilities
        gnome-tweaks
        gnome-extension-manager
        dconf-editor

        # File management
        file-roller # Archive manager

        # Multimedia
        celluloid # Modern video player

        # Essential GNOME extensions
        gnomeExtensions.dash-to-dock
        gnomeExtensions.user-themes
        gnomeExtensions.caffeine
        gnomeExtensions.appindicator
        gnomeExtensions.blur-my-shell
        gnomeExtensions.vitals
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.just-perfection
        gnomeExtensions.space-bar
        gnomeExtensions.logo-menu
        gnomeExtensions.night-theme-switcher

        # Additional useful extensions
        gnomeExtensions.desktop-icons-ng-ding
        gnomeExtensions.sound-output-device-chooser
        gnomeExtensions.workspace-indicator
        gnomeExtensions.places-status-indicator
        gnomeExtensions.removable-drive-menu

        # Theme and appearance
        adwaita-icon-theme
        gnome-themes-extra
        libadwaita
        adw-gtk3
        gsettings-desktop-schemas

        # Fonts for better GNOME experience
        cantarell-fonts
        source-sans-pro
        source-serif-pro
      ];

      # Remove unwanted GNOME packages but keep useful ones
      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        epiphany # Use Firefox instead
        geary # Keep if you use Evolution, remove if not
        totem # Using celluloid instead
        cheese # Camera app - remove if not needed
      ];

      # Modern XDG portal configuration with full GNOME integration
      xdg.portal = {
        enable = true;
        wlr.enable = false; # We're using GNOME, not wlroots
        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
        ];
        config = {
          common = {
            default = ["gnome" "gtk"];
            "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          };
          gnome = {
            default = ["gnome" "gtk"];
            "org.freedesktop.impl.portal.FileChooser" = ["gnome"];
            "org.freedesktop.impl.portal.AppChooser" = ["gnome"];
            "org.freedesktop.impl.portal.Print" = ["gnome"];
            "org.freedesktop.impl.portal.Notification" = ["gnome"];
            "org.freedesktop.impl.portal.Wallpaper" = ["gnome"];
          };
        };
      };

      # Flatpak integration
      services.flatpak.enable = true;

      # Modern DConf configuration instead of deprecated extraGSettingsOverrides
      programs.dconf.enable = true;
      programs.dconf.profiles.gdm.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-theme = "Adwaita";
              cursor-size = mkInt32 24;
              color-scheme =
                if cfg.theming.preferDark
                then "prefer-dark"
                else "default";
            };
          };
        }
      ];

      # Fonts configuration
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          cantarell-fonts
          dejavu_fonts
          source-sans-pro
          source-serif-pro
          ubuntu_font_family
        ];
        fontconfig = {
          enable = true;
          defaultFonts = {
            serif = ["Source Serif Pro" "DejaVu Serif"];
            sansSerif = ["Source Sans Pro" "DejaVu Sans"];
            monospace = ["DejaVu Sans Mono"];
          };
        };
      };

      # Touchpad configuration
      services.libinput = mkIf cfg.hardware.enableTouchpad {
        enable = true;
        touchpad = {
          tapping = true;
          naturalScrolling = true;
          disableWhileTyping = true;
          middleEmulation = true;
        };
      };

      # Home Manager integration for user-level GNOME configuration
      home-manager.users.notroot = {
        # GTK theme configuration
        gtk = {
          enable = true;
          theme = {
            name =
              if cfg.theming.preferDark
              then "Adwaita-dark"
              else "Adwaita";
            package = pkgs.gnome-themes-extra;
          };
          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };
          cursorTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
            size = 24;
          };
          gtk3.extraConfig.gtk-application-prefer-dark-theme = cfg.theming.preferDark;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = cfg.theming.preferDark;
        };

        # Cursor theme for all environments
        home.pointerCursor = {
          gtk.enable = true;
          x11.enable = true;
          name = "Adwaita";
          size = 24;
          package = pkgs.adwaita-icon-theme;
        };

        # Comprehensive DConf settings for the complete GNOME experience
        dconf.settings = {
          # Interface settings
          "org/gnome/desktop/interface" = {
            color-scheme =
              if cfg.theming.preferDark
              then "prefer-dark"
              else "default";
            cursor-theme = "Adwaita";
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "Source Code Pro 10";
            font-antialiasing = "grayscale";
            font-hinting = "slight";
            enable-hot-corners = false;
            show-battery-percentage = true;
            clock-show-weekday = true;
            clock-show-date = true;
            clock-show-seconds = false;
            locate-pointer = true;
          };

          # Window management
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            focus-mode = "click";
            auto-raise = false;
            raise-on-click = true;
            titlebar-font = "Cantarell Bold 11";
          };

          "org/gnome/mutter" = {
            dynamic-workspaces = true;
            workspaces-only-on-primary = true;
            center-new-windows = true;
            attach-modal-dialogs = true;
          };

          # Shell configuration
          "org/gnome/shell" = {
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "org.gnome.Console.desktop"
              "firefox.desktop"
              "ghostty.desktop"
              "org.gnome.Software.desktop"
              "org.gnome.Calculator.desktop"
              "org.gnome.TextEditor.desktop"
            ];
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "dash-to-dock@micxgx.gmail.com"
              "caffeine@patapon.info"
              "appindicatorsupport@rgcjonas.gmail.com"
              "blur-my-shell@aunetx"
              "Vitals@CoreCoding.com"
              "clipboard-indicator@tudmotu.com"
              "just-perfection-desktop@just-perfection"
            ];
            disable-user-extensions = false;
          };

          # Dash to Dock configuration
          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-position = "BOTTOM";
            autohide = true;
            intellihide = false;
            transparency-mode = "DYNAMIC";
            dash-max-icon-size = mkInt32 48;
            unity-backlit-items = true;
            running-indicator-style = "DOTS";
            show-favorites = true;
            show-running = true;
            show-mounts = true;
            show-trash = true;
            isolate-workspaces = false;
            dock-fixed = false;
            extend-height = false;
            height-fraction = 0.9;
            hide-delay = 0.2;
            show-delay = 0.25;
            animation-time = 0.2;
          };

          # Just Perfection settings for cleaner interface
          "org/gnome/shell/extensions/just-perfection" = {
            activities-button = true;
            app-menu = false;
            app-menu-icon = true;
            background-menu = true;
            controls-manager-spacing-size = mkInt32 0;
            dash = true;
            dash-icon-size = mkInt32 0;
            double-super-to-appgrid = true;
            gesture = true;
            hot-corner = false;
            osd = true;
            panel = true;
            panel-arrow = true;
            panel-corner-size = mkInt32 1;
            panel-in-overview = true;
            ripple-box = true;
            search = true;
            show-apps-button = true;
            startup-status = mkInt32 1;
            theme = false;
            window-demands-attention-focus = false;
            window-picker-icon = true;
            window-preview-caption = true;
            window-preview-close-button = true;
            workspace = true;
            workspace-background-corner-size = mkInt32 0;
            workspace-popup = true;
            workspace-switcher-size = mkInt32 0;
            workspaces-in-app-grid = true;
          };

          # File manager settings
          "org/gnome/nautilus/preferences" = {
            default-folder-viewer = "icon-view";
            migrated-gtk-settings = true;
            search-filter-time-type = "last_modified";
            search-view = "list-view";
            show-create-link = true;
            show-delete-permanently = true;
            show-directory-item-counts = "on-demand";
            show-image-thumbnails = "always";
            thumbnail-limit = mkUint32 10485760; # 10MB
          };

          "org/gnome/nautilus/icon-view" = {
            default-zoom-level = "standard";
          };

          "org/gnome/nautilus/list-view" = {
            default-zoom-level = "standard";
            use-tree-view = false;
          };

          # Privacy and security
          "org/gnome/desktop/privacy" = {
            disable-microphone = false;
            disable-camera = false;
            remember-recent-files = true;
            recent-files-max-age = mkUint32 30;
            remove-old-temp-files = true;
            remove-old-trash-files = true;
            old-files-age = mkUint32 30;
          };

          # Search settings
          "org/gnome/desktop/search-providers" = {
            sort-order = ["org.gnome.Contacts.desktop" "org.gnome.Documents.desktop" "org.gnome.Nautilus.desktop"];
            disabled = ["org.gnome.Boxes.desktop"];
          };

          # Power management
          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-type = "suspend";
            sleep-inactive-battery-timeout = mkUint32 1800; # 30 minutes
            power-button-action = "interactive";
            lid-close-ac-action = "nothing";
            lid-close-battery-action = "suspend";
          };

          # Sound settings
          "org/gnome/desktop/sound" = {
            allow-volume-above-100-percent = false;
            event-sounds = true;
            input-feedback-sounds = false;
          };

          # Input devices
          "org/gnome/desktop/peripherals/touchpad" = mkIf cfg.hardware.enableTouchpad {
            tap-to-click = true;
            natural-scroll = true;
            two-finger-scrolling-enabled = true;
            edge-scrolling-enabled = false;
            speed = mkInt32 0;
            disable-while-typing = true;
            send-events = "enabled";
            left-handed = false;
            click-method = "fingers";
          };

          "org/gnome/desktop/peripherals/mouse" = {
            natural-scroll = false;
            speed = mkInt32 0;
            accel-profile = "default";
          };

          # Keyboard settings
          "org/gnome/desktop/input-sources" = {
            sources = [["xkb" "br"]];
            xkb-options = [""];
          };

          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
            remember-numlock-state = true;
          };

          # Calendar and weather
          "org/gnome/calendar" = {
            weather-settings = "(true, true, '', @mv nothing)";
            window-maximized = false;
            window-position = "(26, 23)";
            window-size = "(1268, 600)";
          };

          "org/gnome/Weather" = {
            automatic-location = true;
            locations = "[]";
          };

          # Extensions settings
          "org/gnome/shell/extensions/caffeine" = {
            enable-fullscreen = true;
            restore-state = true;
            show-indicator = true;
            show-notifications = false;
          };

          "org/gnome/shell/extensions/appindicator" = {
            icon-brightness = 0.0;
            icon-contrast = 0.0;
            icon-opacity = 230;
            icon-saturation = 0.0;
            icon-size = 0;
            legacy-tray-enabled = true;
            tray-pos = "right";
          };

          "org/gnome/shell/extensions/blur-my-shell" = {
            brightness = 0.6;
            dash-opacity = 0.12;
            sigma = 30;
            static-blur = true;
          };

          "org/gnome/shell/extensions/vitals" = {
            hide-icons = false;
            hide-zeros = false;
            hot-sensors = ["_processor_usage_" "_memory_usage_" "_system_load_1m_"];
            position-in-panel = 2;
            show-battery = true;
            show-fan = false;
            show-memory = true;
            show-network = false;
            show-processor = true;
            show-storage = false;
            show-system = false;
            show-temperature = false;
            show-voltage = false;
            use-higher-precision = false;
          };
        };

        # Environment variables for user session - X11 focused when Wayland disabled
        home.sessionVariables = {
          # Critical graphics fix for NixOS 25.05
          GSK_RENDERER = "opengl";

          # Cursor consistency
          XCURSOR_THEME = "Adwaita";
          XCURSOR_SIZE = "24";

          # Session-specific settings
          GDK_BACKEND = if cfg.displayManager.wayland then "wayland,x11" else "x11";
          QT_QPA_PLATFORM = if cfg.displayManager.wayland then "wayland;xcb" else "xcb";
          NIXOS_OZONE_WL = mkIf cfg.displayManager.wayland "1";
        };
      };
    })
  ];
}
