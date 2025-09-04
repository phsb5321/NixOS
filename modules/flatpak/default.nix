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
          # Bruno removed due to persistent D-Bus portal issues
          # Will be installed via AppImage instead
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

    # Environment setup for Flatpak and AppImage support
    environment.systemPackages = with pkgs; [
      flatpak # Ensure flatpak CLI is available
      fuse # Required for AppImage support
      
      # Create wrapper script for Bruno AppImage (extracted version)
      (writeShellScriptBin "bruno" ''
        BRUNO_APPIMAGE="$HOME/.local/bin/bruno.AppImage"
        BRUNO_EXTRACTED="$HOME/.local/share/bruno-extracted"
        BRUNO_URL="https://github.com/usebruno/bruno/releases/download/v2.10.0/bruno_2.10.0_x86_64_linux.AppImage"
        
        # Download and extract AppImage if not exists
        if [ ! -d "$BRUNO_EXTRACTED" ]; then
          echo "Setting up Bruno AppImage..."
          mkdir -p "$(dirname "$BRUNO_APPIMAGE")" "$BRUNO_EXTRACTED"
          
          # Download if needed
          if [ ! -f "$BRUNO_APPIMAGE" ]; then
            ${pkgs.curl}/bin/curl -L -o "$BRUNO_APPIMAGE" "$BRUNO_URL"
            chmod +x "$BRUNO_APPIMAGE"
          fi
          
          # Extract AppImage contents
          cd "$BRUNO_EXTRACTED"
          "$BRUNO_APPIMAGE" --appimage-extract >/dev/null
          mv squashfs-root/* .
          rmdir squashfs-root
        fi
        
        # Run extracted Bruno binary
        exec "$BRUNO_EXTRACTED/bruno" "$@"
      '')
    ];

    # Add Flatpak applications to PATH
    environment.profiles = [
      "/var/lib/flatpak/exports"
      "$HOME/.local/share/flatpak/exports"
    ];

    # Shell aliases for AppImage apps
    programs.bash.shellAliases = lib.mkIf config.modules.flatpak.development.enable {
      bruno-appimage = "$HOME/.local/bin/bruno.AppImage";
    };
    
    programs.zsh.shellAliases = lib.mkIf config.modules.flatpak.development.enable {
      bruno-appimage = "$HOME/.local/bin/bruno.AppImage";
    };
  };
}