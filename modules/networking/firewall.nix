# Firewall Configuration Module - Tailscale-Compatible
# Modern firewall setup with nftables and Tailscale integration
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.networking.firewall;
in {
  options.modules.networking.firewall = with lib; {
    enable = mkEnableOption "Enhanced firewall configuration";

    tailscaleCompatible = mkOption {
      type = types.bool;
      default = false;
      description = "Apply Tailscale-specific firewall optimizations";
    };

    useNftables = mkOption {
      type = types.bool;
      default = true;
      description = "Use nftables instead of iptables";
    };

    trustedNetworks = mkOption {
      type = types.listOf types.str;
      default = ["10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"];
      description = "Trusted private networks";
    };

    allowedServices = mkOption {
      type = types.listOf types.str;
      default = ["ssh"];
      description = "Services to allow through firewall (ssh, http, https, vnc, rdp)";
    };

    developmentPorts = mkOption {
      type = types.listOf types.int;
      default = [3000 3001 8080 8000];
      description = "Development server ports to open";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enhanced firewall configuration
    networking.firewall = {
      enable = true;

      # Use nftables for better performance and Tailscale compatibility
      # nftables works better with containerized workloads and VPNs

      # Tailscale compatibility settings
      checkReversePath = lib.mkIf cfg.tailscaleCompatible "loose";

      # Allow common services
      allowedTCPPorts =
        lib.optionals (lib.elem "ssh" cfg.allowedServices) [22]
        ++ lib.optionals (lib.elem "http" cfg.allowedServices) [80]
        ++ lib.optionals (lib.elem "https" cfg.allowedServices) [443]
        ++ lib.optionals (lib.elem "vnc" cfg.allowedServices) [5900 5901] # VNC ports
        ++ lib.optionals (lib.elem "rdp" cfg.allowedServices) [3389] # RDP port
        ++ cfg.developmentPorts;

      allowedUDPPorts = [
        # mDNS for service discovery
        5353
      ];

      # Trust Tailscale and common container interfaces
      trustedInterfaces = lib.mkIf cfg.tailscaleCompatible [
        "tailscale0"
        "docker0"
        "br-+" # Docker bridge networks
        "lo" # Loopback
      ];

      # Allow ping for network diagnostics
      allowPing = true;

      # Tailscale-specific rules (only for iptables, not nftables)
      extraCommands = lib.mkIf (cfg.tailscaleCompatible && !cfg.useNftables) ''
        # Allow Tailscale mesh traffic
        iptables -A INPUT -i tailscale0 -j ACCEPT
        iptables -A OUTPUT -o tailscale0 -j ACCEPT

        # Allow forwarding between Tailscale and local networks
        iptables -A FORWARD -i tailscale0 -j ACCEPT
        iptables -A FORWARD -o tailscale0 -j ACCEPT

        # Allow established and related connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
      '';

      extraStopCommands = lib.mkIf (cfg.tailscaleCompatible && !cfg.useNftables) ''
        # Clean up Tailscale rules
        iptables -D INPUT -i tailscale0 -j ACCEPT 2>/dev/null || true
        iptables -D OUTPUT -o tailscale0 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -i tailscale0 -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -o tailscale0 -j ACCEPT 2>/dev/null || true
      '';
    };

    # Enable nftables when requested
    networking.nftables = lib.mkIf cfg.useNftables {
      enable = true;

      # Basic nftables ruleset
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority filter;

            # Allow loopback
            iifname "lo" accept

            ${lib.optionalString cfg.tailscaleCompatible ''
          # Allow Tailscale
          iifname "tailscale0" accept
        ''}

            # Allow established and related connections
            ct state {established, related} accept

            # Allow ICMP
            icmp type echo-request accept
            icmpv6 type echo-request accept

            # Default policy
            policy drop;
          }

          chain forward {
            type filter hook forward priority filter;

            ${lib.optionalString cfg.tailscaleCompatible ''
          # Allow Tailscale forwarding
          iifname "tailscale0" accept
          oifname "tailscale0" accept
        ''}

            # Allow established and related
            ct state {established, related} accept

            policy drop;
          }

          chain output {
            type filter hook output priority filter;
            policy accept;
          }
        }
      '';
    };

    # Additional packages for firewall management
    environment.systemPackages = with pkgs; [
      # Firewall tools
      iptables
      nftables

      # Network analysis
      inetutils # provides network utilities
      iproute2 # provides ss
      lsof

      # Traffic monitoring
      vnstat
      iftop
    ];

    # Log firewall events for debugging
    networking.firewall.logRefusedConnections = lib.mkDefault false;
    networking.firewall.logRefusedPackets = lib.mkDefault false;
  };
}
