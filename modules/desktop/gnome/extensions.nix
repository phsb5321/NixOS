# Shared GNOME Extensions Configuration
# Common extensions and settings used across hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.desktop.gnome.extensions = {
    enable = lib.mkEnableOption "GNOME Shell extensions";

    # Common extensions available to all hosts
    appIndicator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable AppIndicator and system tray support";
    };

    dashToDock = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Dash to Dock";
    };

    userThemes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable User Themes";
    };

    justPerfection = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Just Perfection";
    };

    vitals = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Vitals system monitor";
    };

    caffeine = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Caffeine (prevent screen dimming)";
    };

    clipboard = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Clipboard Indicator";
    };

    gsconnect = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable GSConnect (KDE Connect integration)";
    };

    workspaceIndicator = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Workspace Indicator";
    };

    soundOutput = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Sound Output Device Chooser";
    };

    # Custom extension list for advanced users
    customList = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional custom extensions to enable";
    };
  };

  config = lib.mkIf config.modules.desktop.gnome.extensions.enable {
    # Install extension packages
    environment.systemPackages = with pkgs;
      []
      ++ lib.optional config.modules.desktop.gnome.extensions.appIndicator gnomeExtensions.appindicator
      ++ lib.optional config.modules.desktop.gnome.extensions.dashToDock gnomeExtensions.dash-to-dock
      ++ lib.optional config.modules.desktop.gnome.extensions.userThemes gnomeExtensions.user-themes
      ++ lib.optional config.modules.desktop.gnome.extensions.justPerfection gnomeExtensions.just-perfection
      ++ lib.optional config.modules.desktop.gnome.extensions.vitals gnomeExtensions.vitals
      ++ lib.optional config.modules.desktop.gnome.extensions.caffeine gnomeExtensions.caffeine
      ++ lib.optional config.modules.desktop.gnome.extensions.clipboard gnomeExtensions.clipboard-indicator
      ++ lib.optional config.modules.desktop.gnome.extensions.gsconnect gnomeExtensions.gsconnect
      ++ lib.optional config.modules.desktop.gnome.extensions.workspaceIndicator gnomeExtensions.workspace-indicator
      ++ lib.optional config.modules.desktop.gnome.extensions.soundOutput gnomeExtensions.sound-output-device-chooser;

    # Extension list management moved to host-specific gnome.nix files
    # to avoid dconf database merging conflicts
    # Each host should define its own programs.dconf.profiles.user.databases
    # with the enabled-extensions list based on the extensions they enable
  };
}
