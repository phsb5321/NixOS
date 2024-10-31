# /hosts/modules/networking/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking;

  # DNS provider configurations
  dnsProviders = {
    cloudflare = {
      primary = "1.1.1.1#one.one.one.one";
      secondary = "1.0.0.1#one.one.one.one";
    };
    google = {
      primary = "8.8.8.8#dns.google";
      secondary = "8.8.4.4#dns.google";
    };
    quad9 = {
      primary = "9.9.9.9#dns.quad9.net";
      secondary = "149.112.112.112#dns.quad9.net";
    };
  };

  selectedDNS =
    if cfg.dns.primaryProvider == "custom"
    then cfg.dns.customNameservers
    else [
      dnsProviders.${cfg.dns.primaryProvider}.primary
      dnsProviders.${cfg.dns.primaryProvider}.secondary
      # Add fallback DNS servers from other providers
      dnsProviders.cloudflare.primary
      dnsProviders.google.primary
      dnsProviders.quad9.primary
    ];
in {
  imports = [./options.nix];

  config = mkIf cfg.enable {
    networking = {
      hostName = cfg.hostName;
      useDHCP = cfg.useDHCP;

      # NetworkManager Configuration
      networkmanager = mkIf cfg.enableNetworkManager {
        enable = true;
        dns = "systemd-resolved"; # Use systemd-resolved for better DNS handling
        wifi = {
          powersave = false; # Disable power management for better stability
          backend = "iwd"; # Use iwd backend for better WiFi performance
        };
      };

      # Firewall Configuration
      firewall = mkIf cfg.firewall.enable {
        enable = true;
        allowPing = cfg.firewall.allowPing;
        allowedTCPPorts = cfg.firewall.openPorts;
        allowedUDPPorts = cfg.firewall.openPorts;
        trustedInterfaces = cfg.firewall.trustedInterfaces;
      };
    };

    # systemd-resolved Configuration
    services.resolved = mkIf cfg.dns.enableSystemdResolved {
      enable = true;
      dnssec = "true";
      domains = ["~."];
      fallbackDns = selectedDNS;
      extraConfig = ''
        DNS=${concatStringsSep " " selectedDNS}
        ${optionalString cfg.dns.enableDNSOverTLS "DNSOverTLS=yes"}
        Cache=yes
        DNSStubListener=yes
        MulticastDNS=yes
      '';
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

      # IPv6 settings
      "net.ipv6.conf.all.accept_ra" = 2;
      "net.ipv6.conf.default.accept_ra" = 2;

      # General network settings
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.core.rmem_default" = 1048576;
      "net.core.wmem_default" = 1048576;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.core.optmem_max" = 65536;
    };

    # Additional network optimization services
    systemd.services.network-optimization = {
      description = "Network Optimization Service";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c '\
          ${pkgs.iproute2}/bin/tc qdisc add dev eth0 root fq_codel || true; \
          ${pkgs.iproute2}/bin/tc qdisc add dev wlan0 root fq_codel || true; \
        '";
      };
    };
  };
}
