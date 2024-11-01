# ~/NixOS/hosts/modules/networking/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking;

  dnsProviders = {
    cloudflare = {
      primary = "1.1.1.1";
      secondary = "1.0.0.1";
    };
    google = {
      primary = "8.8.8.8";
      secondary = "8.8.4.4";
    };
    quad9 = {
      primary = "9.9.9.9";
      secondary = "149.112.112.112";
    };
  };

  selectedDNS =
    if cfg.dns.primaryProvider == "custom"
    then cfg.dns.customNameservers
    else [
      dnsProviders.${cfg.dns.primaryProvider}.primary
      dnsProviders.${cfg.dns.primaryProvider}.secondary
    ];
in {
  options.modules.networking = {
    enable = mkEnableOption "Networking module";

    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "System hostname";
    };

    useDHCP = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DHCP for network configuration";
    };

    optimizeTCP = mkOption {
      type = types.bool;
      default = true;
      description = "Enable TCP optimization settings";
    };

    enableNetworkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NetworkManager for network management";
    };

    dns = {
      enableSystemdResolved = mkOption {
        type = types.bool;
        default = true;
        description = "Enable systemd-resolved for DNS resolution";
      };

      enableDNSOverTLS = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DNS-over-TLS for secure DNS queries";
      };

      primaryProvider = mkOption {
        type = types.enum ["cloudflare" "google" "quad9" "custom"];
        default = "cloudflare";
        description = "Primary DNS provider to use";
      };

      customNameservers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of custom nameservers to use when primaryProvider is set to custom";
      };
    };

    firewall = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable firewall configuration";
      };

      allowPing = mkOption {
        type = types.bool;
        default = true;
        description = "Allow ICMP ping requests";
      };

      openPorts = mkOption {
        type = types.listOf types.int;
        default = [];
        description = "List of ports to open in the firewall";
      };

      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of trusted network interfaces";
      };
    };
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = cfg.hostName;
      # Use mkForce to resolve the conflict with NetworkManager
      useDHCP = lib.mkForce (cfg.useDHCP && !cfg.enableNetworkManager);

      # NetworkManager Configuration
      networkmanager = {
        enable = cfg.enableNetworkManager;
        dns = "systemd-resolved";
        wifi = {
          powersave = false;
          backend = "wpa_supplicant";
        };
      };

      # Wireless Configuration
      wireless = {
        enable = false; # Disable built-in wireless to prevent conflicts
        userControlled.enable = true;
      };

      # Firewall Configuration
      firewall = mkIf cfg.firewall.enable {
        enable = true;
        allowPing = cfg.firewall.allowPing;
        allowedTCPPorts = cfg.firewall.openPorts;
        allowedUDPPorts = cfg.firewall.openPorts;
        trustedInterfaces = cfg.firewall.trustedInterfaces;
      };

      # Name resolution configuration
      nameservers = selectedDNS;
    };

    # systemd-resolved Configuration
    services = {
      resolved = mkIf cfg.dns.enableSystemdResolved {
        enable = true;
        dnssec = "allow-downgrade";
        fallbackDns = selectedDNS;
        extraConfig = ''
          DNSOverTLS=${
            if cfg.dns.enableDNSOverTLS
            then "yes"
            else "no"
          }
          MulticastDNS=yes
          Cache=yes
          DNSStubListener=yes
        '';
      };
    };

    # Network Service Configuration
    systemd.services = {
      NetworkManager = mkIf cfg.enableNetworkManager {
        wantedBy = ["multi-user.target"];
        after = ["network.target"];
        serviceConfig = {
          Restart = "always";
          RestartSec = "5s";
        };
      };

      network-interfaces-up = {
        description = "Ensure network interfaces are up";
        after = ["network.target"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };
    };

    # TCP Optimization
    boot.kernel.sysctl = mkIf cfg.optimizeTCP {
      # IPv4 settings
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_fin_timeout" = 30;
      "net.ipv4.tcp_keepalive_time" = 120;
      "net.ipv4.tcp_max_syn_backlog" = 4096;
      "net.ipv4.tcp_rfc1337" = 1;
      "net.ipv4.ip_forward" = 1;

      # IPv6 settings
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;
      "net.ipv6.conf.all.forwarding" = 1;

      # General network settings
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.core.rmem_default" = 1048576;
      "net.core.wmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.optmem_max" = 65536;
    };

    # Required packages
    environment.systemPackages = with pkgs; [
      networkmanager
      networkmanagerapplet
      wpa_supplicant
      iw
      wirelesstools
    ];
  };
}
