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
          alsa.support32Bit = true;
          pulse.enable = true;
          # Enable WirePlumber
          wireplumber.enable = true;
        };

        # Enable seat management
        seatd = {
          enable = true;
          group = "seatd";
        };

        # Enable greetd service
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.hyprland}/bin/Hyprland";
            };
          } // (if cfg.autoLogin.enable then {
            initial_session = {
              command = "${pkgs.hyprland}/bin/Hyprland";
              user = cfg.autoLogin.user;
            };
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
      ]);

      # Enable XDG portal
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Enable dbus
      services.dbus.enable = true;
    })
  ]);
}
