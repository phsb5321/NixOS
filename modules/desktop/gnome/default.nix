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
      # Essential GNOME Wayland configuration for NixOS 25.05
      services.xserver = {
        enable = true; # Enables XWayland support
        displayManager.gdm = {
          enable = true; # GNOME Display Manager
          wayland = true; # Explicitly enable Wayland
        };
        desktopManager.gnome.enable = true; # Uses Wayland by default
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
        XCURSOR_THEME = "material_dark_cursors";
        XCURSOR_SIZE = "24";
        GTK_THEME = "adw-gtk3-dark";
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

        # Centralized Theme and Cursor Configuration
        # Material Design cursor theme (dark variant for consistency)
        material-cursors

        # Papirus icon theme (comprehensive icon set)
        papirus-icon-theme

        # Adwaita GTK theme (modern GNOME design)
        adw-gtk3
        libadwaita # Essential for GNOME theming

        # Remove conflicting cursor/theme packages
        # vanilla-dmz removed to avoid conflicts
        # adwaita-icon-theme removed to prefer Papirus

        # Essential theme engines and schemas
        gnome-themes-extra
        gtk3
        gtk4
        gsettings-desktop-schemas

        # Font packages for consistent typography
        noto-fonts
        noto-fonts-emoji
        cantarell-fonts

        # Theme utilities for user customization
        themechanger
        gnome-tweaks
        dconf-editor
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
            default = mkDefault ["gtk"];
            "org.freedesktop.impl.portal.Secret" = mkDefault ["gnome-keyring"];
          };
        };
      };

      # GNOME settings overrides for system-wide defaults - Centralized Theme Configuration
      services.xserver.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.interface]
        gtk-theme='adw-gtk3-dark'
        icon-theme='Papirus-Dark'
        cursor-theme='material_dark_cursors'
        cursor-size=24
        font-name='Cantarell 11'
        document-font-name='Cantarell 11'
        monospace-font-name='JetBrainsMono Nerd Font Mono 11'
        color-scheme='prefer-dark'
        clock-show-weekday=true
        show-battery-percentage=true
        enable-animations=true

        [org.gnome.desktop.wm.preferences]
        theme='adw-gtk3-dark'
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
        enabled-extensions=['user-theme@gnome-shell-extensions.gcampax.github.com', 'dash-to-dock@micxgx.gmail.com', 'blur-my-shell@aunetx', 'clipboard-indicator@tudmotu.com', 'sound-output-device-chooser@kgshank.net', 'gsconnect@andyholmes.github.io', 'caffeine@patapon.info', 'forge@jmmaranan.com']
        favorite-apps=['org.gnome.Nautilus.desktop', 'org.gnome.Console.desktop', 'firefox.desktop', 'code.desktop', 'discord.desktop']

        [org.gnome.shell.extensions.user-theme]
        name='adw-gtk3-dark'

        [org.gnome.shell.extensions.dash-to-dock]
        dock-fixed=false
        dock-position='BOTTOM'
        autohide=true
        intellihide=true
        transparency-mode='DYNAMIC'
        running-indicator-style='DOTS'
        customize-alphas=true
        min-alpha=0.2
        max-alpha=0.8
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

        # GTK configuration - Centralized theme setup
        gtk = {
          enable = true;
          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
          };
          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };
          cursorTheme = {
            name = "material_dark_cursors";
            package = pkgs.material-cursors;
            size = 24;
          };
          font = {
            name = "Cantarell";
            size = 11;
          };
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
          };
        };

        # DConf settings for GNOME - Centralized theme configuration
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "adw-gtk3-dark";
            icon-theme = "Papirus-Dark";
            cursor-theme = "material_dark_cursors";
            cursor-size = 24;
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
            color-scheme = "prefer-dark";
            clock-show-weekday = true;
            clock-show-seconds = false;
            show-battery-percentage = true;
            enable-animations = true;
          };

          "org/gnome/desktop/wm/preferences" = {
            theme = "adw-gtk3-dark";
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
            ];
          };

          "org/gnome/shell/extensions/user-theme" = {
            name = "adw-gtk3-dark";
          };

          "org/gnome/shell/extensions/dash-to-dock" = {
            dock-fixed = false;
            dock-position = "BOTTOM";
            autohide = true;
            intellihide = true;
            transparency-mode = "DYNAMIC";
            running-indicator-style = "DOTS";
            customize-alphas = true;
            min-alpha = 0.2;
            max-alpha = 0.8;
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
          GTK_THEME = "adw-gtk3-dark";
          XCURSOR_THEME = "material_dark_cursors";
          XCURSOR_SIZE = "24";
          NIXOS_OZONE_WL = "1"; # Chromium/Electron Wayland support
          GDK_BACKEND = "wayland,x11"; # GTK applications prefer Wayland
          MOZ_ENABLE_WAYLAND = "1"; # Firefox Wayland support
          QT_QPA_PLATFORM = "wayland;xcb"; # Qt applications
          WAYLAND_DISPLAY = "wayland-0";
        };

        # Add systemd service to ensure theme settings are applied
        systemd.user.services.gnome-theme-fix = {
          Unit = {
            Description = "Apply GNOME theme settings";
            After = ["graphical-session.target"];
            PartOf = ["graphical-session.target"];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = toString (pkgs.writeShellScript "gnome-theme-fix" ''
              # Wait for GNOME Shell to be ready
              sleep 3

              # Apply interface settings with Material cursors
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme 'material_dark_cursors'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-size 24
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

              # Apply window manager settings
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.wm.preferences theme 'adw-gtk3-dark'

              # Apply shell theme
              ${pkgs.glib}/bin/gsettings set org.gnome.shell.extensions.user-theme name 'adw-gtk3-dark'

              # Force refresh GNOME Shell
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
              sleep 1
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
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
