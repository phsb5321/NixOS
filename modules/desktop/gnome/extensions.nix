# ~/NixOS/modules/desktop/gnome/extensions.nix
# GNOME Shell extensions and dconf settings
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome.extensions = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GNOME Shell extensions";
    };

    appIndicator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AppIndicator extension";
    };

    dashToDock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Dash to Dock extension";
    };

    userThemes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable User Themes extension";
    };

    justPerfection = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Just Perfection extension";
    };

    vitals = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Vitals system monitor extension";
    };

    caffeine = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Caffeine extension";
    };

    clipboard = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clipboard Indicator extension";
    };

    gsconnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GSConnect (KDE Connect) extension";
    };

    workspaceIndicator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Workspace Indicator extension";
    };

    soundOutputChooser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Sound Output Device Chooser extension";
    };

    unite = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Unite extension (hides titlebars for non-GTK apps)";
    };

    launchNewInstance = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Launch New Instance extension (always launch new app windows)";
    };

    productivity = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable productivity extensions (Vitals, Caffeine, Clipboard)";
    };
  };

  options.modules.desktop.gnome.settings = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Apply GNOME dconf settings";
    };

    darkMode = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable dark mode";
    };

    animations = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable animations";
    };

    hotCorners = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hot corners";
    };

    batteryPercentage = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show battery percentage";
    };

    weekday = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show weekday in clock";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.extensions.enable) {
    # Extension packages
    environment.systemPackages = with pkgs;
      (lib.optionals cfg.extensions.appIndicator [gnomeExtensions.appindicator])
      ++ (lib.optionals cfg.extensions.dashToDock [gnomeExtensions.dash-to-dock])
      ++ (lib.optionals cfg.extensions.userThemes [gnomeExtensions.user-themes])
      ++ (lib.optionals cfg.extensions.justPerfection [gnomeExtensions.just-perfection])
      ++ (lib.optionals (cfg.extensions.vitals || cfg.extensions.productivity) [gnomeExtensions.vitals])
      ++ (lib.optionals (cfg.extensions.caffeine || cfg.extensions.productivity) [gnomeExtensions.caffeine])
      ++ (lib.optionals (cfg.extensions.clipboard || cfg.extensions.productivity) [gnomeExtensions.clipboard-indicator])
      ++ (lib.optionals cfg.extensions.gsconnect [gnomeExtensions.gsconnect])
      ++ (lib.optionals cfg.extensions.workspaceIndicator [gnomeExtensions.workspace-indicator])
      ++ (lib.optionals cfg.extensions.soundOutputChooser [gnomeExtensions.sound-output-device-chooser])
      ++ (lib.optionals cfg.extensions.unite [gnomeExtensions.unite])
      ++ (lib.optionals cfg.extensions.launchNewInstance [gnomeExtensions.launch-new-instance]);

    # Note: dconf settings are intentionally minimal at system level
    # Users should configure GNOME settings through the GUI or home-manager
    # System-level dconf configuration has been removed to avoid GVariant complexity
  };
}
