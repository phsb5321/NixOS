{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.waybar;
  user = config.modules.desktop.autoLogin.user;
  customStyle = ''
    * {
      font-family: "JetBrainsMono Nerd Font";
      font-size: 14px;
    }

    window#waybar {
      background: rgba(21, 22, 30, 0.8);
      border-bottom: 2px solid rgba(100, 114, 125, 0.5);
    }

    #workspaces button {
      padding: 0 5px;
      color: #7aa2f7;
      border-radius: 0;
    }

    #workspaces button.active {
      background: #7dcfff;
      color: #1a1b26;
    }

    #clock, #battery, #cpu, #memory, #network, #pulseaudio, #custom-spotify, #tray, #mode {
      padding: 0 10px;
      margin: 0 5px;
      color: #c0caf5;
    }

    #clock { background-color: #1a1b26; }
    #battery { background-color: #9ece6a; }
    #cpu { background-color: #f7768e; }
    #memory { background-color: #e0af68; }
    #network { background-color: #7aa2f7; }
    #pulseaudio { background-color: #ad8ee6; }
    #custom-spotify { background-color: #1db954; }
    #tray { background-color: #444b6a; }

    #battery.charging { color: #9ece6a; }
    #battery.warning:not(.charging) {
      background-color: #f7768e;
      color: #1a1b26;
      animation: blink 0.5s linear infinite alternate;
    }

    @keyframes blink {
      to { background-color: #ff9e64; }
    }
  '';
in {
  options.modules.waybar.enable = mkEnableOption "Waybar configuration";

  config = mkIf (cfg.enable && config.modules.desktop.enable) {
    home-manager.users.${user} = { pkgs, ... }: {
      programs.waybar = {
        enable = true;
        style = customStyle;
        settings = [{
          layer = "top";
          position = "top";
          modules-left = ["hyprland/workspaces" "custom/spotify"];
          modules-center = ["clock"];
          modules-right = ["cpu" "memory" "battery" "pulseaudio" "network" "tray"];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "";
              urgent = "";
              default = "";
            };
            on-click = "activate";
          };

          "clock" = {
            format = " {:%H:%M}";
            format-alt = " {:%Y-%m-%d}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          "cpu" = {
            format = " {usage}%";
            tooltip = false;
          };

          "memory" = {
            format = " {}%";
          };

          "battery" = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-icons = ["" "" "" "" ""];
          };

          "network" = {
            format-wifi = " {essid}";
            format-ethernet = " {ifname}";
            format-linked = " {ifname} (No IP)";
            format-disconnected = "⚠ Disconnected";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          "pulseaudio" = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%";
            format-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" ""];
            };
            on-click = "pavucontrol";
          };

          "custom/spotify" = {
            format = " {}";
            max-length = 40;
            exec = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null";
            exec-if = "pgrep spotify";
          };

          "tray" = {
            icon-size = 18,
            spacing = 10,
          };
        }];
      };
    };
  };
}
