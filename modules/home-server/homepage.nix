# ~/NixOS/modules/home-server/homepage.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.services.home-dashboard = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the Homepage dashboard.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.homepage-dashboard;
      description = "The Homepage dashboard package to use.";
    };

    listenPort = lib.mkOption {
      type = lib.types.port;
      default = 8082;
      description = "Port for Homepage's web interface.";
    };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Homepage main settings configuration.";
    };

    bookmarks = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Homepage bookmarks configuration.";
    };

    services = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Homepage services configuration.";
    };

    widgets = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [];
      description = "Homepage widgets configuration.";
    };

    kubernetes = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Homepage Kubernetes integration configuration.";
    };

    docker = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Homepage Docker integration configuration.";
    };

    customJS = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Custom JavaScript code for Homepage.";
    };

    customCSS = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Custom CSS code for Homepage.";
    };
  };

  config = let
    cfg = config.services.home-dashboard;
    stateDir = "/var/lib/homepage-dashboard";

    writeConfig = name: value: pkgs.writeText "homepage-${name}" value;

    configFiles = {
      "settings.yaml" = writeConfig "settings" (builtins.toJSON cfg.settings);
      "bookmarks.yaml" = writeConfig "bookmarks" (builtins.toJSON cfg.bookmarks);
      "services.yaml" = writeConfig "services" (builtins.toJSON cfg.services);
      "widgets.yaml" = writeConfig "widgets" (builtins.toJSON cfg.widgets);
      "kubernetes.yaml" = writeConfig "kubernetes" (builtins.toJSON cfg.kubernetes);
      "docker.yaml" = writeConfig "docker" (builtins.toJSON cfg.docker);
      "custom.js" = writeConfig "custom-js" cfg.customJS;
      "custom.css" = writeConfig "custom-css" cfg.customCSS;
    };

    setupScript = pkgs.writeShellScript "homepage-setup" ''
      set -euo pipefail

      # Ensure directories exist
      mkdir -p ${stateDir}/config

      # Copy configuration files
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: src: ''
          cp ${src} ${stateDir}/config/${name}
          chmod 644 ${stateDir}/config/${name}
        '')
        configFiles)}

      # Set permissions
      chown -R homepage:homepage ${stateDir}
      chmod 755 ${stateDir}
    '';
  in
    lib.mkIf cfg.enable {
      users.users.homepage = {
        isSystemUser = true;
        group = "homepage";
        home = stateDir;
      };
      users.groups.homepage = {};

      systemd.services.home-dashboard = {
        description = "Homepage Dashboard Service";
        wantedBy = ["multi-user.target"];
        after = ["network.target"];

        preStart = "${setupScript}";

        environment = {
          HOMEPAGE_CONFIG_DIR = "${stateDir}/config";
          PORT = toString cfg.listenPort;
          NODE_ENV = "production";
        };

        serviceConfig = {
          Type = "simple";
          User = "homepage";
          Group = "homepage";

          StateDirectory = "homepage-dashboard";
          StateDirectoryMode = "0755";
          RuntimeDirectory = "homepage-dashboard";
          RuntimeDirectoryMode = "0755";
          CacheDirectory = "homepage-dashboard";
          CacheDirectoryMode = "0755";

          ExecStart = "${cfg.package}/bin/homepage";
          Restart = "always";
          RestartSec = "10s";

          # Security settings
          NoNewPrivileges = true;
          ProtectSystem = "full";
          ProtectHome = true;
          ReadWritePaths = [stateDir];
        };
      };

      networking.firewall.allowedTCPPorts = [cfg.listenPort];
    };
}
