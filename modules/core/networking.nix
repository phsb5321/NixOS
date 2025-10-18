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
        # Additional settings for stability and IPv6 fixes
        settings = {
          main = {
            # Disable power management for all network interfaces
            no-auto-default = "*";
            # IPv6 stability settings to prevent routing conflicts
            dhcp = "internal";
          };
          connection = {
            # IPv6 privacy and stability settings
            "ipv6.ip6-privacy" = "0";  # Disable IPv6 privacy to prevent conflicts
            "ipv6.method" = "auto";
            "ipv6.may-fail" = "false";  # Ensure IPv6 configuration completes
          };
          ipv6 = {
            # Prevent IPv6 routing conflicts that cause disconnections
            "method" = "auto";
            "privacy" = "disabled";
          };
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
      path = with pkgs; [curl iproute2 coreutils networkmanager gnugrep];
      script = ''
        # Function to test connectivity with multiple retries (reduce false positives)
        test_connectivity() {
          local retries=3
          local success=0

          for i in $(seq 1 $retries); do
            # Test basic connectivity to multiple reliable servers with longer timeouts
            if curl -s --max-time 20 --connect-timeout 10 "http://www.google.com/generate_204" >/dev/null 2>&1 || \
               curl -s --max-time 20 --connect-timeout 10 "http://connectivitycheck.gstatic.com/generate_204" >/dev/null 2>&1 || \
               ping -c 3 8.8.8.8 >/dev/null 2>&1; then
              success=1
              break
            fi

            if [ "$i" -lt "$retries" ]; then
              echo "Connectivity test attempt $i/$retries failed, retrying in 30 seconds..."
              sleep 30
            fi
          done

          if [ "$success" -eq 1 ]; then
            return 0
          fi

          # Only log detailed diagnostics after multiple failures
          echo "Connectivity failed after $retries attempts with 30s delays. Running diagnostics..."
          return 1
        }

        # Function to fix IPv6 routing issues
        fix_ipv6_routing() {
          echo "Attempting to fix IPv6 routing issues..."

          # Clear problematic IPv6 routes
          ip -6 route flush table cache 2>/dev/null || true

          # Restart IPv6 on the interface
          echo 0 > /proc/sys/net/ipv6/conf/enp8s0/disable_ipv6 2>/dev/null || true
          echo 1 > /proc/sys/net/ipv6/conf/enp8s0/disable_ipv6 2>/dev/null || true
          sleep 2
          echo 0 > /proc/sys/net/ipv6/conf/enp8s0/disable_ipv6 2>/dev/null || true

          # Wait for IPv6 autoconfiguration
          sleep 5
        }

        # Main monitoring loop
        while true; do
          sleep 900  # Test every 15 minutes (much less aggressive)

          # Check physical cable connection first
          if [ -f /sys/class/net/enp8s0/carrier ] && [ "$(cat /sys/class/net/enp8s0/carrier)" != "1" ]; then
            echo "Physical cable disconnected on enp8s0"
            sleep 30  # Wait for potential reconnection
            continue
          fi

          if ! test_connectivity; then
            echo "Network connectivity confirmed lost after multiple retries. Attempting conservative recovery..."

            # First try IPv6 routing fix
            fix_ipv6_routing

            # Test again after IPv6 fix
            if test_connectivity; then
              echo "Network connectivity restored via IPv6 routing fix"
              continue
            fi

            # More conservative approach - only log, don't restart services aggressively
            echo "Connectivity still problematic. Logging status for manual review..."
            echo "Interface status:"
            ip addr show enp8s0 | head -10
            echo "IPv6 routes:"
            ip -6 route show | head -10
            echo "Device status:"
            nmcli device status

            # Wait longer before next test cycle
            echo "Waiting 5 minutes before next monitoring cycle..."
            sleep 300
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