# ~/NixOS/modules/desktop/gnome/extensions.nix
# GNOME Shell extensions and dconf settings
<<<<<<< HEAD
{ config, lib, pkgs, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  ...
}: let
>>>>>>> origin/host/server
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

<<<<<<< HEAD
    # Additional popular extensions
    blurMyShell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Blur My Shell extension for beautiful blur effects";
    };

    popShell = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Pop Shell for tiling window management";
    };

    burnMyWindows = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Burn My Windows for window close animations";
    };

    windowList = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Window List for taskbar-style window list";
    };

    removableDriveMenu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Removable Drive Menu for easy drive access";
    };

    altTab = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AlternateTab for better Alt+Tab behavior";
    };

    systemMonitor = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable System Monitor extension";
    };

    batteryClock = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Battery Clock extension";
    };

    gpuStats = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GPU Stats extension";
    };

    netspeedSimplified = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Netspeed Simplified for network monitoring";
    };

    windowTitles = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Window Titles on Panel extension";
    };

    topIndicators = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable TopHat (Top Indicators) extension";
    };

=======
>>>>>>> origin/host/server
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
<<<<<<< HEAD
      # Core extensions
      (lib.optionals cfg.extensions.appIndicator [ gnomeExtensions.appindicator ])
      ++ (lib.optionals cfg.extensions.dashToDock [ gnomeExtensions.dash-to-dock ])
      ++ (lib.optionals cfg.extensions.userThemes [ gnomeExtensions.user-themes ])
      ++ (lib.optionals cfg.extensions.justPerfection [ gnomeExtensions.just-perfection ])
      ++ (lib.optionals (cfg.extensions.vitals || cfg.extensions.productivity) [ gnomeExtensions.vitals ])
      ++ (lib.optionals (cfg.extensions.caffeine || cfg.extensions.productivity) [ gnomeExtensions.caffeine ])
      ++ (lib.optionals (cfg.extensions.clipboard || cfg.extensions.productivity) [ gnomeExtensions.clipboard-indicator ])
      ++ (lib.optionals cfg.extensions.gsconnect [ gnomeExtensions.gsconnect ])
      ++ (lib.optionals cfg.extensions.workspaceIndicator [ gnomeExtensions.workspace-indicator ])
      ++ (lib.optionals cfg.extensions.soundOutputChooser [ gnomeExtensions.sound-output-device-chooser ])
      
      # Popular additional extensions
      ++ (lib.optionals cfg.extensions.blurMyShell [ gnomeExtensions.blur-my-shell ])
      ++ (lib.optionals cfg.extensions.popShell [ gnomeExtensions.pop-shell ])
      ++ (lib.optionals cfg.extensions.burnMyWindows [ gnomeExtensions.burn-my-windows ])
      ++ (lib.optionals cfg.extensions.windowList [ gnomeExtensions.window-list ])
      ++ (lib.optionals cfg.extensions.removableDriveMenu [ gnomeExtensions.removable-drive-menu ])
      ++ (lib.optionals cfg.extensions.altTab [ gnomeExtensions.advanced-alttab-window-switcher ])
      ++ (lib.optionals cfg.extensions.systemMonitor [ gnomeExtensions.system-monitor ])
      ++ (lib.optionals cfg.extensions.batteryClock [ gnomeExtensions.battery-time ])
      ++ (lib.optionals cfg.extensions.gpuStats [ gnomeExtensions.vitals ])  # Vitals includes GPU stats
      ++ (lib.optionals cfg.extensions.netspeedSimplified [ gnomeExtensions.net-speed-simplified ])
      ++ (lib.optionals cfg.extensions.windowTitles [ gnomeExtensions.window-list ])  # Window list shows titles
      ++ (lib.optionals cfg.extensions.topIndicators [ gnomeExtensions.tophat ]);
=======
      (lib.optionals cfg.extensions.appIndicator [gnomeExtensions.appindicator])
      ++ (lib.optionals cfg.extensions.dashToDock [gnomeExtensions.dash-to-dock])
      ++ (lib.optionals cfg.extensions.userThemes [gnomeExtensions.user-themes])
      ++ (lib.optionals cfg.extensions.justPerfection [gnomeExtensions.just-perfection])
      ++ (lib.optionals (cfg.extensions.vitals || cfg.extensions.productivity) [gnomeExtensions.vitals])
      ++ (lib.optionals (cfg.extensions.caffeine || cfg.extensions.productivity) [gnomeExtensions.caffeine])
      ++ (lib.optionals (cfg.extensions.clipboard || cfg.extensions.productivity) [gnomeExtensions.clipboard-indicator])
      ++ (lib.optionals cfg.extensions.gsconnect [gnomeExtensions.gsconnect])
      ++ (lib.optionals cfg.extensions.workspaceIndicator [gnomeExtensions.workspace-indicator])
      ++ (lib.optionals cfg.extensions.soundOutputChooser [gnomeExtensions.sound-output-device-chooser]);
>>>>>>> origin/host/server

    # Note: dconf settings are intentionally minimal at system level
    # Users should configure GNOME settings through the GUI or home-manager
    # System-level dconf configuration has been removed to avoid GVariant complexity
  };
}
