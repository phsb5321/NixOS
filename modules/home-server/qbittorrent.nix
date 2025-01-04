# ~/NixOS/modules/home-server/qbittorrent.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.qbittorrent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the qBittorrent service.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for qBittorrent's web interface.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/qbittorrent";
      description = "Directory where qBittorrent stores its data.";
    };
  };

  config = lib.mkIf config.services.qbittorrent.enable {
    # Create system user and group for qBittorrent
    users.users.qbittorrent = {
      group = "qbittorrent";
      isSystemUser = true;
      home = config.services.qbittorrent.dataDir;
      createHome = true;
    };
    users.groups.qbittorrent = {};

    # Ensure the data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d '${config.services.qbittorrent.dataDir}' 0755 qbittorrent qbittorrent - -"
    ];

    systemd.services.qbittorrent = {
      description = "qBittorrent Daemon (system-level)";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      requires = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "qbittorrent";
        Group = "qbittorrent";
        ExecStart = ''
          ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox \
            --webui-port=${toString config.services.qbittorrent.port} \
            --profile=${config.services.qbittorrent.dataDir}
        '';
        Restart = "on-failure";
        RestartSec = "5";
        StartLimitInterval = "500";
        StartLimitBurst = "5";

        # Hardening options
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [config.services.qbittorrent.dataDir];
        PrivateTmp = true;
      };
    };

    # Open required ports in the firewall
    networking.firewall.allowedTCPPorts = [
      config.services.qbittorrent.port # Web UI
      6881 # Default BitTorrent port
    ];
  };
}
