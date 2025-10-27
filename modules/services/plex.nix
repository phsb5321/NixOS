# Plex Media Server Module
# Integrated with qBittorrent for automatic media library management
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.plex;
in {
  options.modules.services.plex = {
    enable = lib.mkEnableOption "Plex Media Server";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/plex";
      description = "Directory for Plex configuration and metadata";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/plex-media";
      description = "Root directory for Plex media libraries";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for Plex";
    };

    hardwareAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable hardware-accelerated transcoding (requires PlexPass)";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "plex";
      description = "User account under which Plex runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "plex";
      description = "Group under which Plex runs";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.plex;
      description = "Plex package to use";
      example = "pkgs.plexpass";
    };

    libraries = {
      movies = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Movies library";
      };

      tvShows = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TV Shows library";
      };

      music = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Music library";
      };
    };

    integration = {
      qbittorrent = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable automatic integration with qBittorrent";
        };

        autoScan = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Automatically scan library when new media is added";
        };

        useHardlinks = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use hardlinks instead of copying files (preserves seeding)";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Plex Media Server
    services.plex = {
      enable = true;
      dataDir = cfg.dataDir;
      openFirewall = cfg.openFirewall;
      package = cfg.package;
      user = cfg.user;
      group = cfg.group;
    };

    # Allow unfree packages (Plex is proprietary)
    nixpkgs.config.allowUnfree = true;

    # Create media directory structure
    systemd.tmpfiles.rules = let
      plexUser = cfg.user;
      plexGroup = cfg.group;
    in
      [
        "d ${cfg.mediaDir} 0755 ${plexUser} ${plexGroup} -"
      ]
      ++ lib.optionals cfg.libraries.movies [
        "d ${cfg.mediaDir}/Movies 0755 ${plexUser} ${plexGroup} -"
      ]
      ++ lib.optionals cfg.libraries.tvShows [
        "d ${cfg.mediaDir}/TV Shows 0755 ${plexUser} ${plexGroup} -"
      ]
      ++ lib.optionals cfg.libraries.music [
        "d ${cfg.mediaDir}/Music 0755 ${plexUser} ${plexGroup} -"
      ];

    # Add qBittorrent user to Plex group for file access
    users.users.qbittorrent = lib.mkIf (config.modules.services.qbittorrent.enable && cfg.integration.qbittorrent.enable) {
      extraGroups = [cfg.group];
    };

    # Add Plex user to qBittorrent group for file access
    users.users.${cfg.user} = lib.mkIf (config.modules.services.qbittorrent.enable && cfg.integration.qbittorrent.enable) {
      extraGroups = [config.modules.services.qbittorrent.group];
    };

    # Hardware transcoding support (requires PlexPass)
    hardware.graphics.enable = lib.mkIf cfg.hardwareAcceleration true;

    # Install Plex utilities
    environment.systemPackages = with pkgs; [
      plex
      curl # For Plex API calls
    ];

    # Plex API token configuration script
    environment.etc."plex/get-token.sh" = {
      text = ''
        #!/usr/bin/env bash
        # Get Plex authentication token
        # Run this after first Plex setup through Web UI

        echo "To get your Plex token:"
        echo "1. Sign in to Plex Web UI at http://$(hostname -I | awk '{print $1}'):32400/web"
        echo "2. Open your browser's developer tools (F12)"
        echo "3. Go to Console tab"
        echo "4. Type: window.localStorage.getItem('myPlexAccessToken')"
        echo "5. Copy the token (without quotes)"
        echo ""
        echo "Then create: /etc/plex/token with your token"
        echo "Example: echo 'YOUR_TOKEN_HERE' | sudo tee /etc/plex/token"
      '';
      mode = "0755";
    };
  };
}
