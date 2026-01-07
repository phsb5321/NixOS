# Laptop Host - GNOME Configuration
# Power-optimized X11 setup (host-specific overrides only)
{
  config,
  lib,
  ...
}: {
  # Enable GNOME with common settings
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = false; # X11 for Intel/NVIDIA compatibility
    settings.enable = true; # Common dconf settings from module

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

        # Mutter - power savings (no fancy features)
        "org/gnome/mutter" = {
          edge-tiling = true;
          dynamic-workspaces = true;
          workspaces-only-on-primary = true;
          center-new-windows = true;
          experimental-features = lib.gvariant.mkEmptyArray lib.gvariant.type.string;
          dynamic-triple-buffering = false;
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
