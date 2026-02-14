# Cloudflare Tunnel Module
# Automatically runs cloudflared tunnel for Audiobookshelf external access
# Provides persistent tunnel that survives reboots
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

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = "Cloudflare tunnel ID (no default - must be set explicitly, never commit to git)";
      # No default - must be configured per-host to avoid committing secrets
    };

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
      description = "Path to Cloudflare tunnel credentials file (typically ~/.cloudflared/<tunnel-id>.json)";
      # No default - derived from tunnelId, must be configured per-host
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
