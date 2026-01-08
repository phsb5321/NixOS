# ~/NixOS/modules/desktop/gnome/settings.nix
# Common GNOME dconf settings shared across hosts
# Host-specific gnome.nix files extend this with hardware-specific settings
# NOTE: Options are defined in extensions.nix, this file only provides the config
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.gnome;
in {
  # No options here - they are already defined in extensions.nix

  config = lib.mkIf (cfg.enable && cfg.settings.enable) {
    # Common GNOME dconf settings
    # These are merged with host-specific databases
    programs.dconf.profiles.user.databases = lib.mkBefore [
      {
        lockAll = false;
        settings = {
          # Interface settings - common across all hosts
          "org/gnome/desktop/interface" = {
            color-scheme =
              if cfg.settings.darkMode
              then "prefer-dark"
              else "default";
            icon-theme = cfg.theme.iconTheme;
            cursor-theme = cfg.theme.cursorTheme;
            cursor-size = lib.gvariant.mkInt32 24;
            font-name = "Cantarell 11";
            document-font-name = "Cantarell 11";
            monospace-font-name = "Source Code Pro 10";
            enable-animations = cfg.settings.animations;
            enable-hot-corners = cfg.settings.hotCorners;
            show-battery-percentage = cfg.settings.batteryPercentage;
            clock-show-weekday = cfg.settings.weekday;
            clock-show-seconds = false;
            locate-pointer = true;
          };

          # Window manager preferences - common
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "appmenu:minimize,maximize,close";
            titlebar-font = "Cantarell Bold 11";
            focus-mode = "click";
          };

          # Input configuration - common
          "org/gnome/desktop/peripherals/keyboard" = {
            numlock-state = true;
            remember-numlock-state = true;
          };

          # Privacy settings - common
          "org/gnome/desktop/privacy" = {
            report-technical-problems = false;
            send-software-usage-stats = false;
          };

          # Search settings - common
          "org/gnome/desktop/search-providers" = {
            disable-external = false;
          };
        };
      }
    ];

    # Common PAM services for GNOME
    security.pam.services = {
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };

    # Common GNOME login fixes (NixOS Wiki)
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;
  };
}
