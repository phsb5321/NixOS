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
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Cloudflare tunnel ID (must be set via server-secrets.nix, never commit to git)";
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
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to Cloudflare tunnel credentials file (typically ~/.cloudflared/<tunnel-id>.json)";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "notroot";
      description = "User to run the tunnel as";
    };
  };

  config = lib.mkIf cfg.enable {
    # Assertions to ensure credentials are configured
    assertions = [
      {
        assertion = cfg.tunnelId != null;
        message = "modules.services.cloudflareTunnel.tunnelId must be set (via server-secrets.nix)";
      }
      {
        assertion = cfg.credentialsFile != null;
        message = "modules.services.cloudflareTunnel.credentialsFile must be set (via server-secrets.nix)";
      }
    ];

    # Cloudflare Tunnel systemd service
    systemd.services.cloudflared-tunnel = lib.mkIf (cfg.tunnelId != null && cfg.credentialsFile != null) {
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
