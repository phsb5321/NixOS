{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop;
in {
  config = mkIf (cfg.enable && cfg.environment == "hyprland") {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    services.greetd = {
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
    ];

    xdg.portal.wlr.enable = true;

    security.pam.services.swaylock = {};
  };
}
