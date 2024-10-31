# /hosts/modules/networking/options.nix
{lib, ...}:
with lib; {
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

    # DNS Configuration
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

    # Firewall Configuration
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
}
