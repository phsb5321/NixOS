{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.waybar;
  user = config.modules.desktop.autoLogin.user;
in {
  options.modules.waybar.enable = mkEnableOption "Waybar configuration";

  config = mkIf (cfg.enable && config.modules.desktop.enable) {
    home-manager.users.${user} = {
      programs.waybar = {
        enable = true;
        systemd.enable = true;
        systemd.target = "hyprland-session.target";
        package = pkgs.waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
        });
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 32;
            spacing = 4;
            margin-top = 4;
            margin-bottom = 0;
            margin-left = 8;
            margin-right = 8;

            modules-left = [
              "hyprland/workspaces"
              "hyprland/window"
            ];
            modules-center = ["clock"];
            modules-right = [
              "tray"
              "network"
              "bluetooth"
              "pulseaudio"
              "battery"
            ];

            "hyprland/workspaces" = {
              format = "{icon}";
              on-click = "activate";
              sort-by-number = true;
              active-only = false;
              format-icons = {
                "1" = "一";
                "2" = "二";
                "3" = "三";
                "4" = "四";
                "5" = "五";
                "6" = "六";
                "7" = "七";
                "8" = "八";
                "9" = "九";
                "10" = "十";
              };
            };

            "clock" = {
              format = "{:%I:%M %p}";
              format-alt = "{:%Y-%m-%d}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
                format = {
                  months = "<span color='#ffead3'><b>{}</b></span>";
                  days = "<span color='#ecc6d9'><b>{}</b></span>";
                  weeks = "<span color='#99ffdd'><b>W{}</b></span>";
                  weekdays = "<span color='#ffcc66'><b>{}</b></span>";
                  today = "<span color='#ff6699'><b><u>{}</u></b></span>";
                };
              };
            };

            network = {
              format-wifi = "󰤨  {essid}";
              format-ethernet = "󰤨  Wired";
              tooltip-format = "{ifname} via {gwaddr}";
              format-linked = "{ifname} (No IP)";
              format-disconnected = "󰤭  Disconnected";
              format-alt = "{ifname}: {ipaddr}/{cidr}";
              on-click-right = "nm-connection-editor";
            };

            bluetooth = {
              format = "󰂯";
              format-disabled = "󰂲";
              format-connected = "󰂱 {device_alias}";
              tooltip-format = "{controller_alias}\t{controller_address}";
              tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
              tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
              on-click = "blueman-manager";
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = "󰝟";
              format-icons = {
                default = ["󰕿" "󰖀" "󰕾"];
                headphone = "󰋋";
                hands-free = "󰋎";
                headset = "󰋎";
                phone = "";
                portable = "";
                car = "";
              };
              on-click = "pavucontrol";
            };

            battery = {
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{icon} {capacity}%";
              format-charging = "󰂄 {capacity}%";
              format-plugged = "󱘖 {capacity}%";
              format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
              on-click = "";
              tooltip = true;
            };

            tray = {
              icon-size = 16;
              spacing = 8;
            };
          };
        };
        style = ''
          * {
            font-family: "JetBrainsMono Nerd Font";
            font-size: 13px;
            border: none;
            border-radius: 0;
          }

          window#waybar {
            background-color: rgba(26, 27, 38, 0.85);
            color: #cdd6f4;
            border-radius: 8px;
          }

          #workspaces button {
            padding: 0 4px;
            color: #6c7086;
            border-radius: 4px;
          }

          #workspaces button:hover {
            background: rgba(69, 71, 90, 0.4);
            color: #cdd6f4;
            border-radius: 4px;
          }

          #workspaces button.active {
            color: #cdd6f4;
            background: #89b4fa;
            border-radius: 4px;
          }

          #workspaces button.urgent {
            background: #f38ba8;
            color: #11111b;
            border-radius: 4px;
          }

          #clock,
          #battery,
          #pulseaudio,
          #network,
          #bluetooth,
          #tray {
            background-color: rgba(69, 71, 90, 0.4);
            padding: 0 8px;
            margin: 4px 0;
            border-radius: 4px;
          }
        '';
      };
    };
  };
}
