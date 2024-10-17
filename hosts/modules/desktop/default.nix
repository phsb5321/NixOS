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
      # Enable Hyprland
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };

      # Wayland-specific services
      services = {
        # For audio support
        pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
          jack.enable = true;
        };

        # Enable seat management
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

      # Environment variables for Wayland
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        WLR_NO_HARDWARE_CURSORS = "1";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GDK_BACKEND = "wayland,x11";
        QT_QPA_PLATFORM = "wayland;xcb";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
      };

      # Additional system packages required for Hyprland
      environment.systemPackages = with pkgs; [
        waybar
        wofi
        swww
        grim
        slurp
        wl-clipboard
        mako
        libnotify
        swaylock-effects
        wlogout
        hyprpaper
        xdg-desktop-portal-hyprland
        xdg-utils
        polkit-kde-agent
        networkmanagerapplet
      ] ++ cfg.extraPackages;

      # Enable XDG portal
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      # Enable dbus and polkit
      services.dbus.enable = true;
      security.polkit.enable = true;

      # Add user to necessary groups
      users.users.${cfg.autoLogin.user}.extraGroups = [ "video" "audio" "input" ];

      # Enable OpenGL
      hardware.opengl = {
        enable = true;
        driSupport32Bit = true;
      };

      # Enable fonts
      fonts.enableDefaultFonts = true;

      # Enable Bluetooth
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

      # Enable networking
      networking.networkmanager.enable = true;

      # Enable CUPS for printing
      services.printing.enable = true;

      # Enable sound
      security.rtkit.enable = true;

      # Configure PAM for swaylock
      security.pam.services.swaylock = {};
    })
  ]);
}
