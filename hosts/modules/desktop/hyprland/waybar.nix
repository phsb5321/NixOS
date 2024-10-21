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
        settings = [{
          layer = "top";
          position = "top";
          height = 25;
          margin-left = 5;
          margin-right = 5;
          margin-top = 5;
          margin-bottom = 0;
          spacing = 1;

          modules-left = ["hyprland/workspaces" "river/tags" "tray"];
          modules-right = [
            "network"
            "cpu"
            "temperature"
            "backlight"
            "wireplumber"
            "clock"
            "custom/separator"
            "group/custom-group"
            "custom/separator"
            "custom/power"
          ];

          "group/custom-group" = {
            orientation = "horizontal";
            modules = [
              "idle_inhibitor"
              "custom/bluetooth"
              "custom/kdeconnect"
              "custom/wifi"
            ];
          };

          "hyprland/workspaces" = {
            on-click = "activate";
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "1" = "";
              "2" = "";
              "3" = "";
              "4" = "";
              "5" = "";
              "6" = "";
              "7" = "󰠮";
              "8" = "";
              "9" = "";
              "10" = "";
            };
          };

          "hyprland/window" = {
            format = "{}";
            separate-outputs = true;
          };

          "river/tags" = {
            num-tags = 7;
            tag-labels = ["󰈹" "" "" "" "" "" "󰠮" "" "" ""];
          };

          tray = {
            icon-size = 16;
            spacing = 5;
            show-passive-items = true;
          };

          clock = {
            interval = 60;
            format = "  {:%a %b %d    %I:%M %p}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            format-alt = "{:%Y-%m-%d %H:%M:%S  }";
          };

          temperature = {
            critical-threshold = 80;
            interval = 2;
            format = " {temperatureC:>2}°C";
            format-icons = ["" "" ""];
            on-click = "hyprctl dispatcher togglespecialworkspace monitor";
          };

          cpu = {
            interval = 2;
            format = " {usage:>2}%";
            tooltip = false;
            on-click = "hyprctl dispatcher togglespecialworkspace monitor";
          };

          memory = {
            interval = 2;
            format = " {:>2}%";
          };

          disk = {
            interval = 15;
            format = "󰋊 {percentage_used:>2}%";
          };

          backlight = {
            format = "{icon} {percent:>2}%";
            format-icons = ["" "" "" "" "" "" "" "" ""];
          };

          network = {
            interval = 1;
            format-wifi = "  {bandwidthTotalBytes:>2}";
            format-ethernet = "{ipaddr}/{cidr} ";
            tooltip-format-wifi = " {ipaddr} ({signalStrength}%)";
            tooltip-format = "{ifname} via {gwaddr} ";
            format-linked = "{ifname} (No IP) ";
            format-disconnected = "󰀦 Disconnected";
            format-alt = "{ifname}: {ipaddr}/{cidr}";
          };

          wireplumber = {
            format = "{icon} {volume:>3}%";
            format-muted = "󰖁 {volume:>3}%";
            format-icons = ["" "" ""];
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = "󰈈";
              deactivated = "󰈉";
            };
          };

          "custom/power" = {
            format = "{icon}";
            format-icons = " ";
            exec-on-event = true;
            on-click = "$HOME/scripts/rofi-power";
            tooltip-format = "Power Menu";
          };

          "custom/kdeconnect" = {
            format = "{icon}";
            format-icons = "";
            exec-on-event = true;
            on-click = "kdeconnect-app";
            tooltip-format = "KDE Connect";
          };

          "custom/bluetooth" = {
            format = "{icon}";
            format-icons = "";
            exec-on-event = true;
            on-click = "$HOME/scripts/rofi-bluetooth";
            tooltip-format = "Bluetooth Menu";
          };

          "custom/wifi" = {
            format = "{icon}";
            format-icons = "";
            exec-on-event = true;
            on-click = "$HOME/scripts/rofi-wifi";
            tooltip-format = "Wifi Menu";
          };

          "custom/separator" = {
            format = "{icon}";
            format-icons = "|";
            tooltip = false;
          };
        }];

        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
            font-size: 13px;
            min-height: 0;
          }

          window#waybar {
            background: rgba(21, 22, 30, 0.8);
            color: #cdd6f4;
          }

          #workspaces button {
            padding: 0 5px;
            background: transparent;
            color: #cdd6f4;
            border-bottom: 3px solid transparent;
          }

          #workspaces button.active {
            background: #64727D;
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
          #wireplumber,
          #custom-power,
          #tray,
          #mode {
            padding: 0 10px;
            margin: 0 5px;
            color: #cdd6f4;
          }

          #temperature.critical {
            color: #f38ba8;
          }

          @keyframes blink {
            to {
              background-color: #f38ba8;
              color: #181825;
            }
          }

          #battery.critical:not(.charging) {
            background-color: #f38ba8;
            color: #181825;
            animation-name: blink;
            animation-duration: 0.5s;
            animation-timing-function: linear;
            animation-iteration-count: infinite;
            animation-direction: alternate;
          }
        '';
      };

      home.packages = with pkgs; [
        font-awesome
      ];
    };
  };
}
