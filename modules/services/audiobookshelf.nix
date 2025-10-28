# Audiobookshelf Service Module
# Modern self-hosted audiobook and podcast server with superior metadata and chapter support
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.audiobookshelf;
in {
  options.modules.services.audiobookshelf = {
    enable = lib.mkEnableOption "Audiobookshelf audiobook and podcast server";

    port = lib.mkOption {
      type = lib.types.port;
      default = 13378;
      description = "Web UI port for Audiobookshelf";
    };

    audiobooksDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/plex/AudioBooks";
      description = "Directory containing audiobooks (can be SSHFS mount)";
    };

    podcastsDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/torrents/podcasts";
      description = "Directory for podcasts";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/audiobookshelf";
      description = "Directory for Audiobookshelf configuration and metadata";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall port for Audiobookshelf";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "ghcr.io/advplyr/audiobookshelf:latest";
      description = "Docker image to use";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure Docker is enabled
    virtualisation.docker.enable = true;

    # Create data and podcast directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
      "d ${cfg.dataDir}/config 0755 root root -"
      "d ${cfg.dataDir}/metadata 0755 root root -"
      "d ${cfg.podcastsDir} 0755 root root -"
    ];

    # Audiobookshelf Docker container service
    systemd.services.audiobookshelf = {
      description = "Audiobookshelf audiobook and podcast server";
      after = ["docker.service" "network.target"];
      requires = ["docker.service"];
      wantedBy = ["multi-user.target"];

      # Wait for AudioBooks mount if using SSHFS
      unitConfig = lib.mkIf (cfg.audiobooksDir == "/mnt/torrents/plex/AudioBooks") {
        After = ["mnt-torrents-plex-AudioBooks.mount"];
        Requires = ["mnt-torrents-plex-AudioBooks.mount"];
      };

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.docker}/bin/docker pull ${cfg.image}";
        ExecStart = pkgs.writeShellScript "audiobookshelf-start" ''
          ${pkgs.docker}/bin/docker run -d \
            --name audiobookshelf \
            --restart unless-stopped \
            -p ${toString cfg.port}:80 \
            -e ROUTER_BASE_PATH="" \
            -v ${cfg.dataDir}/config:/config \
            -v ${cfg.dataDir}/metadata:/metadata \
            -v ${cfg.audiobooksDir}:/audiobooks:ro \
            -v ${cfg.podcastsDir}:/podcasts \
            ${cfg.image} || \
          ${pkgs.docker}/bin/docker start audiobookshelf
        '';
        ExecStop = "${pkgs.docker}/bin/docker stop audiobookshelf";
        Restart = "on-failure";
        RestartSec = "10s";
      };

      preStart = ''
        # Remove container if it exists but is stopped
        ${pkgs.docker}/bin/docker rm -f audiobookshelf 2>/dev/null || true
      '';
    };

    # Firewall configuration
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

    # Install Docker if not already enabled
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];
  };
}
