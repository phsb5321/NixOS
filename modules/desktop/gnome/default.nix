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
      # GNOME Wayland configuration with minimal X server for XWayland
      services.xserver = {
        enable = true; # Required for XWayland and GNOME packages
        # No display manager configuration here - handled by coordinator
        desktopManager.gnome.enable = true; # GNOME desktop environment
      };

      # Ensure proper session packages are available for GDM
      services.displayManager.sessionPackages = [pkgs.gnome-session.sessions];

      # Pipewire audio system (optimal for Wayland)
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # GNOME-specific services
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

      # Additional services needed by GNOME
      services.geoclue2.enable = true;

      # Enhanced dbus configuration for GNOME
      services.dbus = {
        enable = true;
        packages = with pkgs; [
          dconf
          gnome-settings-daemon
          gsettings-desktop-schemas
          gnome-session
          gnome-shell
        ];
      };

      # Essential system services for session management
      systemd.services.gnome-session-manager = {
        description = "GNOME Session Manager";
        wantedBy = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        after = ["graphical-session-pre.target"];
      };

      # Add udev rules for GNOME
      services.udev.packages = with pkgs; [
        gnome-settings-daemon
      ];

      # System-wide environment variables for consistent theming
      environment.sessionVariables = {
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
        GTK_THEME = "Orchis-Dark-Compact";
      };

      # GNOME-specific packages
      environment.systemPackages = with pkgs; [
        # Core GNOME packages
        gnome-tweaks
        gnome-shell-extensions
        dconf-editor
        gnome-backgrounds
        gnome-themes-extra
        gnome-extension-manager

        # Essential session packages - Fix for GDM Wayland session registration
        gnome-session
        gnome-session.sessions
        gnome-shell

        # Python GTK bindings - fix for "No module named 'gi'" errors
        python3Packages.pygobject3
        python3Packages.pycairo
        gobject-introspection
        glib
        glib.dev # Contains glib-compile-schemas
        glib.bin # Ensures glib-compile-schemas is available in PATH
        gsettings-desktop-schemas # GNOME schema files
        gtk3
        gtk4

        # Missing dependencies identified in logs
        ibus
        libdbusmenu-gtk3
        libappindicator
        libappindicator-gtk3
        libsoup_2_4
        dconf

        # Extensions from the configuration
        gnomeExtensions.dash-to-dock
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.sound-output-device-chooser
        gnomeExtensions.gsconnect
        gnomeExtensions.blur-my-shell
        gnomeExtensions.caffeine
        gnomeExtensions.forge
        gnomeExtensions.user-themes

        # Additional modern extensions for better visual experience
        gnomeExtensions.just-perfection
        gnomeExtensions.rounded-window-corners-reborn
        gnomeExtensions.compiz-windows-effect

        # Centralized Theme and Cursor Configuration
        # Modern Orchis GTK theme (elegant dark theme with rounded corners)
        orchis-theme

        # Tela icon theme (modern, colorful, consistent design)
        tela-icon-theme

        # Bibata cursor theme (modern, smooth animations)
        bibata-cursors

        # Essential theme dependencies
        adw-gtk3 # Keep as fallback
        libadwaita # Essential for GNOME theming
        gnome-themes-extra
        gtk3
        gtk4
        gsettings-desktop-schemas

        # Font packages for consistent typography
        noto-fonts
        noto-fonts-emoji
        cantarell-fonts
        # Additional modern fonts for better visual experience
        inter
        lexend

        # Theme utilities for user customization
        themechanger
        gnome-tweaks
        dconf-editor

        # Additional visual enhancement tools
        gnome-backgrounds
        vanilla-dmz # Fallback cursor theme
        adwaita-icon-theme # Fallback icon theme
      ];

      # Configure XDG portal specifically for GNOME
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
        config = {
          gnome = {
            default = mkForce ["gnome" "gtk"];
            "org.freedesktop.impl.portal.Secret" = mkDefault ["gnome-keyring"];
          };
        };
      };

      # GNOME settings overrides for system-wide defaults - Modern Theme Configuration
      services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.interface]
        gtk-theme='Orchis-Dark-Compact'
        icon-theme='Tela-dark'
        cursor-theme='Bibata-Modern-Classic'
        cursor-size=24
        font-name='Cantarell 11'
        document-font-name='Cantarell 11'
        monospace-font-name='JetBrainsMono Nerd Font Mono 11'
        color-scheme='prefer-dark'
        accent-color='blue'
        clock-show-weekday=true
        show-battery-percentage=true
        enable-animations=true
        enable-hot-corners=false

        [org.gnome.desktop.wm.preferences]
        theme='Orchis-Dark-Compact'
        button-layout='appmenu:minimize,maximize,close'
        titlebar-font='Cantarell Bold 11'

        [org.gnome.desktop.peripherals.mouse]
        accel-profile='adaptive'

        [org.gnome.desktop.peripherals.touchpad]
        tap-to-click=true
        natural-scroll=true
        two-finger-scrolling-enabled=true

        [org.gnome.desktop.screensaver]
        lock-enabled=true
        lock-delay=uint32 300

        [org.gnome.desktop.lockdown]
        disable-lock-screen=false

        [org.gnome.shell]
        enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'clipboard-indicator@tudmotu.com', 'sound-output-device-chooser@kgshank.net', 'gsconnect@andyholmes.github.io', 'caffeine@patapon.info', 'forge@jmmaranan.com', 'just-perfection-desktop@just-perfection', 'rounded-window-corners@fxgn', 'compiz-windows-effect@hermes83.github.com']
        favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'firefox.desktop', 'code.desktop', 'discord.desktop']

        [org.gnome.shell.extensions.user-theme]
        name='Orchis-Dark-Compact'

        [org.gnome.shell.extensions.dash-to-dock]
        dock-fixed=false
        dock-position='BOTTOM'
        autohide=true
        intellihide=true
        transparency-mode='DYNAMIC'
        running-indicator-style='DOTS'
        customize-alphas=true
        min-alpha=0.15
        max-alpha=0.85
        dash-max-icon-size=48
        apply-custom-theme=true

        [org.gnome.shell.extensions.blur-my-shell]
        brightness=0.85
        sigma=15

        [org.gnome.desktop.background]
        color-shading-type='solid'
        picture-options='zoom'
        primary-color='#1e1e2e'
        secondary-color='#181825'
      '';

      # Enable Flatpak support
      services.flatpak.enable = true;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.Flatpak.app-install" ||
               action.id == "org.freedesktop.Flatpak.app-remove") &&
              subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';

      # Power management settings
      services.upower = {
        enable = true;
        percentageLow = 15;
        percentageCritical = 5;
        percentageAction = 3;
      };

      # Enable DConf settings and ensure proper database setup
      programs.dconf.enable = true;

      # GNOME automatically handles schema compilation and theme cache
      # User directories will be created by GNOME on first login

      # Home Manager configuration for persistent GNOME settings
      home-manager.users.notroot = {
        # Required imports for proper functioning
        imports = [
        ];

        # GTK configuration - Modern theme setup with Orchis and Tela
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
          font = {
            name = "Cantarell";
            size = 11;
          };
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-decoration-layout = "appmenu:minimize,maximize,close";
          };
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-decoration-layout = "appmenu:minimize,maximize,close";
          };
        };

        # DConf settings for GNOME - Modern theme configuration
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "Orchis-Dark-Compact";
            icon-theme = "Tela-dark";
            cursor-theme = "Bibata-Modern-Classic";
            cursor-size = 24;
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
            color-scheme = "prefer-dark";
            accent-color = "blue";
            clock-show-weekday = true;
            clock-show-seconds = false;
            show-battery-percentage = true;
            enable-animations = true;
            enable-hot-corners = false;
          };

          "org/gnome/desktop/wm/preferences" = {
            theme = "Orchis-Dark-Compact";
            button-layout = "appmenu:minimize,maximize,close";
            titlebar-font = "Cantarell Bold 11";
          };

          "org/gnome/shell" = {
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "org.gnome.Console.desktop"
              "firefox.desktop"
              "code.desktop"
              "discord.desktop"
            ];
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "dash-to-dock@micxgx.gmail.com"
              "blur-my-shell@aunetx"
              "clipboard-indicator@tudmotu.com"
              "sound-output-device-chooser@kgshank.net"
              "gsconnect@andyholmes.github.io"
              "caffeine@patapon.info"
              "forge@jmmaranan.com"
              "just-perfection-desktop@just-perfection"
              "rounded-window-corners@fxgn"
              "compiz-windows-effect@hermes83.github.com"
            ];
          };

          "org/gnome/shell/extensions/user-theme" = {
            name = "Orchis-Dark-Compact";
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-fixed = false;
            dock-position = "BOTTOM";
            autohide = true;
            intellihide = true;
            transparency-mode = "DYNAMIC";
            running-indicator-style = "DOTS";
            customize-alphas = true;
            min-alpha = 0.15;
            max-alpha = 0.85;
            dash-max-icon-size = 48;
            apply-custom-theme = true;
          };

          "org/gnome/shell/extensions/blur-my-shell" = {
            brightness = 0.85;
            sigma = 15;
          };

          "org/gnome/desktop/background" = {
            color-shading-type = "solid";
            picture-options = "zoom";
            primary-color = "#1e1e2e";
            secondary-color = "#181825";
          };

          "org/gnome/desktop/peripherals/touchpad" = {
            tap-to-click = true;
            natural-scroll = true;
            two-finger-scrolling-enabled = true;
          };

          "org/gnome/desktop/privacy" = {
            disable-microphone = false;
            disable-camera = false;
          };

          "org/gnome/desktop/screensaver" = {
            lock-enabled = true;
            lock-delay = "uint32 300";
          };

          "org/gnome/desktop/session" = {
            idle-delay = "uint32 600";
          };

          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-battery-type = "suspend";
            sleep-inactive-battery-timeout = 1800;
          };

          "org/gnome/nautilus/preferences" = {
            default-folder-viewer = "icon-view";
            search-filter-time-type = "last_modified";
            show-hidden-files = false;
          };

          "org/gnome/nautilus/icon-view" = {
            default-zoom-level = "medium";
          };
        };

        # Environment variables for consistent theming and Wayland compatibility
        home.sessionVariables = {
          GTK_THEME = "Orchis-Dark-Compact";
          XCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = "24";
          NIXOS_OZONE_WL = "1"; # Chromium/Electron Wayland support
          GDK_BACKEND = "wayland,x11"; # GTK applications prefer Wayland
          MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland support
          QT_QPA_PLATFORM = "wayland;xcb"; # Qt applications
          WAYLAND_DISPLAY = "wayland-0";
        };

        # Add systemd service to ensure modern theme settings are applied
        systemd.user.services.gnome-theme-fix = {
          Unit = {
            Description = "Apply modern GNOME theme settings";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = toString (pkgs.writeShellScript "gnome-theme-fix" ''
              # Wait for GNOME Shell to be ready
              sleep 3

              # Apply modern interface settings with Orchis theme and Bibata cursors
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark-Compact'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme 'Tela-dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-size 24
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface accent-color 'blue'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface enable-hot-corners false

              # Apply window manager settings
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.wm.preferences theme 'Orchis-Dark-Compact'

              # Apply shell theme
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.user-theme name 'Orchis-Dark-Compact'

              # Configure dash-to-dock for better appearance
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-dock min-alpha 0.15
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.dash-to-dock max-alpha 0.85

              # Configure blur-my-shell for modern effects
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.blur-my-shell brightness 0.85
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.blur-my-shell sigma 15

              # Set elegant background colors
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.background primary-color '#1e1e2e'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.background secondary-color '#181825'

              # Force refresh GNOME Shell to apply changes
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
              sleep 1
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark-Compact'
            '');
          };
          Install = {
            WantedBy = ["graphical-session.target"];
          };
        };
      };
    })
  ];
}
