# ~/NixOS/modules/desktop/gnome/extensions.nix
# GNOME Shell extensions and dconf settings
{ config, lib, pkgs, ... }:

let
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
      (lib.optionals cfg.extensions.appIndicator [ gnomeExtensions.appindicator ])
      ++ (lib.optionals cfg.extensions.dashToDock [ gnomeExtensions.dash-to-dock ])
      ++ (lib.optionals cfg.extensions.userThemes [ gnomeExtensions.user-themes ])
      ++ (lib.optionals cfg.extensions.justPerfection [ gnomeExtensions.just-perfection ])
      ++ (lib.optionals (cfg.extensions.vitals || cfg.extensions.productivity) [ gnomeExtensions.vitals ])
      ++ (lib.optionals (cfg.extensions.caffeine || cfg.extensions.productivity) [ gnomeExtensions.caffeine ])
      ++ (lib.optionals (cfg.extensions.clipboard || cfg.extensions.productivity) [ gnomeExtensions.clipboard-indicator ])
      ++ (lib.optionals cfg.extensions.gsconnect [ gnomeExtensions.gsconnect ])
      ++ (lib.optionals cfg.extensions.workspaceIndicator [ gnomeExtensions.workspace-indicator ])
      ++ (lib.optionals cfg.extensions.soundOutputChooser [ gnomeExtensions.sound-output-device-chooser ]);

    # dconf settings
    programs.dconf.profiles.user.databases = lib.mkIf cfg.settings.enable [
      {
        lockAll = false;
        settings = {
          # Enabled extensions
          "org/gnome/shell" = {
            enabled-extensions = lib.flatten [
              (lib.optional cfg.extensions.appIndicator "appindicatorsupport@rgcjonas.gmail.com")
              (lib.optional cfg.extensions.dashToDock "dash-to-dock@micxgx.gmail.com")
              (lib.optional cfg.extensions.userThemes "user-theme@gnome-shell-extensions.gcampax.github.com")
              (lib.optional cfg.extensions.justPerfection "just-perfection-desktop@just-perfection")
              (lib.optional (cfg.extensions.vitals || cfg.extensions.productivity) "Vitals@CoreCoding.com")
              (lib.optional (cfg.extensions.caffeine || cfg.extensions.productivity) "caffeine@patapon.info")
              (lib.optional (cfg.extensions.clipboard || cfg.extensions.productivity) "clipboard-indicator@tudmotu.com")
              (lib.optional cfg.extensions.gsconnect "gsconnect@andyholmes.github.io")
              (lib.optional cfg.extensions.workspaceIndicator "workspace-indicator@gnome-shell-extensions.gcampax.github.com")
              (lib.optional cfg.extensions.soundOutputChooser "sound-output-device-chooser@kgshank.net")
            ];
            favorite-apps = [
              "org.gnome.Nautilus.desktop"
              "firefox.desktop"
              "org.gnome.Terminal.desktop"
              "org.gnome.TextEditor.desktop"
            ];
          };

          # Desktop interface settings
          "org/gnome/desktop/interface" = {
            color-scheme = if cfg.settings.darkMode then "prefer-dark" else "default";
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
          };

          # Window manager settings
          "org/gnome/mutter" = {
            edge-tiling = true;
            dynamic-workspaces = true;
            workspaces-only-on-primary = false;
            center-new-windows = true;
          };
        };
      }
    ];
  };
}
