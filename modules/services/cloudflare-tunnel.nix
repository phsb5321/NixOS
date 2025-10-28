# Cloudflare Tunnel Service Module
# Exposes local services securely via Cloudflare Tunnel
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.cloudflare-tunnel;
in {
  options.modules.services.cloudflare-tunnel = {
    enable = lib.mkEnableOption "Cloudflare Tunnel";

    tunnelID = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare Tunnel ID";
      example = "7d1704a0-512f-4a54-92c4-d9bf0b4561c3";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to tunnel credentials JSON file";
      example = "/home/user/.cloudflared/TUNNEL_ID.json";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to cloudflared config.yml";
      example = "/home/user/.cloudflared/config.yml";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "notroot";
      description = "User to run cloudflared as";
    };
  };

  config = lib.mkIf cfg.enable {
    # Cloudflare Tunnel service
    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${cfg.configFile} run ${cfg.tunnelID}";
        Restart = "always";
        RestartSec = "5s";

        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = [
          "/home/${cfg.user}/.cloudflared"
        ];
      };
    };

    # Install cloudflared
    environment.systemPackages = with pkgs; [
      cloudflared
    ];
  };
}
