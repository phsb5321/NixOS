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

    # GNOME-specific configuration
    (mkIf (cfg.enable && cfg.environment == "gnome") {
      # Enable X server and GNOME desktop environment with GDM
      services.xserver = {
        enable = true;
      };

      # Modern desktop manager configuration
      services.desktopManager.gnome.enable = true;

      # Configure GDM as the display manager
      services.displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
        autoLogin = mkIf cfg.autoLogin.enable {
          enable = true;
          user = cfg.autoLogin.user;
        };
        defaultSession = "gnome";
      };

      # GNOME-specific services
      services.gnome = {
        gnome-keyring.enable = true;
        core-shell.enable = true;
        core-apps.enable = true; # FIXED: was core-utilities.enable
        gnome-settings-daemon.enable = true;
        evolution-data-server.enable = true;
        glib-networking.enable = true;
        tinysparql.enable = true; # Renamed from tracker.enable
        localsearch.enable = true; # Renamed from tracker-miners.enable
      };

      # Additional services needed by GNOME
      services.geoclue2.enable = true;
      services.dbus = {
        enable = true;
        packages = with pkgs; [
          dconf
          gnome-settings-daemon
        ];
      };

      # Add udev rules for GNOME
      services.udev.packages = with pkgs; [
        gnome-settings-daemon
      ];

      # GNOME-specific packages
      environment.systemPackages = with pkgs; [
        # Core GNOME packages
        gnome-tweaks
        gnome-shell-extensions
        dconf-editor
        gnome-backgrounds
        gnome-themes-extra
        gnome-extension-manager

        # Python GTK bindings - fix for "No module named 'gi'" errors
        python3Packages.pygobject3
        python3Packages.pycairo
        gobject-introspection
        glib
        gtk3
        gtk4

        # Missing dependencies identified in logs
        ibus
        libdbusmenu-gtk3
        libappindicator
        libappindicator-gtk3
        libsoup_2_4 # Updated from libsoup
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

        # Enhanced Theme Packages
        adwaita-icon-theme
        papirus-icon-theme
        material-cursors
        vanilla-dmz
        yaru-theme
        adw-gtk3

        # GTK theme engines and additional themes
        gnome-themes-extra
        materia-theme
        arc-theme
        libadwaita # Essential for GNOME theming

        # Font packages for better rendering
        noto-fonts
        noto-fonts-emoji
        cantarell-fonts

        # Theme utilities and GNOME customization tools
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
            default = ["gtk"];
            "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
          };
        };
      };

      # GNOME settings overrides for system-wide defaults
      services.desktopManager.gnome.extraGSettingsOverrides = ''
        [org.gnome.desktop.interface]
        gtk-theme='adw-gtk3-dark'
        icon-theme='Papirus-Dark'
        cursor-theme='Adwaita'
        font-name='Cantarell 11'
        document-font-name='Cantarell 11'
        monospace-font-name='JetBrainsMono Nerd Font Mono 11'
        color-scheme='prefer-dark'
        clock-show-weekday=true
        show-battery-percentage=true

        [org.gnome.desktop.wm.preferences]
        theme='adw-gtk3-dark'
        button-layout='appmenu:minimize,maximize,close'
        titlebar-font='Cantarell Bold 11'

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

      # System activation script to ensure theme cache is generated
      system.activationScripts.gnome-theme-cache = ''
        echo "Setting up GNOME theme cache..."
        ${pkgs.glib}/bin/glib-compile-schemas ${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas

        # Ensure user-level theme directories exist
        mkdir -p /home/${cfg.autoLogin.user}/.local/share/themes
        mkdir -p /home/${cfg.autoLogin.user}/.local/share/icons
        mkdir -p /home/${cfg.autoLogin.user}/.config/gtk-3.0
        mkdir -p /home/${cfg.autoLogin.user}/.config/gtk-4.0

        chown -R ${cfg.autoLogin.user}:users /home/${cfg.autoLogin.user}/.local/share/themes || true
        chown -R ${cfg.autoLogin.user}:users /home/${cfg.autoLogin.user}/.local/share/icons || true
        chown -R ${cfg.autoLogin.user}:users /home/${cfg.autoLogin.user}/.config/gtk-3.0 || true
        chown -R ${cfg.autoLogin.user}:users /home/${cfg.autoLogin.user}/.config/gtk-4.0 || true
      '';

      # Home Manager configuration for persistent GNOME settings
      home-manager.users.${cfg.autoLogin.user} = {
        # Required imports for proper functioning
        imports = [
        ];

        # GTK configuration
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
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
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

        # DConf settings for GNOME
        dconf.settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = "adw-gtk3-dark";
            icon-theme = "Papirus-Dark";
            cursor-theme = "Adwaita";
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
            color-scheme = "prefer-dark";
            clock-show-weekday = true;
            clock-show-seconds = false;
            show-battery-percentage = true;
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

        # Environment variables for consistent theming
        home.sessionVariables = {
          GTK_THEME = "adw-gtk3-dark";
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

              # Apply interface settings
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
              ${pkgs.glib}/bin/gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
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
