# DNS Configuration Module - Tailscale-Compatible
# Handles DNS resolution with Tailscale conflict prevention
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.networking.dns;
in {
  options.modules.networking.dns = with lib; {
    enable = mkEnableOption "Enhanced DNS configuration";

    tailscaleCompatible = mkOption {
      type = types.bool;
      default = false;
      description = "Apply Tailscale-specific DNS optimizations";
    };

    primaryServers = mkOption {
      type = types.listOf types.str;
<<<<<<< HEAD
      default = [ "8.8.8.8" "8.8.4.4" ];
=======
      default = ["8.8.8.8" "8.8.4.4"];
>>>>>>> origin/host/server
      description = "Primary DNS servers";
    };

    fallbackServers = mkOption {
      type = types.listOf types.str;
<<<<<<< HEAD
      default = [ "1.1.1.1" "1.0.0.1" ];
=======
      default = ["1.1.1.1" "1.0.0.1"];
>>>>>>> origin/host/server
      description = "Fallback DNS servers";
    };

    enableDoT = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNS over TLS";
    };

    enableDnssec = mkOption {
      type = types.bool;
      default = true;
      description = "Enable DNSSEC validation";
    };

    healthCheck = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DNS health monitoring";
      };

      interval = mkOption {
        type = types.str;
        default = "*:0/5"; # Every 5 minutes
        description = "Health check interval (systemd calendar format)";
      };

      testDomains = mkOption {
        type = types.listOf types.str;
<<<<<<< HEAD
        default = [ "google.com" "github.com" "nixos.org" ];
=======
        default = ["google.com" "github.com" "nixos.org"];
>>>>>>> origin/host/server
        description = "Domains to test for DNS health checks";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # systemd-resolved configuration with Tailscale compatibility
    services.resolved = {
      enable = true;

      # DNS servers configuration
      fallbackDns = cfg.primaryServers ++ cfg.fallbackServers;

      # Security and performance settings
<<<<<<< HEAD
      dnssec = if cfg.enableDnssec then "allow-downgrade" else "false";
=======
      dnssec =
        if cfg.enableDnssec
        then "allow-downgrade"
        else "false";
>>>>>>> origin/host/server

      # Tailscale-compatible configuration
      extraConfig = ''
        # DNS resolution settings
        DNS=${lib.concatStringsSep " " (cfg.primaryServers ++ cfg.fallbackServers)}
        FallbackDNS=${lib.concatStringsSep " " cfg.fallbackServers}
        Domains=~.

        # Security settings
<<<<<<< HEAD
        DNSSEC=${if cfg.enableDnssec then "allow-downgrade" else "false"}
        DNSOverTLS=${if cfg.enableDoT then "yes" else "no"}
=======
        DNSSEC=${
          if cfg.enableDnssec
          then "allow-downgrade"
          else "false"
        }
        DNSOverTLS=${
          if cfg.enableDoT
          then "yes"
          else "no"
        }
>>>>>>> origin/host/server

        # Tailscale compatibility settings
        DNSStubListener=yes
        DNSStubListenerExtra=0.0.0.0
        Cache=yes

        # Prevent conflicts with Tailscale MagicDNS
        ReadEtcHosts=yes
        ResolveUnicastSingleLabel=yes
      '';
    };

    # DNS health monitoring system
    systemd.timers.dns-health-check = lib.mkIf cfg.healthCheck.enable {
<<<<<<< HEAD
      wantedBy = [ "timers.target" ];
      partOf = [ "dns-health-check.service" ];
      timerConfig = {
        OnCalendar = cfg.healthCheck.interval;
        Persistent = true;
        RandomizedDelaySec = "30s";  # Avoid thundering herd
=======
      wantedBy = ["timers.target"];
      partOf = ["dns-health-check.service"];
      timerConfig = {
        OnCalendar = cfg.healthCheck.interval;
        Persistent = true;
        RandomizedDelaySec = "30s"; # Avoid thundering herd
>>>>>>> origin/host/server
      };
    };

    systemd.services.dns-health-check = lib.mkIf cfg.healthCheck.enable {
      serviceConfig = {
        Type = "oneshot";
        User = "nobody";
        Group = "nogroup";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
      };

      script = ''
        # Test DNS resolution for multiple domains
        failed_domains=0
        total_domains=${toString (lib.length cfg.healthCheck.testDomains)}

        ${lib.concatMapStringsSep "\n" (domain: ''
<<<<<<< HEAD
          if ! ${pkgs.systemd}/bin/resolvectl query ${domain} >/dev/null 2>&1; then
            echo "DNS resolution failed for ${domain}"
            failed_domains=$((failed_domains + 1))
          fi
        '') cfg.healthCheck.testDomains}
=======
            if ! ${pkgs.systemd}/bin/resolvectl query ${domain} >/dev/null 2>&1; then
              echo "DNS resolution failed for ${domain}"
              failed_domains=$((failed_domains + 1))
            fi
          '')
          cfg.healthCheck.testDomains}
>>>>>>> origin/host/server

        # If more than half of domains fail, restart DNS services
        if [ "$failed_domains" -gt $((total_domains / 2)) ]; then
          echo "DNS health check failed ($failed_domains/$total_domains domains), triggering restart..."
          systemctl restart systemd-resolved
          sleep 2

          # Restart Tailscale if it's running and Tailscale compatibility is enabled
          ${lib.optionalString cfg.tailscaleCompatible ''
<<<<<<< HEAD
            if systemctl is-active --quiet tailscaled; then
              ${pkgs.tailscale}/bin/tailscale down && ${pkgs.tailscale}/bin/tailscale up
            fi
          ''}
=======
          if systemctl is-active --quiet tailscaled; then
            ${pkgs.tailscale}/bin/tailscale down && ${pkgs.tailscale}/bin/tailscale up
          fi
        ''}
>>>>>>> origin/host/server
        else
          echo "DNS health check passed ($((total_domains - failed_domains))/$total_domains domains working)"
        fi
      '';
    };

    # Resume commands for DNS recovery after suspend
    powerManagement.resumeCommands = lib.mkIf cfg.tailscaleCompatible ''
      # Restart DNS services after resume to prevent Tailscale conflicts
      ${pkgs.systemd}/bin/systemctl restart systemd-resolved
      sleep 2
      ${pkgs.systemd}/bin/systemctl restart NetworkManager

      # Cycle Tailscale if running
      if systemctl is-active --quiet tailscaled; then
        ${pkgs.tailscale}/bin/tailscale down && ${pkgs.tailscale}/bin/tailscale up
      fi
    '';

    # Network debugging tools
    environment.systemPackages = with pkgs; [
<<<<<<< HEAD
      dnsutils      # dig, nslookup
      bind          # DNS tools
      dogdns        # Modern DNS lookup tool
      q             # DNS query tool
    ];
  };
}
=======
      dnsutils # dig, nslookup
      bind # DNS tools
      dogdns # Modern DNS lookup tool
      q # DNS query tool
    ];
  };
}
>>>>>>> origin/host/server
