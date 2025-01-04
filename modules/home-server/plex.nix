# ~/NixOS/modules/home-server/plex.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.customPlex = {
    # Changed from services.plex
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the Custom Plex Media Server.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/customplex"; # Changed directory name to avoid conflicts
      description = "Directory where Custom Plex stores metadata.";
    };
  };

  config = lib.mkIf config.services.customPlex.enable {
    # Changed from services.plex
    # Create system user and group for Plex
    users.users.customplex = {
      # Changed from plex
      group = "customplex"; # Changed from plex
      isSystemUser = true;
      home = config.services.customPlex.dataDir; # Changed reference
      createHome = true;
    };
    users.groups.customplex = {}; # Changed from plex

    # Ensure the data directory exists and has correct permissions
    systemd.tmpfiles.rules = [
      "d '${config.services.customPlex.dataDir}' 0755 customplex customplex - -" # Changed references
    ];

    systemd.services.customplex = {
      # Changed from plex
      description = "Custom Plex Media Server";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      requires = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "customplex"; # Changed from plex
        Group = "customplex"; # Changed from plex
        ExecStart = "${pkgs.plex}/lib/plexmediaserver/Plex\\ Media\\ Server";
        Restart = "on-failure";
        RestartSec = "5";
        StartLimitIntervalSec = "500";
        StartLimitBurst = "5";

        # Hardening options
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          config.services.customPlex.dataDir # Changed reference
          "/tmp"
        ];
        PrivateTmp = true;
      };

      environment = {
        # Set required environment variables
        PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR = config.services.customPlex.dataDir; # Changed reference
        PLEX_MEDIA_SERVER_HOME = "${pkgs.plex}/lib/plexmediaserver";
        PLEX_MEDIA_SERVER_MAX_PLUGIN_PROCS = "6";
        PLEX_MEDIA_SERVER_TMPDIR = "/tmp";
        LC_ALL = "en_US.UTF-8";
        LANG = "en_US.UTF-8";
      };
    };

    # Open required ports in the firewall
    networking.firewall = {
      allowedTCPPorts = [
        32400 # Primary Plex port
        3005 # Plex Home Theater via Plex Companion
        8324 # Plex for Roku via Plex Companion
        32469 # Plex DLNA Server
      ];
      allowedUDPPorts = [
        1900 # Plex DLNA Server
        5353 # Plex Cast
        32410 # GDM network discovery
        32412 # GDM network discovery
        32413 # GDM network discovery
        32414 # GDM network discovery
      ];
    };
  };
}
