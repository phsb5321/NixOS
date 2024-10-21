{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.waybar;
in {
  options.modules.waybar = {
    enable = mkEnableOption "Waybar configuration";
  };

  config = mkIf cfg.enable {
    home-manager.users.${config.modules.desktop.autoLogin.user} = { ... }: {
      programs.waybar = {
        enable = true;
        settings = [{
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" "hyprland/mode" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "cpu" "memory" "temperature" "backlight" "battery" "tray" ];
        }];
      };
    };
  };
}
