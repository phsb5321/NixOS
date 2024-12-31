# /home/notroot/NixOS/hosts/modules/desktop/hyprland/ags.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop;
  user = cfg.autoLogin.user;
in {
  config = mkIf (cfg.enable && cfg.environment == "hyprland") {
    environment.systemPackages = with pkgs; [
      # Core AGS dependencies
      ags
      gjs
      gtk3
      gtk4
      libgtop
      libsoup_3
      webkitgtk_6_0
      accountsservice
      glib
      brightnessctl
      playerctl
      pavucontrol
      adwaita-icon-theme
      gnome-bluetooth
      bluez
      networkmanager
      networkmanagerapplet
      sassc
      jq
      socat
      systemd
      matugen
    ];

    # Required services
    services = {
      upower.enable = true;
      accounts-daemon.enable = true;
      gnome.gnome-keyring.enable = true;
      power-profiles-daemon.enable = true;
    };

    # Enable DBus and GSettings
    programs.dconf.enable = true;

    # Home manager configuration
    home-manager.users.${user} = {
      pkgs,
      config,
      ...
    }: {
      xdg.configFile."ags/config.js".text = ''
        const { GLib } = imports.gi;

        // Utility function to fetch stats
        const fetchStat = async (cmd, parser) => {
            const output = await Utils.execAsync(cmd);
            return parser(output);
        };

        const createWorkspaceButtons = () => {
          const buttons = [];
          for (let i = 0; i < 10; i++) {
            const wsNum = i + 1;
            buttons.push(Widget.Button({
              class_name: 'workspace-btn',
              on_clicked: () => Utils.execAsync(['hyprctl', 'dispatch', 'workspace', wsNum.toString()]),
              child: Widget.Label(wsNum.toString()),
              setup: self => self.poll(500, async () => {
                const output = await Utils.execAsync(['hyprctl', 'activeworkspace', '-j']);
                const active = JSON.parse(output).id;
                self.toggleClassName('active', active === wsNum);
              }),
            }));
          }
          return buttons;
        };

        const Workspaces = () => Widget.Box({
          class_name: 'workspaces',
          children: createWorkspaceButtons(),
        });

        const Clock = () => Widget.Label({
          class_name: 'clock',
          setup: self => self.poll(1000, self => {
            const time = GLib.DateTime.new_now_local();
            self.label = time.format('%H:%M:%S');
          }),
        });

        const CpuStat = () => Widget.CircularProgress({
          class_name: 'cpu',
          setup: self => self.poll(2000, async () => {
            const parser = (output) => {
              const usageLine = output.split('\n').find(line => line.includes('Cpu(s)'));
              const usage = parseFloat(usageLine.match(/(\d+\.\d+)/)[1]);
              return usage / 100;
            };
            self.value = await fetchStat('top -bn1', parser);
          }),
        });

        const RamStat = () => Widget.CircularProgress({
          class_name: 'ram',
          setup: self => self.poll(2000, async () => {
            const parser = (output) => {
              const values = output.split('\n')[1].split(/\s+/).map(Number);
              return values[2] / values[1];
            };
            self.value = await fetchStat('free', parser);
          }),
        });

        const DiskStat = () => Widget.Label({
          class_name: 'disk',
          setup: self => self.poll(3000, async () => {
            const parser = (output) => {
              const rootLine = output.split('\n').find(line => line.includes('/'));
              return rootLine.split(/\s+/)[4]; // Assuming the percentage is in the 5th field
            };
            self.label = "Disk: " + await fetchStat('df -h /', parser); // Concatenate with +
          }),
        });

        const BatteryStat = () => Widget.Label({
          class_name: 'battery',
          setup: self => self.poll(5000, async () => {
            const parser = (output) => {
              const batteryLine = output.split('\n')[1];
              return batteryLine.split(/\s+/)[3]; // Adjust accordingly
            };
            self.label = "Battery: " + await fetchStat('upower -i /org/freedesktop/UPower/devices/battery_BAT0', parser); // Concatenate with +
          }),
        });

        const NetworkStat = () => Widget.Label({
          class_name: 'network',
          setup: self => self.poll(5000, async () => {
            const parser = (output) => {
              const line = output.split('\n').find(line => line.includes('wlp3s0')); // Adjust interface name
              return line ? 'Connected' : 'Disconnected';
            };
            self.label = "Network: " + await fetchStat('nmcli -t -f DEVICE,STATE device', parser); // Concatenate with +
          }),
        });

        const SysInfo = () => Widget.Box({
          class_name: 'sysinfo',
          children: [
            CpuStat(),
            RamStat(),
            DiskStat(),
            BatteryStat(),
            NetworkStat(),
          ],
        });

        const Bar = () => Widget.Window({
          name: 'bar',
          class_name: 'bar',
          monitor: 0,
          anchor: ['top', 'left', 'right'],
          exclusivity: 'exclusive',
          child: Widget.CenterBox({
            class_name: 'panel',
            start_widget: Workspaces(),
            center_widget: Clock(),
            end_widget: SysInfo(),
          }),
        });

        const scss = `
          * {
            font-family: 'JetBrainsMono Nerd Font', monospace;
            font-size: 13px;
          }

          .bar {
            background-color: #282828; /* GruvBox bg0_h */
            color: #ebdbb2; /* GruvBox fg */
            padding: 8px;
            border-bottom: 2px solid #504945; /* GruvBox bg4 */
          }

          .panel {
            display: flex;
            align-items: center;
            justify-content: space-between;
            min-height: 30px;
          }

          .workspaces button {
            padding: 4px 8px;
            margin: 0 2px;
            border-radius: 4px;
            background: #3c3836; /* GruvBox bg3 */
            color: #d5c4a1; /* GruvBox fg4 */
            transition: background 0.3s, color 0.3s;

            &.active {
              background: #458588; /* GruvBox blue */
              color: #282828; /* GruvBox bg0_h */
            }

            &:hover {
              background: #504945; /* GruvBox bg4 */
              color: #ebdbb2; /* GruvBox fg */
            }
          }

          .clock {
            background: #3c3836; /* GruvBox bg3 */
            padding: 4px 12px;
            border-radius: 4px;
            text-align: center;
          }

          .sysinfo circular-progress {
            background: #3c3836; /* GruvBox bg3 */
            min-height: 24px;
            min-width: 24px;
            margin: 0 6px;
            padding: 4px;
            border-radius: 4px;
            color: #458588; /* GruvBox blue */

            &.cpu { color: #cc241d; /* GruvBox red */ }
            &.ram { color: #98971a; /* GruvBox green */ }
          }

          .disk, .battery, .network {
            padding: 4px 8px;
            margin: 0 4px;
            border-radius: 4px;
            background: #3c3836; /* GruvBox bg3 */
            color: #d5c4a1; /* GruvBox fg4 */
          }
        `;

        export default {
          style: scss,
          windows: [Bar()],
        };
      '';

      systemd.user.services.ags = {
        Unit = {
          Description = "Aylur's GTK Shell";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target" "hyprland-session.target"];
        };
        Service = {
          Environment = [
            "PATH=/run/current-system/sw/bin:${config.home.profileDirectory}/bin"
            "GI_TYPELIB_PATH=/run/current-system/sw/lib/girepository-1.0"
          ];
          ExecStart = "${pkgs.ags}/bin/ags";
          ExecReload = "${pkgs.ags}/bin/ags -r";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install = {
          WantedBy = ["hyprland-session.target"];
        };
      };

      # GTK theme settings
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      # Environment variables
      home.sessionVariables = {
        GTK_THEME = "adw-gtk3-dark";
        AGS_DEBUG = "1";
      };
    };
  };
}
