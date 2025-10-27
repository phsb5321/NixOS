# Laptop Host - GNOME Configuration
# Intel GPU X11 setup optimized for battery life
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable GNOME with X11 for better compatibility
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = false; # X11 for Intel GPU compatibility

    # Enable essential extensions only (battery conscious)
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
      soundOutput = false; # Not needed on laptop
    };
  };

  # Laptop-specific GNOME settings via dconf
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
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "org.gnome.TextEditor.desktop"
            "code.desktop"
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
          enable-animations = true; # Keep animations but optimize below
          enable-hot-corners = false;
          show-battery-percentage = true;
          clock-show-weekday = true;
          clock-show-seconds = false;
          locate-pointer = true;
        };

        # Mutter settings - laptop power savings
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = true; # Single display for laptop
          center-new-windows = true;
          # Minimal experimental features for battery life
          experimental-features = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
          # Disable triple buffering for better battery life
          dynamic-triple-buffering = false;
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

        # Session idle settings - shorter for battery
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 300; # 5 minutes
        };

        # Power settings - laptop optimized
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "suspend"; # Suspend even on AC
          sleep-inactive-battery-type = "suspend";
          power-button-action = "suspend";
          idle-dim = true;
          ambient-enabled = false; # Disable adaptive brightness
        };

        # Search settings
        "org/gnome/desktop/search-providers" = {
          disable-external = false;
        };
      };
    }
  ];

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
