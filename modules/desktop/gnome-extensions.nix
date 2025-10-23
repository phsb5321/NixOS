# Shared GNOME Extensions Configuration
# Centralized extension management for all GNOME hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.desktop.gnomeExtensions = {
    enable = lib.mkEnableOption "shared GNOME Shell extensions";

    # Core extensions that should be on all hosts
    coreExtensions = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable essential GNOME extensions";
      };
      
      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "dash-to-dock@micxgx.gmail.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "just-perfection-desktop@just-perfection"
          "appindicatorsupport@rgcjonas.gmail.com"
          "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        ];
        description = "Core GNOME Shell extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          # Essential core extensions
          gnomeExtensions.dash-to-dock
          gnomeExtensions.user-themes
          gnomeExtensions.just-perfection
          gnomeExtensions.appindicator
          gnomeExtensions.workspace-indicator
        ];
        description = "Core GNOME extension packages";
      };
    };

    # System monitoring extensions
    systemMonitoring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable system monitoring extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "Vitals@CoreCoding.com"
          "system-monitor-next@paradoxxx.zero.gmail.com"
        ];
        description = "System monitoring extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gnomeExtensions.vitals # Primary system monitor with temperature, CPU, network, storage
          gnomeExtensions.system-monitor-next # Additional system monitor with graphs
        ];
        description = "System monitoring extension packages";
      };
    };

    # Productivity extensions
    productivity = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable productivity extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "caffeine@patapon.info"
          "clipboard-indicator@tudmotu.com"
          "gsconnect@andyholmes.github.io"
        ];
        description = "Productivity extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gnomeExtensions.caffeine # Prevent screen lock
          gnomeExtensions.clipboard-indicator # Clipboard manager
          gnomeExtensions.gsconnect # Phone integration (KDE Connect)
        ];
        description = "Productivity extension packages";
      };
    };

    # Window management extensions
    windowManagement = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable window management extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "advanced-alt-tab@G-dH.github.com"
          "panel-workspace-scroll@glerro.pm.me"
          "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
          "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
        ];
        description = "Window management extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gnomeExtensions.advanced-alttab-window-switcher # Enhanced Alt+Tab
          gnomeExtensions.panel-workspace-scroll # Scroll on panel to switch workspaces
          gnomeExtensions.auto-move-windows # Remember window positions per workspace
          gnomeExtensions.launch-new-instance
        ];
        description = "Window management extension packages";
      };
    };

    # Visual and customization extensions
    visual = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable visual and customization extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "blur-my-shell@aunetx"
        ];
        description = "Visual customization extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gnomeExtensions.blur-my-shell # Modern blur effects
        ];
        description = "Visual customization extension packages";
      };
    };

    # Quick access and navigation extensions
    navigation = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable navigation and quick access extensions";
      };

      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "places-menu@gnome-shell-extensions.gcampax.github.com"
          "drive-menu@gnome-shell-extensions.gcampax.github.com"
          "sound-output-device-chooser@kgshank.net"
        ];
        description = "Navigation extension IDs";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          gnomeExtensions.places-status-indicator # Quick access to bookmarks
          gnomeExtensions.removable-drive-menu # USB drive management
          gnomeExtensions.sound-output-device-chooser # Audio device switching
        ];
        description = "Navigation extension packages";
      };
    };

    # Additional extensions per host
    extraExtensions = {
      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional extension IDs for specific hosts";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [];
        description = "Additional extension packages for specific hosts";
      };
    };
  };

  config = lib.mkIf config.modules.desktop.gnomeExtensions.enable {
    # Install all enabled extension packages
    environment.systemPackages = with config.modules.desktop.gnomeExtensions;
      (lib.optionals coreExtensions.enable coreExtensions.packages)
      ++ (lib.optionals systemMonitoring.enable systemMonitoring.packages)
      ++ (lib.optionals productivity.enable productivity.packages)
      ++ (lib.optionals windowManagement.enable windowManagement.packages)
      ++ (lib.optionals visual.enable visual.packages)
      ++ (lib.optionals navigation.enable navigation.packages)
      ++ extraExtensions.packages;

    # Generate the complete list of enabled extension IDs
    modules.desktop.gnome.extensions.list = with config.modules.desktop.gnomeExtensions;
      (lib.optionals coreExtensions.enable coreExtensions.list)
      ++ (lib.optionals systemMonitoring.enable systemMonitoring.list)
      ++ (lib.optionals productivity.enable productivity.list)
      ++ (lib.optionals windowManagement.enable windowManagement.list)
      ++ (lib.optionals visual.enable visual.list)
      ++ (lib.optionals navigation.enable navigation.list)
      ++ extraExtensions.list;
  };
}