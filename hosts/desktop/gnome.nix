# Desktop Host - GNOME Configuration
# AMD GPU Wayland-optimized setup
{
  config,
  lib,
  ...
}: {
  # Enable GNOME with Wayland
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = true; # NixOS 25.11+ Wayland-only for desktop

    # Enable all standard extensions
    extensions = {
      enable = true;
      appIndicator = true;
      dashToDock = true;
      userThemes = true;
      justPerfection = true;
      vitals = true;
      caffeine = true;
      clipboard = true;
      gsconnect = true;
      workspaceIndicator = true;
      soundOutput = true;
      unite = true; # Hide titlebars for Electron apps like Spotify
      launchNewInstance = true; # Always launch new app windows
    };
  };

  # Desktop-specific GNOME settings via dconf
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        # Enabled extensions list
        "org/gnome/shell" = {
          enabled-extensions = [
            "appindicatorsupport@rgcjonas.gmail.com"
            "dash-to-dock@micxgx.gmail.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "just-perfection-desktop@just-perfection"
            "Vitals@CoreCoding.com"
            "caffeine@patapon.info"
            "clipboard-indicator@tudmotu.com"
            "gsconnect@andyholmes.github.io"
            "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
            "sound-output-device-chooser@kgshank.net"
            "unite@hardpixel.eu"
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.TextEditor.desktop"
            "kitty.desktop"
            "code.desktop"
            "steam.desktop"
          ];
        };

        # Interface settings
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
          clock-show-seconds = false;
          locate-pointer = true;
        };

        # Mutter settings - AMD GPU optimizations
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = false;
          center-new-windows = true;
          # GNOME 48 optimizations for AMD GPU (RX 5700 XT)
          experimental-features = [
            "scale-monitor-framebuffer"
            "rt-scheduler" # Real-time scheduler for smoother animations
          ];
          # Dynamic triple buffering for better performance (GNOME 48 feature)
          dynamic-triple-buffering = true;
          # Optimize for AMD GPU performance
          force-sync = false; # Let AMD GPU handle vsync
        };

        # Window manager preferences
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
          titlebar-font = "Cantarell Bold 11";
          focus-mode = "click";
        };

        # Input configuration
        "org/gnome/desktop/peripherals/keyboard" = {
          numlock-state = true;
          remember-numlock-state = true;
        };

        # Privacy settings
        "org/gnome/desktop/privacy" = {
          report-technical-problems = false;
          send-software-usage-stats = false;
        };

        # Session idle settings
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 900;
        };

        # Power settings - desktop (always plugged in)
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "suspend";
          power-button-action = "interactive";
        };

        # Search settings
        "org/gnome/desktop/search-providers" = {
          disable-external = false;
        };
      };
    }
  ];

  # Desktop-specific environment variables for AMD GPU
  environment.sessionVariables = {
    # Hardware acceleration for AMD GPU
    "LIBVA_DRIVER_NAME" = "radeonsi";
    "VDPAU_DRIVER" = "radeonsi";
  };

  # Security configuration for GNOME
  security.pam.services = {
    gdm = {
      enableGnomeKeyring = true;
    };
    gdm-password = {
      enableGnomeKeyring = true;
    };
  };

  # GNOME login fixes (NixOS Wiki solution for session registration failures)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
