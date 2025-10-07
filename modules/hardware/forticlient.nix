# modules/hardware/forticlient.nix
# FortiClient VPN configuration for laptop
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.hardware.forticlient;
in
{
  options.modules.hardware.forticlient = {
    enable = mkEnableOption "FortiClient VPN support";

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically start FortiClient service on boot";
    };

    serverConfig = mkOption {
      type = types.attrs;
      default = {};
      example = {
        host = "vpn.company.com";
        port = 443;
        realm = "";
      };
      description = "FortiVPN server configuration";
    };

    trustedCert = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Trusted certificate hash for the VPN server";
    };
  };

  config = mkIf cfg.enable {
    # Install openfortivpn and GUI tools
    environment.systemPackages = with pkgs; [
      openfortivpn
      openfortivpn-webview  # For SAML authentication if needed

      # Additional networking tools
      networkmanager-fortisslvpn
      networkmanagerapplet
    ];

    # Enable NetworkManager integration
    networking.networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-fortisslvpn
      ];
    };

    # Create openfortivpn configuration file
    environment.etc."openfortivpn/config" = mkIf (cfg.serverConfig != {}) {
      mode = "0600";
      text = ''
        # OpenFortiVPN Configuration
        ${optionalString (cfg.serverConfig ? host) "host = ${cfg.serverConfig.host}"}
        ${optionalString (cfg.serverConfig ? port) "port = ${toString cfg.serverConfig.port}"}
        ${optionalString (cfg.serverConfig ? realm) "realm = ${cfg.serverConfig.realm}"}
        ${optionalString (cfg.trustedCert != null) "trusted-cert = ${cfg.trustedCert}"}

        # Security settings
        set-dns = 1
        set-routes = 1
        half-internet-routes = 0
        persistent = 5
      '';
    };

    # Create systemd service for openfortivpn
    systemd.services.openfortivpn = mkIf cfg.autoStart {
      description = "OpenFortiVPN Client";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = mkIf cfg.autoStart [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        PrivateTmp = true;
        Restart = "always";
        RestartSec = "10";
        ExecStart = "${pkgs.openfortivpn}/bin/openfortivpn -c /etc/openfortivpn/config";
      };
    };

    # Add user to networkmanager group for VPN management
    users.users.${config.users.users.notroot.name or "notroot"} = {
      extraGroups = [ "networkmanager" ];
    };

    # Enable required kernel modules
    boot.kernelModules = [ "ppp_async" "ppp_deflate" "ppp_mppe" ];

    # Firewall rules for VPN
    networking.firewall = {
      # Allow VPN traffic
      allowedTCPPorts = mkIf (cfg.serverConfig ? port) [ cfg.serverConfig.port ];
      allowedUDPPorts = mkIf (cfg.serverConfig ? port) [ cfg.serverConfig.port ];

      # Enable NAT traversal
      extraCommands = ''
        iptables -A INPUT -p udp --dport 500 -j ACCEPT
        iptables -A INPUT -p udp --dport 4500 -j ACCEPT
      '';
    };
  };
}