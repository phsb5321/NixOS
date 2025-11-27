# qBittorrent Option Declarations
# All configurable options for the qBittorrent service
{lib, ...}: {
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

    webUI = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Web UI";
      };

      bypassLocalAuth = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Bypass authentication for clients on localhost and LAN";
      };

      bypassAuthSubnetWhitelist = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Comma-separated list of IP subnets to bypass authentication (e.g., '192.168.1.0/24, 10.0.0.0/8')";
        example = "192.168.0.0/16, 10.0.0.0/8";
      };
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
        description = "Custom script to run on torrent completion";
      };
    };

    storage = {
      device = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Block device to use for torrent storage (e.g., /dev/sda or UUID=...)";
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
}
