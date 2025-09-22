# Tailscale VPN Configuration Module
# Modern NixOS 25+ implementation for secure mesh networking
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.networking.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN service";

    useRoutingFeatures = lib.mkOption {
      type = lib.types.enum ["none" "client" "server" "both"];
      default = "client";
      description = ''
        Enable Tailscale routing features:
        - none: Basic Tailscale connectivity only
        - client: Can use subnet routes and exit nodes
        - server: Can advertise routes and act as exit node
        - both: Full routing capabilities
      '';
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 41641;
      description = "UDP port for Tailscale";
    };

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "tailscale0";
      description = "Tailscale interface name";
    };

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing Tailscale auth key";
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra flags to pass to tailscale up command";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall for Tailscale traffic";
    };
  };

  config = lib.mkIf config.modules.networking.tailscale.enable {
    # Enable Tailscale service
    services.tailscale = {
      enable = true;
      useRoutingFeatures = config.modules.networking.tailscale.useRoutingFeatures;
      port = config.modules.networking.tailscale.port;
      interfaceName = config.modules.networking.tailscale.interfaceName;
      authKeyFile = config.modules.networking.tailscale.authKeyFile;
      extraUpFlags = config.modules.networking.tailscale.extraUpFlags;
      openFirewall = config.modules.networking.tailscale.openFirewall;
    };

    # Firewall configuration for Tailscale
    networking.firewall = lib.mkIf config.modules.networking.tailscale.openFirewall {
      # Trust Tailscale interface
      trustedInterfaces = [config.modules.networking.tailscale.interfaceName];

      # Allow Tailscale UDP port
      allowedUDPPorts = [config.modules.networking.tailscale.port];

      # Allow SSH over Tailscale (secure remote access)
      allowedTCPPorts = [22];
    };

    # Ensure Tailscale CLI is available
    environment.systemPackages = with pkgs; [
      tailscale
    ];

    # Enable IPv4 forwarding for routing features
    boot.kernel.sysctl = lib.mkIf (config.modules.networking.tailscale.useRoutingFeatures != "none") {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Systemd service to handle auth key if provided
    systemd.services.tailscale-autoconnect = lib.mkIf (config.modules.networking.tailscale.authKeyFile != null) {
      description = "Automatic connection to Tailscale";
      after = ["network-pre.target" "tailscale.service"];
      wants = ["network-pre.target" "tailscale.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        # Wait for tailscale to be ready
        sleep 2

        # Check if already connected
        status=$(${pkgs.tailscale}/bin/tailscale status --json | ${pkgs.jq}/bin/jq -r '.BackendState')
        if [ "$status" = "Running" ]; then
          echo "Tailscale already running"
          exit 0
        fi

        # Connect using auth key
        echo "Connecting to Tailscale..."
        ${pkgs.tailscale}/bin/tailscale up --auth-key-file=${config.modules.networking.tailscale.authKeyFile} ${lib.concatStringsSep " " config.modules.networking.tailscale.extraUpFlags}
      '';
    };
  };
}
