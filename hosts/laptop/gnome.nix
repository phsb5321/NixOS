# Laptop Host - GNOME Configuration
# Wayland setup for GNOME 49+ (host-specific overrides only)
{lib, ...}: {
  # Enable GNOME with common settings
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = true; # Required for GNOME 49+ (X11 sessions removed)
    settings.enable = true; # Common dconf settings from module

    # GNOME Core Apps - Full Suite for laptop
    coreApps = {
      enable = true;
      fullSuite = true; # All categories enabled
    };

    # Laptop extension set (battery conscious)
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
    };
  };

  # Laptop-specific dconf settings (power savings)
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
          ];
          favorite-apps = [
            "org.gnome.Nautilus.desktop"
            "firefox.desktop"
            "org.gnome.Terminal.desktop"
            "code.desktop"
          ];
        };

        # Mutter - Wayland features for GNOME 49+
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = true;
          center-new-windows = true;
          experimental-features = [
            "scale-monitor-framebuffer"
            "xwayland-native-scaling"
            "variable-refresh-rate"
            "autoclose-xwayland"
          ];
        };

        # Session - laptop idle (5 min)
        "org/gnome/desktop/session" = {
          idle-delay = lib.gvariant.mkUint32 300;
        };

        # Power - laptop optimized
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "suspend";
          sleep-inactive-battery-type = "suspend";
          power-button-action = "suspend";
          idle-dim = true;
          ambient-enabled = false;
        };
      };
    }
  ];
}
