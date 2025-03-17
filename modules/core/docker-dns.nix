# modules/core/docker-dns.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Configure Docker with explicit DNS settings
  virtualisation.docker = {
    enable = true;

    # Use explicit command-line options to force DNS settings
    extraOptions = ''
      --dns=1.1.1.1 --dns=8.8.8.8 --dns=8.8.4.4
      --dns-opt=timeout:2 --dns-opt=attempts:5
      --mtu=1500
      --ip-forward=true
      --iptables=true
      --log-driver=journald
    '';
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

  # Configure networking properly for Docker
  networking = {
    # Consolidated firewall configuration
    firewall = {
      allowPing = true;
      trustedInterfaces = ["docker0" "br-+"];
      allowedTCPPorts = [2375 2376]; # Docker daemon ports
      extraCommands = ''
        # Allow established connections from Docker containers
        iptables -A INPUT -i docker0 -j ACCEPT
        iptables -A FORWARD -i docker0 -j ACCEPT
        iptables -A FORWARD -o docker0 -j ACCEPT

        # Ensure Docker containers can resolve DNS
        iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -p udp --sport 53 -j ACCEPT
      '';
    };

    # Enable NAT for Docker
    nat.enable = true;
    nat.enableIPv6 = true;
  };

  # Add networking tools for troubleshooting
  environment.systemPackages = with pkgs; [
    dnsutils
    bridge-utils
    iproute2
    iputils
    iptables
  ];

  # Create configuration directory for Docker
  system.activationScripts.dockerDnsSetup = {
    text = ''
      mkdir -p /etc/docker
      echo '{"dns": ["1.1.1.1", "8.8.8.8", "8.8.4.4"], "dns-opts": ["timeout:2", "attempts:5"]}' > /etc/docker/daemon.json
    '';
    deps = [];
  };
}
