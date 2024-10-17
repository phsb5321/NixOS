{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable (mkMerge [

    # Common settings
    {
      services.xserver.enable = (cfg.environment != "hyprland");
      services.xserver.xkb = {
        layout = "br";
        variant = "";
      };

      environment.systemPackages = cfg.extraPackages;
    }

    # GNOME configuration
    (mkIf (cfg.environment == "gnome") {
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;

      # Auto-login for GDM
      services.xserver.displayManager.gdm.autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
    })

    # KDE configuration
    (mkIf (cfg.environment == "kde") {
      services.xserver.displayManager.sddm.enable = true;
      services.xserver.desktopManager.plasma5.enable = true;

      # Auto-login for SDDM
      services.displayManager.autoLogin = mkIf cfg.autoLogin.enable {
        enable = true;
        user = cfg.autoLogin.user;
      };
    })

    # Hyprland configuration
    (mkIf (cfg.environment == "hyprland") {
      # Disable X server as Hyprland is Wayland-based
      services.xserver.enable = false;

      # Enable Hyprland
      programs.hyprland = {
        enable = true;
        # You can add additional settings here if needed
      };

      # Enable required services
      services = {
        # For audio support
        pipewire = {
          enable = true;
          alsa.enable = true;
          pulse.enable = true;
        };
        wireplumber.enable = true;

        # Enable seat management
        seatd = {
          enable = true;
          group = "seatd";
        };

        # Enable screen locking
        swaylock.enable = true;

        # Enable greetd service
        greetd = {
          enable = true;
          settings = {
            greet = {
              command = "${pkgs.wlgreet}/bin/wlgreet";
            };
            default_session = "hyprland";
          } // (if cfg.autoLogin.enable then {
            default_user = cfg.autoLogin.user;
            auto_login = true;
          } else { });
        };
      };

      # Environment variables for keyboard layout
      environment.variables = {
        XKB_DEFAULT_LAYOUT = "br";
        XKB_DEFAULT_VARIANT = "";
      };

      # Additional system packages required for Hyprland
      environment.systemPackages = cfg.extraPackages ++ (with pkgs; [
        waybar
        wofi
        swww
        hyprpaper
        grim
        slurp
        wl-clipboard
        xdg-desktop-portal-wlr
        mako
        swaylock
        seatd
        wlgreet # Install wlgreet
      ]);
    })
  ]);
}
