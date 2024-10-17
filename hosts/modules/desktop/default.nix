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
        };

        # Enable greetd service
        greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
              user = "greeter";
            };
          } // (if cfg.autoLogin.enable then {
            initial_session = {
              command = "Hyprland";
              user = cfg.autoLogin.user;
            };
          } else { });
        };
      };

      # Environment variables for keyboard layout and Wayland compatibility
      environment.sessionVariables = {
        XKB_DEFAULT_LAYOUT = "br";
        XKB_DEFAULT_VARIANT = "";
        NIXOS_OZONE_WL = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
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
        xdg-desktop-portal-gtk
        mako
        swaylock
        greetd.tuigreet
        libsForQt5.qt5.qtwayland
        qt6.qtwayland
      ]);

      # Enable XDG portal
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Enable dbus
      services.dbus.enable = true;

      # Add user to necessary groups
      users.users.${cfg.autoLogin.user}.extraGroups = [ "seat" "video" "audio" "input" ];

      # Enable OpenGL
      hardware.opengl = {
        enable = true;
      };
    })
  ]);
}
