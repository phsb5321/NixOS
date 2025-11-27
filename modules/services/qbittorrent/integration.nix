# qBittorrent-Plex Integration
# Automatic hardlink creation and Plex library scanning for completed torrents
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
in {
  config = lib.mkIf cfg.enable {
    # Plex monitor daemon (automatically creates hardlinks for completed torrents)
    systemd.services.plex-monitor = lib.mkIf (config.modules.services.plex.enable or false) {
      description = "Plex-qBittorrent Integration Monitor";
      after = ["qbittorrent.service" "plex.service"];
      wants = ["qbittorrent.service" "plex.service"];
      wantedBy = ["multi-user.target"];

      environment = {
        QBITTORRENT_URL = "http://localhost:${toString cfg.port}";
        PLEX_URL = "http://localhost:32400";
        PLEX_MOVIES_SECTION = "1";
        PLEX_TV_SECTION = "2";
        POLL_INTERVAL = "30"; # Check every 30 seconds
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.python3.withPackages (ps: with ps; [requests])}/bin/python3 ${../qbittorrent-scripts/plex-monitor-daemon.py}";
        Restart = "always";
        RestartSec = "10s";

        # Security
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          cfg.dataDir
          cfg.downloadDir
          cfg.incompleteDir
          cfg.storage.mountPoint
          "/var/log"
        ];
        ProtectHome = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
      };
    };
  };
}
