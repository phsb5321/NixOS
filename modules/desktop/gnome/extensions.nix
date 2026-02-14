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

    # NOTE: soundOutputChooser removed — the extension was discontinued and
    # does not work on GNOME 45+.  GNOME 45+ has native Quick Settings for
    # audio output switching.  Kept as a no-op alias so existing configs
    # that set it to true won't fail evaluation.
    soundOutputChooser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Deprecated no-op (sound-output-device-chooser is dead on GNOME 45+)";
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

  config = lib.mkIf (cfg.enable && cfg.extensions.enable) (let
    # Single source of truth: map each option to its package and dconf UUID.
    # Adding a new extension only requires adding one entry here.
    extensionMap = [
      {
        cond = cfg.extensions.appIndicator;
        pkg = pkgs.gnomeExtensions.appindicator;
        uuid = "appindicatorsupport@rgcjonas.gmail.com";
      }
      {
        cond = cfg.extensions.dashToDock;
        pkg = pkgs.gnomeExtensions.dash-to-dock;
        uuid = "dash-to-dock@micxgx.gmail.com";
      }
      {
        cond = cfg.extensions.userThemes;
        pkg = pkgs.gnomeExtensions.user-themes;
        uuid = "user-theme@gnome-shell-extensions.gcampax.github.com";
      }
      {
        cond = cfg.extensions.justPerfection;
        pkg = pkgs.gnomeExtensions.just-perfection;
        uuid = "just-perfection-desktop@just-perfection";
      }
      {
        cond = cfg.extensions.vitals || cfg.extensions.productivity;
        pkg = pkgs.gnomeExtensions.vitals;
        uuid = "Vitals@CoreCoding.com";
      }
      {
        cond = cfg.extensions.caffeine || cfg.extensions.productivity;
        pkg = pkgs.gnomeExtensions.caffeine;
        uuid = "caffeine@patapon.info";
      }
      {
        cond = cfg.extensions.clipboard || cfg.extensions.productivity;
        pkg = pkgs.gnomeExtensions.clipboard-indicator;
        uuid = "clipboard-indicator@tudmotu.com";
      }
      {
        cond = cfg.extensions.gsconnect;
        pkg = pkgs.gnomeExtensions.gsconnect;
        uuid = "gsconnect@andyholmes.github.io";
      }
      {
        cond = cfg.extensions.workspaceIndicator;
        pkg = pkgs.gnomeExtensions.workspace-indicator;
        uuid = "workspace-indicator@gnome-shell-extensions.gcampax.github.com";
      }
      {
        cond = cfg.extensions.unite;
        pkg = pkgs.gnomeExtensions.unite;
        uuid = "unite@hardpixel.eu";
      }
      {
        cond = cfg.extensions.launchNewInstance;
        pkg = pkgs.gnomeExtensions.launch-new-instance;
        uuid = "launch-new-instance@gnome-shell-extensions.gcampax.github.com";
      }
    ];

    # Filter to only enabled extensions
    enabledExtensions = builtins.filter (e: e.cond) extensionMap;
  in {
    # Install extension packages
    environment.systemPackages = map (e: e.pkg) enabledExtensions;

    # Auto-generate dconf enabled-extensions list from the same source of truth.
    # This ensures every installed extension is activated, and no activated
    # extension is missing its package. Host gnome.nix files no longer need
    # to maintain their own enabled-extensions lists.
    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/shell" = {
            enabled-extensions = map (e: e.uuid) enabledExtensions;
          };
        };
      }
    ];
  });
}
