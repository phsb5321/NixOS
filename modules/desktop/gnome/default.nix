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
      services.displayManager.sessionPackages = [pkgs.gnome-session.sessions];

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

        # Fix GNOME Shell timeout and startup issues
        GNOME_SHELL_SLOWDOWN_FACTOR = "1";
        GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "0";
        GNOME_SHELL_DEBUG_MODE = "1";

        # IBus environment variables
        GTK_IM_MODULE = "ibus";
        QT_IM_MODULE = "ibus";
        XMODIFIERS = "@im=ibus";

        # Backend settings (conditional on Wayland vs X11)
        GDK_BACKEND =
          if cfg.displayManager.wayland
          then "wayland,x11"
          else "x11";
        QT_QPA_PLATFORM =
          if cfg.displayManager.wayland
          then "wayland;xcb"
          else "xcb";

        # Wayland-specific optimizations
        NIXOS_OZONE_WL =
          if cfg.displayManager.wayland
          then "1"
          else "0";
        MOZ_ENABLE_WAYLAND =
          if cfg.displayManager.wayland
          then "1"
          else "0";
        ELECTRON_OZONE_PLATFORM_HINT =
          if cfg.displayManager.wayland
          then "wayland"
          else "x11";

        # Unified cursor theme across all environments
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
        
        # Use default Adwaita theme with dark support
        GTK_THEME = mkIf cfg.theming.preferDark "Adwaita:dark";

        # Font-related environment variables to fix UI cramping
        GDK_SCALE = "1";
        GDK_DPI_SCALE = "1";
        QT_SCALE_FACTOR = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "0";
      };

      # Comprehensive GNOME package set with extensive extensions
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

        # Input method framework (fix for ibus-daemon missing)
        ibus

        # Essential GNOME extensions
        gnomeExtensions.dash-to-dock
        gnomeExtensions.user-themes
        gnomeExtensions.just-perfection

        # System monitoring extensions - Multiple options for comprehensive monitoring
        gnomeExtensions.vitals # Temperature, voltage, fan speed, memory, CPU, network, storage
        gnomeExtensions.system-monitor-next # Classic system monitor with graphs
        gnomeExtensions.tophat # Elegant system resource monitor
        gnomeExtensions.multicore-system-monitor # Individual CPU core monitoring
        gnomeExtensions.system-monitor-2 # Alternative system monitor
        gnomeExtensions.resource-monitor # Real-time monitoring in top bar

        # Productivity and customization extensions
        gnomeExtensions.caffeine # Prevent screen lock
        gnomeExtensions.appindicator # System tray support
        gnomeExtensions.blur-my-shell # Blur effects for shell elements
        gnomeExtensions.clipboard-indicator # Clipboard manager
        gnomeExtensions.night-theme-switcher # Automatic dark/light theme switching
        gnomeExtensions.gsconnect # Phone integration (KDE Connect)
        
        # Workspace and window management
        gnomeExtensions.workspace-indicator # Better workspace indicator
        gnomeExtensions.advanced-alttab-window-switcher # Enhanced Alt+Tab
        gnomeExtensions.smart-auto-move # Remember window positions

        # Quick access and navigation
        gnomeExtensions.places-status-indicator # Quick access to bookmarks
        gnomeExtensions.removable-drive-menu # USB drive management
        gnomeExtensions.sound-output-device-chooser # Audio device switching

        # Visual enhancements
        gnomeExtensions.logo-menu # Custom logo in activities
        gnomeExtensions.weather-or-not # Weather in top panel
        gnomeExtensions.desktop-icons-ng-ding # Desktop icons support

        # Additional useful extensions
        gnomeExtensions.clipboard-history # Enhanced clipboard manager
        gnomeExtensions.current-workspace-name # Show workspace name
        gnomeExtensions.improved-workspace-indicator # Better workspace display
        gnomeExtensions.translate-clipboard # Translate clipboard content
        gnomeExtensions.night-light-slider-updated # Night light control
        gnomeExtensions.panel-workspace-scroll # Scroll on panel to switch workspaces

        # Theme and appearance packages
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

      # Modern DConf configuration - unified cursor theme for GDM
      programs.dconf.enable = true;
      programs.dconf.profiles.gdm.databases = [
        {
          settings = {
            "org/gnome/desktop/interface" = {
              cursor-theme = "Adwaita";
              cursor-size = mkInt32 24;
              # Fix scaling issues on GDM
              scaling-factor = mkUint32 1;
              text-scaling-factor = 1.0;
              color-scheme =
                if cfg.theming.preferDark
                then "prefer-dark"
                else "default";
            };
          };
        }
      ];

      # Fonts configuration - CRITICAL FIX for UI cramping
      fonts = {
        enableDefaultPackages = true;
        packages = with pkgs; [
          cantarell-fonts
          dejavu_fonts
          source-sans-pro
          source-serif-pro
          ubuntu_font_family
          # Add Microsoft fonts for better app compatibility
          corefonts
          vistafonts
        ];
        fontconfig = {
          enable = true;
          # Critical font configuration to fix UI cramping
          antialias = true;
          subpixel.rgba = "rgb";
          hinting = {
            enable = true;
            style = "slight";
            autohint = false;
          };
          defaultFonts = {
            serif = ["Source Serif Pro" "DejaVu Serif" "Cantarell"];
            sansSerif = ["Source Sans Pro" "DejaVu Sans" "Cantarell"];
            monospace = ["DejaVu Sans Mono" "Source Code Pro"];
          };
          # Additional font configuration to prevent cramping
          localConf = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <!-- Fix for UI element cramping -->
              <match target="pattern">
                <test name="family"><string>sans-serif</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Cantarell</string>
                  <string>DejaVu Sans</string>
                </edit>
              </match>
              
              <!-- Ensure proper font sizes -->
              <match target="font">
                <edit name="antialias" mode="assign"><bool>true</bool></edit>
                <edit name="hinting" mode="assign"><bool>true</bool></edit>
                <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
                <edit name="rgba" mode="assign"><const>rgb</const></edit>
              </match>
              
              <!-- Disable bitmap fonts that can cause scaling issues -->
              <selectfont>
                <rejectfont>
                  <pattern>
                    <patelt name="scalable"><bool>false</bool></patelt>
                  </pattern>
                </rejectfont>
              </selectfont>
            </fontconfig>
          '';
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
        # GTK theme configuration - with proper dark theme support
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

        # Unified cursor theme for all environments
        home.pointerCursor = {
          gtk.enable = true;
          x11.enable = true;
          name = "Adwaita";
          size = 24;
          package = pkgs.adwaita-icon-theme;
        };

        # Comprehensive DConf settings for the complete GNOME experience
        dconf.settings = {
          # Interface settings with proper dark theme support and FIXED FONT SIZES
          "org/gnome/desktop/interface" = {
            color-scheme =
              if cfg.theming.preferDark
              then "prefer-dark"
              else "default";
            cursor-theme = "Adwaita";
            # CRITICAL FIX: Proper font configuration to prevent UI cramping
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "Source Code Pro 10";
            # Font rendering settings to fix cramping
            font-antialiasing = "grayscale";
            font-hinting = "slight";
            # Scaling settings to prevent cramping
            scaling-factor = mkUint32 1;
            text-scaling-factor = 1.0;
            # UI behavior settings
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
            # FIXED: Proper titlebar font to prevent cramping
            titlebar-font = "Cantarell Bold 11";
          };

          "org/gnome/mutter" = {
            dynamic-workspaces = true;
            workspaces-only-on-primary = true;
            center-new-windows = true;
            attach-modal-dialogs = true;
            # Additional settings to fix scaling issues
            experimental-features = [];
          };

          # Shell configuration with comprehensive extensions
          "org/gnome/shell" = {
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "org.gnome.Console.desktop"
              "firefox.desktop"
              "kitty.desktop"
              "code.desktop"
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
              "space-bar@luchrioh"
              "logo-menu@aryan_k"
              "night-theme-switcher@romainvigier.fr"
              "desktop-icons@csoriano"
              "sound-output-device-chooser@kgshank.net"
              "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
              "places-menu@gnome-shell-extensions.gcampax.github.com"
              "removable-drive-menu@gnome-shell-extensions.gcampax.github.com"
              "gsconnect@andyholmes.github.io"
              "system-monitor-next@paradoxxx.zero.gmail.com"
              "tophat@fflewddur.github.io"
              "weather-or-not@somepaulo.github.io"
            ];
            disable-user-extensions = false;
          };

          # Dash to Dock configuration - clean and functional
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
            mru-sources = [["xkb" "br"]];
          };

          # IBus configuration (fix for missing ibus-daemon)
          "org/gnome/desktop/interface" = {
            gtk-im-module = "ibus";
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

          # Extension configurations
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
            hot-sensors = ["_processor_usage_" "_memory_usage_" "_system_load_1m_" "_temperature_cpu_" "_network-rx_"];
            position-in-panel = 2;
            show-battery = true;
            show-fan = true;
            show-memory = true;
            show-network = true;
            show-processor = true;
            show-storage = true;
            show-system = true;
            show-temperature = true;
            show-voltage = false;
            use-higher-precision = false;
          };

          # Night theme switcher configuration
          "org/gnome/shell/extensions/night-theme-switcher" = {
            enable = true;
            time-source = "nightlight";
          };

          "org/gnome/shell/extensions/night-theme-switcher/gtk-variants" = {
            enabled = true;
            day = "Adwaita";
            night = "Adwaita-dark";
          };

          "org/gnome/shell/extensions/night-theme-switcher/shell-variants" = {
            enabled = true;
            day = "Adwaita";
            night = "Adwaita-dark";
          };

          # GSConnect configuration for phone integration
          "org/gnome/shell/extensions/gsconnect" = {
            enabled = true;
            show-indicators = true;
            show-battery = true;
            show-connectivity = true;
          };
        };

        # Environment variables for user session
        home.sessionVariables = {
          # Critical graphics fix for NixOS 25.05
          GSK_RENDERER = "opengl";

          # Fix GNOME Shell timeout and startup issues
          GNOME_SHELL_SLOWDOWN_FACTOR = "1";
          GNOME_SHELL_DISABLE_HARDWARE_ACCELERATION = "0";
          GNOME_SHELL_DEBUG_MODE = "1";

          # IBus environment variables
          GTK_IM_MODULE = "ibus";
          QT_IM_MODULE = "ibus";
          XMODIFIERS = "@im=ibus";

          # Cursor consistency
          XCURSOR_THEME = "Adwaita";
          XCURSOR_SIZE = "24";

          # Session-specific settings
          GDK_BACKEND =
            if cfg.displayManager.wayland
            then "wayland,x11"
            else "x11";
          QT_QPA_PLATFORM =
            if cfg.displayManager.wayland
            then "wayland;xcb"
            else "xcb";
          NIXOS_OZONE_WL =
            if cfg.displayManager.wayland
            then "1"
            else "0";
        };
      };
    })
  ];
}
