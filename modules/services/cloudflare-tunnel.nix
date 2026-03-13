# modules/services/cloudflare-tunnel.nix
#
# Module: Cloudflare Tunnel
# Purpose: Runs cloudflared tunnel for external access to services (e.g., Audiobookshelf)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.cloudflareTunnel;
in {
  options.modules.services.cloudflareTunnel = {
    enable = lib.mkEnableOption "Cloudflare Tunnel for Audiobookshelf";

    tunnelName = lib.mkOption {
      type = lib.types.str;
      default = "audiobookshelf";
      description = "Name of the tunnel";
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      default = "/home/notroot/.cloudflared/config.yml";
      description = "Path to Cloudflare tunnel config file";
    };

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/cloudflare_credentials";
      description = ''
        Path to Cloudflare tunnel credentials JSON file.
        Defaults to the sops-nix decrypted secret path.
        Can be overridden to a manual path if not using sops-nix.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "notroot";
      description = "User to run the tunnel as";
    };
  };

  config = lib.mkIf cfg.enable {
    # Cloudflare Tunnel systemd service
    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel for Audiobookshelf";
      after = ["network.target" "audiobookshelf.service"];
      wants = ["audiobookshelf.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --config ${cfg.configFile} run ${cfg.tunnelName}";
        Restart = "always";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadOnlyPaths = [cfg.configFile cfg.credentialsFile];
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
      };
    };

    # Install cloudflared package
    environment.systemPackages = with pkgs; [
      cloudflared
    ];
  };
}
