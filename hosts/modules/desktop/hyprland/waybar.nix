{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.waybar;
  user = config.modules.desktop.autoLogin.user;
  customStyle = ''
    * {
      font-family: "Fira Code Nerd Font", sans-serif;
      font-size: 12px;
      background-color: #1e1e2e;
      color: #cdd6f4;
    }

    #workspaces button {
      background-color: transparent;
      padding: 0 10px;
      margin: 0 5px;
      border-radius: 4px;
    }

    #workspaces button.focused {
      background-color: #89b4fa;
      color: #1e1e2e;
    }

    #clock {
      padding: 0 10px;
    }

    #pulseaudio, #network, #cpu, #memory, #temperature, #backlight, #battery, #tray {
      padding: 0 5px;
    }

    .module:hover {
      background-color: #45475a;
    }
  '';
in {
  options.modules.waybar = {
    enable = mkEnableOption "Waybar configuration";
  };

  config = mkIf (cfg.enable && config.modules.desktop.enable) {
    home-manager.users.${user} = { pkgs, ... }: {
      programs.waybar = {
        enable = true;
        style = customStyle;
        settings = [{
          layer = "top";
          position = "top";
          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "cpu" "memory" "temperature" "battery" "pulseaudio" "network" ];
          clock = {
            format = "{:%a %d %b %H:%M}";
          };
          battery = {
            format = "{capacity}%";
            format-icons = [ "" "" "" "" "" ];
          };
          cpu = {
            format = "CPU {usage}%";
          };
          memory = {
            format = "RAM {used}/{total} GB";
          };
          temperature = {
            format = "Temp {temperature}°C";
          };
          pulseaudio = {
            format = "Vol {volume}%";
          };
          network = {
            format-wifi = " {essid} {signalStrength}%";
            format-ethernet = " {ifname}";
          };
        }];
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
      };
    };
  };
}
