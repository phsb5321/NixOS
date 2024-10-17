{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop;
in
{
  imports = [ ./options.nix ];

  config = mkIf cfg.enable (mkMerge [
    {
      services.xserver = {
        enable = true;
        layout = "br";
        xkb.variant = "";
      };

      environment.systemPackages = cfg.extraPackages;
    }

    (mkIf (cfg.environment == "gnome") {
      services.xserver = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
    })

    (mkIf (cfg.environment == "kde") {
      services.xserver = {
        displayManager.sddm.enable = true;
        desktopManager.plasma5.enable = true;
      };
    })

    (mkIf (cfg.environment == "hyprland") {
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      environment.systemPackages = with pkgs; [
        waybar
        swww
        wofi
      ];
    })

    (mkIf cfg.autoLogin.enable {
      services.xserver.displayManager.autoLogin = {
        enable = true;
        user = cfg.autoLogin.user;
      };
    })
  ]);
}
