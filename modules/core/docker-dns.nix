# modules/core/docker-dns.nix
# Docker with explicit DNS configuration and security hardening
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.core.dockerDns;
in {
  options.modules.core.dockerDns = {
    enable = lib.mkEnableOption "Docker with DNS configuration";
  };

  config = lib.mkIf cfg.enable {
    # Configure Docker with explicit DNS settings
    virtualisation.docker = {
      enable = true;

      # Use explicit command-line options to force DNS settings
      extraOptions = ''
        --dns=1.1.1.1 --dns=8.8.8.8 --dns=8.8.4.4
        --dns-opt=timeout:2 --dns-opt=attempts:5
        --mtu=1500
        --ip-forward=true
        --log-driver=journald
      '';

      # Declarative daemon.json (replaces imperative activationScript)
      daemon.settings = {
        dns = ["1.1.1.1" "8.8.8.8" "8.8.4.4"];
        dns-opts = ["timeout:2" "attempts:5"];
      };
    };

    # Ensure Docker is properly restarted and configured
    systemd.services.docker = {
      after = ["network-online.target"];
      wants = ["network-online.target"];

      # Force Docker to be restarted if the service fails
      serviceConfig = {
        Restart = "always";
        RestartSec = "5";
        StartLimitIntervalSec = "0";
      };
    };

    # Configure networking properly for Docker (nftables compatible)
    # NOTE: Ports 2375/2376 removed — Docker API should not be exposed (root-equivalent remote access)
    networking = {
      firewall = {
        allowPing = true;
        trustedInterfaces = ["docker0" "br-+"];
      };

      # Enable NAT for Docker (use mkDefault so hosts can override)
      nat.enable = lib.mkDefault true;
      nat.enableIPv6 = lib.mkDefault true;
    };

    # Add networking tools for troubleshooting
    environment.systemPackages = with pkgs; [
      dnsutils
      bridge-utils
      iproute2
      iputils
      iptables
    ];
  };
}
