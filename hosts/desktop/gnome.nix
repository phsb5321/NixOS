# Desktop Host - GNOME Configuration
# dconf settings and extension activation (host-specific overrides only)
# Module options (extensions.*, settings.*) are in configuration.nix
{lib, ...}: {
  # Desktop-specific dconf settings (AMD GPU optimizations, power, extension activation)
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
