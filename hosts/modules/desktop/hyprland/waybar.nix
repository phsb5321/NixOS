{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.waybar;
in {
  options.modules.waybar = {
    enable = mkEnableOption "Waybar configuration";
  };

  config = mkIf (cfg.enable && config.modules.desktop.enable) {
    home-manager.users.${config.modules.desktop.autoLogin.user} = { pkgs, ... }: {
      programs.waybar = {
        enable = true;
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: rgba(21, 22, 30, 0.9);
            color: #cdd6f4;
            border-radius: 0px 0px 10px 10px;
            transition-property: background-color;
            transition-duration: .5s;
          }

          #workspaces button {
            padding: 0 5px;
            background-color: transparent;
            color: #cdd6f4;
            border-bottom: 3px solid transparent;
          }

          #workspaces button:hover {
            background: rgba(0, 0, 0, 0.2);
            box-shadow: inherit;
            border-bottom: 3px solid #cdd6f4;
          }

          #workspaces button.active {
            background-color: #64727D;
            border-bottom: 3px solid #f38ba8;
          }

          #clock,
          #battery,
          #cpu,
          #memory,
          #disk,
          #temperature,
          #backlight,
          #network,
          #pulseaudio,
          #custom-media,
          #tray,
          #mode,
          #idle_inhibitor,
          #custom-power,
          #custom-spotify {
            padding: 0 10px;
            margin: 0 5px;
            color: #cdd6f4;
            border-radius: 10px;
          }

          #clock {
            background-color: #1e1e2e;
          }

          #battery {
            background-color: #1e1e2e;
            color: #a6e3a1;
          }

          #battery.charging, #battery.plugged {
            color: #a6e3a1;
            background-color: #26A65B;
          }

          @keyframes blink {
            to {
              background-color: #f38ba8;
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
            background-color: #1e1e2e;
            color: #f38ba8;
          }

          #memory {
            background-color: #1e1e2e;
            color: #fab387;
          }

          #disk {
            background-color: #1e1e2e;
            color: #89b4fa;
          }

          #backlight {
            background-color: #1e1e2e;
            color: #f9e2af;
          }

          #network {
            background-color: #1e1e2e;
            color: #94e2d5;
          }

          #network.disconnected {
            background-color: #f38ba8;
            color: #1e1e2e;
          }

          #pulseaudio {
            background-color: #1e1e2e;
            color: #89b4fa;
          }

          #pulseaudio.muted {
            background-color: #f38ba8;
            color: #1e1e2e;
          }

          #custom-media {
            background-color: #1e1e2e;
            color: #a6e3a1;
          }

          #custom-power {
            background-color: #1e1e2e;
            color: #f38ba8;
          }

          #custom-spotify {
            background-color: #1e1e2e;
            color: #a6e3a1;
          }
        '';
        settings = [{
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;
          modules-left = [
            "custom/launcher"
            "hyprland/workspaces"
            "custom/media"
          ];
          modules-center = [
            "clock"
          ];
          modules-right = [
            "idle_inhibitor"
            "pulseaudio"
            "network"
            "cpu"
            "memory"
            "temperature"
            "backlight"
            "battery"
            "custom/power"
            "tray"
          ];

          "hyprland/workspaces" = {
            disable-scroll = true;
            all-outputs = true;
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
          };

          "custom/launcher" = {
            format = " ";
            on-click = "wofi --show drun";
            tooltip = false;
          };

          "custom/power" = {
            format = "襤";
            on-click = "wlogout";
            tooltip = false;
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "";
              deactivated = "";
            };
          };

          clock = {
            format = " {:%H:%M}";
            format-alt = " {:%A, %B %d, %Y (%R)}";
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "right";
              on-scroll = 1;
              on-click-right = "mode";
              format = {
                months = "<span color='#ffead3'><b>{}</b></span>";
                days = "<span color='#ecc6d9'><b>{}</b></span>";
                weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                today = "<span color='#ff6699'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-click-forward = "tz_up";
              on-click-backward = "tz_down";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };

          cpu = {
            format = "{usage}% ";
            tooltip = false;
          };

          memory = {
            format = "{}% ";
          };

          temperature = {
            critical-threshold = 80;
            format = "{temperatureC}°C {icon}";
            format-icons = ["" "" ""];
          };

          backlight = {
            format = "{percent}% {icon}";
            format-icons = ["" "" "" "" "" "" "" "" ""];
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{capacity}% {icon}";
            format-charging = "{capacity}% ";
            format-plugged = "{capacity}% ";
            format-alt = "{time} {icon}";
            format-icons = ["" "" "" "" ""];
          };

          network = {
            format-wifi = "{essid} ({signalStrength}%) ";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "Disconnected ⚠";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          pulseaudio = {
            format = "{volume}% {icon} {format_source}";
            format-bluetooth = "{volume}% {icon} {format_source}";
            format-bluetooth-muted = " {icon} {format_source}";
            format-muted = " {format_source}";
            format-source = "{volume}% ";
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
        }];
      };

      # Install additional packages for Waybar
      home.packages = with pkgs; [
        font-awesome
        pavucontrol
      ];

      # Create a custom script for media player information
      home.file.".config/waybar/mediaplayer.py".source = pkgs.writeScript "mediaplayer.py" ''
        #!/usr/bin/env python3
        import json
        import subprocess
        import sys

        try:
            output = subprocess.check_output(["playerctl", "metadata", "--format", '{"text": "{{artist}} - {{title}}", "tooltip": "{{playerName}} : {{artist}} - {{title}} ({{album}})", "alt": "{{status}}", "class": "{{status}}"}'], stderr=subprocess.STDOUT)
            print(output.decode("utf-8").strip())
        except subprocess.CalledProcessError:
            print(json.dumps({"text": "No media", "class": "stopped"}))
      '';
    };
  };
}
