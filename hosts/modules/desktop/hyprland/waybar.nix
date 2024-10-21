{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.waybar;
  user = config.modules.desktop.autoLogin.user;
  customStyle = ''
    * {
      font-family: "JetBrainsMono Nerd Font", "Fira Code Nerd Font", sans-serif;
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: rgba(30, 30, 46, 0.9);
      border-bottom: 2px solid rgba(137, 180, 250, 0.3);
      color: #cdd6f4;
      transition-property: background-color;
      transition-duration: 0.5s;
    }

    window#waybar.hidden {
      opacity: 0.2;
    }

    #workspaces {
      background-color: rgba(49, 50, 68, 0.5);
      border-radius: 10px;
      margin: 5px;
      padding: 0 5px;
    }

    #workspaces button {
      padding: 0 7px;
      background-color: transparent;
      color: #cdd6f4;
      border-radius: 8px;
      margin: 2px;
      transition: all 0.3s ease;
    }

    #workspaces button:hover {
      background: rgba(137, 180, 250, 0.2);
      box-shadow: inset 0 -3px rgba(137, 180, 250, 0.5);
    }

    #workspaces button.focused {
      background-color: #89b4fa;
      color: #1e1e2e;
      box-shadow: inset 0 -3px #cdd6f4;
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #temperature,
    #network,
    #pulseaudio,
    #custom-media,
    #tray,
    #mode,
    #window {
      padding: 0 10px;
      margin: 2px 4px;
      color: #cdd6f4;
      border-radius: 8px;
      background-color: rgba(49, 50, 68, 0.5);
    }

    #clock {
      background-color: rgba(137, 180, 250, 0.2);
    }

    #battery {
      background-color: rgba(166, 227, 161, 0.2);
    }

    #battery.charging, #battery.plugged {
      background-color: rgba(166, 227, 161, 0.5);
    }

    @keyframes blink {
      to {
        background-color: #f9e2af;
        color: #1e1e2e;
      }
    }

    #battery.critical:not(.charging) {
      background-color: #f38ba8;
      color: #1e1e2e;
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
    }

    #cpu {
      background-color: rgba(245, 194, 231, 0.2);
    }

    #memory {
      background-color: rgba(250, 179, 135, 0.2);
    }

    #temperature {
      background-color: rgba(249, 226, 175, 0.2);
    }

    #temperature.critical {
      background-color: #f38ba8;
    }

    #network {
      background-color: rgba(137, 220, 235, 0.2);
    }

    #network.disconnected {
      background-color: #f38ba8;
    }

    #pulseaudio {
      background-color: rgba(180, 190, 254, 0.2);
    }

    #pulseaudio.muted {
      background-color: rgba(249, 226, 175, 0.2);
    }

    #custom-media {
      background-color: rgba(249, 226, 175, 0.2);
    }

    #tray {
      background-color: rgba(205, 214, 244, 0.2);
    }

    #tray > .passive {
      -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
      -gtk-icon-effect: highlight;
      background-color: #f38ba8;
    }

    #window {
      font-weight: bold;
      background-color: rgba(137, 180, 250, 0.2);
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
          height = 34;
          spacing = 4;
          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "custom/media" "cpu" "memory" "temperature" "battery" "pulseaudio" "network" "tray" ];
          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "";
              urgent = "";
              focused = "";
              default = "";
            };
            on-scroll-up = "hyprctl dispatch workspace e+1";
            on-scroll-down = "hyprctl dispatch workspace e-1";
          };
          "hyprland/window" = {
            max-length = 50;
          };
          clock = {
            format = " {:%a %b %d  %H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };
          cpu = {
            format = " {usage}%";
            tooltip = false;
          };
          memory = {
            format = " {}%";
          };
          temperature = {
            critical-threshold = 80;
            format = "{icon} {temperatureC}°C";
            format-icons = ["" "" "" "" ""];
          };
          battery = {
            states = {
              good = 95;
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-alt = "{icon} {time}";
            format-icons = ["" "" "" "" ""];
          };
          network = {
            format-wifi = " {essid} ({signalStrength}%)";
            format-ethernet = " {ifname}";
            format-linked = " {ifname} (No IP)";
            format-disconnected = "⚠ Disconnected";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };
          pulseaudio = {
            format = "{icon} {volume}% {format_source}";
            format-bluetooth = "{icon} {volume}% {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = " {volume}%";
            format-source-muted = "";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" "" ""];
            };
            on-click = "pavucontrol";
          };
          "custom/media" = {
            format = "{icon} {}";
            return-type = "json";
            max-length = 40;
            format-icons = {
              spotify = "";
              default = "🎜";
            };
            escape = true;
            exec = "$HOME/.config/waybar/mediaplayer.py 2> /dev/null";
          };
          tray = {
            icon-size = 18;
            spacing = 10;
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
