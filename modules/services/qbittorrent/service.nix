# qBittorrent Systemd Service Definition
# Main service, user/group, filesystem, firewall configuration
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
in {
  config = lib.mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
      createHome = true;
      description = "qBittorrent service user";
    };

    users.groups.${cfg.group} = {};

    # Filesystem configuration for storage device
    fileSystems.${cfg.storage.mountPoint} = lib.mkIf (cfg.storage.device != "") {
      device = cfg.storage.device;
      fsType = cfg.storage.fsType;
      options = ["defaults" "nofail"];
    };

    # Format storage device if requested (requires manual intervention)
    systemd.services.format-qbittorrent-storage = lib.mkIf (cfg.storage.format && cfg.storage.device != "") {
      description = "Format qBittorrent storage device";
      wantedBy = ["multi-user.target"];
      before = ["qbittorrent.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "format-qbittorrent-storage" ''
          # Check if device is already formatted
          if ${pkgs.util-linux}/bin/blkid ${cfg.storage.device} | grep -q TYPE; then
            echo "Device ${cfg.storage.device} is already formatted, skipping..."
            exit 0
          fi

          echo "Formatting ${cfg.storage.device} as ${cfg.storage.fsType}..."
          ${pkgs.e2fsprogs}/bin/mkfs.${cfg.storage.fsType} -F ${cfg.storage.device}
        '';
      };
    };

    # Create directory structure and log files
    systemd.tmpfiles.rules =
      [
        "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.downloadDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.incompleteDir} 0750 ${cfg.user} ${cfg.group} -"
        "d ${cfg.watchDir} 0750 ${cfg.user} ${cfg.group} -"
        # Mount point needs 0755 to allow other users to traverse into subdirectories (e.g., Audiobookshelf accessing /mnt/torrents/plex/AudioBooks)
        "d ${cfg.storage.mountPoint} 0755 ${cfg.user} ${cfg.group} -"
      ]
      ++ lib.optionals cfg.webhook.enable [
        "f /var/log/qbittorrent-webhook.log 0644 ${cfg.user} ${cfg.group} -"
      ]
      ++ lib.optionals (config.modules.services.plex.enable or false) [
        "f /var/log/plex-monitor.log 0644 ${cfg.user} ${cfg.group} -"
        "f /var/log/plex-qbittorrent-integration.log 0644 ${cfg.user} ${cfg.group} -"
      ];

    # qBittorrent service
    systemd.services.qbittorrent = {
      description = "qBittorrent headless torrent client";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --profile=${cfg.dataDir} --webui-port=${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "5s";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [
          cfg.dataDir
          cfg.downloadDir
          cfg.incompleteDir
          cfg.watchDir
          cfg.storage.mountPoint
          "/var/log"
        ];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK"];
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # qBittorrent uses JIT
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
      };

      # Wait for mount point to be ready
      unitConfig = lib.mkIf (cfg.storage.device != "") {
        RequiresMountsFor = cfg.storage.mountPoint;
      };
    };

    # Firewall configuration
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port cfg.torrentPort];
      allowedUDPPorts = [cfg.torrentPort];
    };

    # Install qBittorrent and dependencies
    environment.systemPackages = with pkgs; [
      qbittorrent-nox
      curl # For webhooks
      (python3.withPackages (ps: with ps; [requests])) # For monitor daemon
    ];
  };
}
