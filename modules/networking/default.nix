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
  ##############################################################################
  # 1) Declare the `modules.networking` option namespace and all its settings
  ##############################################################################
  options.modules.networking = {
    enable = mkEnableOption "Enable the custom networking module";

    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "System hostname";
    };

    enableNetworkManager = mkOption {
      type = types.bool;
      default = true;
      description = "Use NetworkManager for all interface configuration";
    };

    optimizeTCP = mkOption {
      type = types.bool;
      default = true;
      description = "Enable TCP tuning sysctls";
    };

    dns = {
      enableSystemdResolved = mkOption {
        type = types.bool;
        default = true;
        description = "Run systemd-resolved stub on 127.0.0.53";
      };

      enableDNSOverTLS = mkOption {
        type = types.bool;
        default = true;
        description = "Have systemd-resolved use DNS-over-TLS";
      };

      primaryProvider = mkOption {
        type = types.enum ["cloudflare" "google" "quad9" "custom"];
        default = "cloudflare";
        description = "Which upstream DNS provider to use";
      };

      customNameservers = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "List of nameservers if primaryProvider = custom";
      };
    };

    firewall = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable basic stateful firewall";
      };

      allowPing = mkOption {
        type = types.bool;
        default = true;
        description = "Allow ICMP echo requests";
      };

      openPorts = mkOption {
        type = types.listOf types.int;
        default = [22];
        description = "TCP ports to open (e.g. SSH)";
      };

      trustedInterfaces = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Interfaces on which all traffic is allowed";
      };
    };
  };

  ########################################################
  # 2) Apply everything when modules.networking.enable = true
  ########################################################
  config = mkIf cfg.enable {
    # Hostname
    networking.hostName = cfg.hostName;

    # ———————————————————————————————————————
    # NetworkManager configuration
    # ———————————————————————————————————————
    networking.networkmanager = {
      enable = cfg.enableNetworkManager;
      dns = "none"; # let systemd-resolved handle DNS
      insertNameservers = selectedDNS; # prepend our static DNS
    };

    # Disable legacy DHCP clients and conflicting services
    networking.useDHCP = false;
    networking.dhcpcd.enable = false;
    networking.wireless.enable = false;

    # ———————————————————————————————————————
    # systemd-resolved stub resolver
    # ———————————————————————————————————————
    services.resolved = {
      enable = cfg.dns.enableSystemdResolved;
      dnssec = "allow-downgrade";
      fallbackDns = selectedDNS;
      extraConfig = ''
        DNSOverTLS=${
          if cfg.dns.enableDNSOverTLS
          then "yes"
          else "no"
        }
        Cache=yes
        DNSStubListener=yes
      '';
    };

    # ———————————————————————————————————————
    # Firewall
    # ———————————————————————————————————————
    networking.firewall = mkIf cfg.firewall.enable {
      enable = true;
      allowedTCPPorts = cfg.firewall.openPorts;
      allowPing = cfg.firewall.allowPing;
      trustedInterfaces = cfg.firewall.trustedInterfaces;
    };

    # ———————————————————————————————————————
    # TCP kernel tuning
    # ———————————————————————————————————————
    boot.kernel.sysctl = mkIf cfg.optimizeTCP {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.core.netdev_max_backlog" = 16384;
      "net.core.somaxconn" = 8192;
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
    };

    # ———————————————————————————————————————
    # Useful CLI tools for debugging
    # ———————————————————————————————————————
    environment.systemPackages = with pkgs; [
      networkmanager
      networkmanagerapplet # correct attribute name for the GNOME applet :contentReference[oaicite:0]{index=0}
      bind
      openssl
      curl
    ];

    # Ensure NetworkManager service is enabled
    systemd.services.NetworkManager.enable = true;
  };
}
