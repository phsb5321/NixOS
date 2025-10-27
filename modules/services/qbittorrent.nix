# qBittorrent Service Module
# Headless torrent client with web UI, automation, and webhook support
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;
in {
  options.modules.services.qbittorrent = {
    enable = lib.mkEnableOption "qBittorrent headless torrent client";

    user = lib.mkOption {
      type = lib.types.str;
      default = "qbittorrent";
      description = "User account under which qBittorrent runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "qbittorrent";
      description = "Group under which qBittorrent runs";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/qbittorrent";
      description = "Directory for qBittorrent configuration and state";
    };

    downloadDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/downloads";
      description = "Directory for completed downloads";
    };

    incompleteDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/incomplete";
      description = "Directory for incomplete downloads";
    };

    watchDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/watch";
      description = "Directory to watch for .torrent files";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Web UI port";
    };

    torrentPort = lib.mkOption {
      type = lib.types.port;
      default = 6881;
      description = "Port for torrent connections";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall ports for qBittorrent";
    };

    webhook = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable webhook notifications on torrent completion";
      };

      url = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Webhook URL to call on torrent completion";
        example = "https://discord.com/api/webhooks/...";
      };

      script = lib.mkOption {
        type = lib.types.path;
        default = pkgs.writeShellScript "qbittorrent-webhook" ''
          #!/usr/bin/env bash
          # Default webhook script for qBittorrent
          # Called on torrent completion with parameters from qBittorrent

          # qBittorrent parameters:
          # %N - Torrent name
          # %L - Category
          # %G - Tags (separated by comma)
          # %F - Content path (same as root path for multi-file torrent)
          # %R - Root path (first torrent subdirectory path)
          # %D - Save path
          # %C - Number of files
          # %Z - Torrent size (bytes)
          # %T - Current tracker
          # %I - Info hash v1
          # %J - Info hash v2
          # %K - Torrent ID

          TORRENT_NAME="$1"
          CATEGORY="$2"
          SAVE_PATH="$3"
          CONTENT_PATH="$4"
          TORRENT_SIZE="$5"
          INFO_HASH="$6"

          echo "[$(date)] Torrent completed: $TORRENT_NAME" >> /var/log/qbittorrent-webhook.log

          ${lib.optionalString (cfg.webhook.url != "") ''
            # Send webhook notification
            ${pkgs.curl}/bin/curl -X POST "${cfg.webhook.url}" \
              -H "Content-Type: application/json" \
              -d "{\"content\": \"✅ Torrent completed: **$TORRENT_NAME** ($TORRENT_SIZE bytes)\"}" \
              >> /var/log/qbittorrent-webhook.log 2>&1
          ''}
        '';
        description = "Custom script to run on torrent completion";
      };
    };

    storage = {
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/sda";
        description = "Block device to use for torrent storage";
      };

      mountPoint = lib.mkOption {
        type = lib.types.path;
        default = "/mnt/torrents";
        description = "Mount point for torrent storage";
      };

      format = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Format the storage device (WARNING: destroys all data)";
      };

      fsType = lib.mkOption {
        type = lib.types.str;
        default = "ext4";
        description = "Filesystem type for torrent storage";
      };
    };

    settings = {
      maxRatio = lib.mkOption {
        type = lib.types.nullOr lib.types.float;
        default = null;
        description = "Maximum seeding ratio before stopping torrent";
        example = 2.0;
      };

      maxSeedingTime = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Maximum seeding time in minutes before stopping torrent";
        example = 10080; # 7 days
      };

      downloadLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Global download speed limit in KB/s (null = unlimited)";
      };

      uploadLimit = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Global upload speed limit in KB/s (null = unlimited)";
      };
    };
  };

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
        "d ${cfg.storage.mountPoint} 0750 ${cfg.user} ${cfg.group} -"
      ]
      ++ lib.optionals cfg.webhook.enable [
        "f /var/log/qbittorrent-webhook.log 0644 ${cfg.user} ${cfg.group} -"
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
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
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
    ];
  };
}
