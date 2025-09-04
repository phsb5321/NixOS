# Flatpak Configuration Module
# Declarative Flatpak management using nix-flatpak
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.flatpak = {
    enable = lib.mkEnableOption "Flatpak application management";

    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable automatic Flatpak updates";
      };

      schedule = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        description = "Schedule for automatic updates";
      };
    };

    development = {
      enable = lib.mkEnableOption "development Flatpak applications";
      
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "com.usebruno.Bruno" # Bruno API Client (better portal integration than Nix package)
        ];
        description = "List of development Flatpak applications";
      };
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional Flatpak packages specific to this host";
    };
  };

  config = lib.mkIf config.modules.flatpak.enable {
    # Enable Flatpak service
    services.flatpak = {
      enable = true;

      # Configure automatic updates
      update = {
        onActivation = true;
        auto = lib.mkIf config.modules.flatpak.autoUpdate.enable {
          enable = true;
          onCalendar = config.modules.flatpak.autoUpdate.schedule;
        };
      };

      # Install development packages if enabled
      packages = 
        (lib.optionals config.modules.flatpak.development.enable config.modules.flatpak.development.packages)
        ++ config.modules.flatpak.extraPackages;
    };

    # Ensure XDG portals are properly configured for Flatpak
    xdg.portal = {
      enable = true;
      config = {
        common = {
          default = [ "gnome" ];
        };
      };
    };

    # Environment setup for Flatpak
    environment.systemPackages = with pkgs; [
      flatpak # Ensure flatpak CLI is available
      
      # Create wrapper script for Bruno Flatpak
      (writeShellScriptBin "bruno" ''
        exec flatpak run com.usebruno.Bruno "$@"
      '')
    ];

    # Add Flatpak applications to PATH
    environment.profiles = [
      "/var/lib/flatpak/exports"
      "$HOME/.local/share/flatpak/exports"
    ];

    # Shell aliases for convenient access to Flatpak apps
    programs.bash.shellAliases = lib.mkIf config.modules.flatpak.development.enable {
      bruno-flatpak = "flatpak run com.usebruno.Bruno";
    };
    
    programs.zsh.shellAliases = lib.mkIf config.modules.flatpak.development.enable {
      bruno-flatpak = "flatpak run com.usebruno.Bruno";
    };
  };
}