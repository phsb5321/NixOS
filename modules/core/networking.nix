# ~/NixOS/modules/core/networking.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.networking;
in {
  options.modules.core.networking = with lib; {
    enable = mkEnableOption "Enhanced networking configuration with power management fixes";

    preventIdleDisconnection = mkOption {
      type = types.bool;
      default = true;
      description = "Prevent network interfaces from being suspended during idle periods";
    };

    interfaces = mkOption {
      type = with types; listOf str;
      default = ["enp8s0" "wlp9s0"]; # Common interface patterns
      description = "Network interfaces to configure power management for";
    };
  };

  config = lib.mkIf cfg.enable {
    # NetworkManager configuration to prevent idle suspension
    networking = {
      networkmanager = {
        enable = true;
        # Prevent NetworkManager from suspending devices
        wifi.powersave = false;
        # Additional settings for stability
        settings = {
          main = {
            # Disable power management for all network interfaces
            no-auto-default = "*";
          };
          # Note: IPv6 and LLDP settings should be configured per-connection, not globally
        };
      };
    };

    # Systemd service to disable power management on network interfaces
    systemd.services.disable-network-power-management = lib.mkIf cfg.preventIdleDisconnection {
      description = "Disable power management on network interfaces to prevent idle disconnection";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "NetworkManager.service"];
      path = with pkgs; [utillinux gnugrep coreutils];
      script = ''
        # Function to disable power management for an interface
        disable_power_mgmt() {
          local interface="$1"
          local power_file="/sys/class/net/$interface/device/power/control"

          if [ -f "$power_file" ]; then
            echo "Disabling power management for $interface"
            echo "on" > "$power_file" 2>/dev/null || true
          fi
        }

        # Disable power management for specified interfaces
        ${lib.concatMapStringsSep "\n" (iface: ''
          disable_power_mgmt "${iface}"
        '') cfg.interfaces}

        # Also check for any active network interfaces
        for iface in $(ls /sys/class/net/ 2>/dev/null | grep -E '^(en|wl|eth|wlan)'); do
          disable_power_mgmt "$iface"
        done

        echo "Network interface power management configuration completed"
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
    };

    # Udev rules to prevent power management on network interfaces
    services.udev.extraRules = lib.mkIf cfg.preventIdleDisconnection ''
      # Disable power management for network interfaces to prevent idle disconnection
      SUBSYSTEM=="net", ACTION=="add", KERNEL=="en*", RUN+="${pkgs.bash}/bin/bash -c 'echo on > /sys$devpath/device/power/control'"
      SUBSYSTEM=="net", ACTION=="add", KERNEL=="wl*", RUN+="${pkgs.bash}/bin/bash -c 'echo on > /sys$devpath/device/power/control'"
      SUBSYSTEM=="net", ACTION=="add", KERNEL=="eth*", RUN+="${pkgs.bash}/bin/bash -c 'echo on > /sys$devpath/device/power/control'"
      SUBSYSTEM=="net", ACTION=="add", KERNEL=="wlan*", RUN+="${pkgs.bash}/bin/bash -c 'echo on > /sys$devpath/device/power/control'"
    '';

    # Additional kernel parameters to improve network stability
    boot.kernel.sysctl = {
      # Prevent network timeouts during idle periods
      "net.ipv4.tcp_keepalive_time" = lib.mkDefault 600;
      "net.ipv4.tcp_keepalive_probes" = lib.mkDefault 3;
      "net.ipv4.tcp_keepalive_intvl" = lib.mkDefault 90;
      # Improve network performance and stability (don't override core setting)
      "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";
    };

    # Network connectivity monitoring service
    systemd.services.network-keepalive = lib.mkIf cfg.preventIdleDisconnection {
      description = "Network connectivity keepalive to prevent idle timeouts";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = with pkgs; [curl iproute2 coreutils];
      script = ''
        # Function to test connectivity
        test_connectivity() {
          # Test basic connectivity to multiple reliable servers
          curl -s --max-time 10 --connect-timeout 5 "http://www.google.com/generate_204" >/dev/null 2>&1 || \
          curl -s --max-time 10 --connect-timeout 5 "http://detectportal.firefox.com/canonical.html" >/dev/null 2>&1 || \
          curl -s --max-time 10 --connect-timeout 5 "http://connectivitycheck.gstatic.com/generate_204" >/dev/null 2>&1
        }

        # Main monitoring loop
        while true; do
          sleep 300  # Test every 5 minutes

          if ! test_connectivity; then
            echo "Network connectivity lost, attempting to restore..."

            # Reset network interface
            ip link set enp8s0 down 2>/dev/null || true
            sleep 2
            ip link set enp8s0 up 2>/dev/null || true

            # Wait and test again
            sleep 10

            if test_connectivity; then
              echo "Network connectivity restored"
            else
              echo "Network connectivity still lost, restarting NetworkManager"
              systemctl restart NetworkManager
            fi
          fi
        done
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "30";
        User = "root";
      };
    };

    # System packages for network debugging
    environment.systemPackages = with pkgs; [
      ethtool
      iftop
      nethogs
      tcpdump
      mtr
      networkmanager
      curl
    ];
  };
}