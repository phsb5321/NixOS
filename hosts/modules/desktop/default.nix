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

        # Enable Wayland display manager
        seatd.enable = true;
        swaylock.enable = true; # For screen locking
      };

      # Use greetd as the login manager with wlgreet for Wayland
      services.greetd = {
        enable = true;
        greeter = {
          wlgreet = {
            enable = true;
          };
        };
        settings = {
          default_session = "hyprland";
        } // (mkIf cfg.autoLogin.enable {
          default_user = cfg.autoLogin.user;
          auto_login = true;
        });
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
      ]);
    })
  ]);
}