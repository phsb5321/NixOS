# Laptop Host - GNOME Configuration
# dconf settings and extension activation (host-specific overrides only)
# Module options (extensions.*, settings.*) are in configuration.nix
{lib, ...}: {
  # Laptop-specific dconf settings (power savings, extension activation)
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
