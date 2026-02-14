# Desktop Host - GNOME Configuration
# AMD GPU Wayland-optimized setup (host-specific overrides only)
{lib, ...}: {
  # Enable GNOME with common settings
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = true;
    settings.enable = true; # Common dconf settings from module

    # GNOME Core Apps - Full Suite for desktop
    coreApps = {
      enable = true;
      fullSuite = true; # All categories enabled
    };

    # Desktop extension set (full features)
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
      unite = true;
      launchNewInstance = true;
    };
  };

  # Desktop-specific dconf settings (AMD GPU optimizations, power)
  programs.dconf.profiles.user.databases = [
    {
      lockAll = false;
      settings = {
        # Shell - extensions and favorites
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
            "kitty.desktop"
            "code.desktop"
            "steam.desktop"
          ];
        };

        # Mutter - AMD GPU optimizations
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = false;
          center-new-windows = true;
          experimental-features = ["scale-monitor-framebuffer" "rt-scheduler"];
          dynamic-triple-buffering = true;
          force-sync = false;
        };

        # Session - desktop idle (15 min)
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 900;
        };

        # Power - desktop (always plugged in)
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "suspend";
          power-button-action = "interactive";
        };
      };
    }
  ];

  # AMD GPU environment variables
  environment.sessionVariables = {
    "LIBVA_DRIVER_NAME" = "radeonsi";
    "VDPAU_DRIVER" = "radeonsi";
  };
}
