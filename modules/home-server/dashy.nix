# ~/NixOS/modules/home-server/dashy.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.customDashy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable a minimal Custom Dashy dashboard (no references to other services).";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Port for Custom Dashy.";
    };
  };

  config = lib.mkIf config.services.customDashy.enable {
    ################################################################################
    # 1) Create a user & group
    ################################################################################
    users.users.customdashy = {
      isSystemUser = true;
      group = "customdashy";
      home = "/var/lib/customdashy";
      shell = pkgs.bash;
      createHome = true;
    };

    users.groups.customdashy = {};

    ################################################################################
    # 2) Directory creation (permissions)
    ################################################################################
    systemd.tmpfiles.rules = [
      "d /var/lib/customdashy 0755 customdashy customdashy -"
    ];

    ################################################################################
    # 3) Generate a minimal config.json
    ################################################################################
    environment.etc."customdashy/config.json".text = builtins.toJSON {
      server = {
        port = config.services.customDashy.port;
      };
      theme = "dark";
      language = "en";
      statusCheck = true;
      hideComponents = {
        hideSearch = false;
        hideSettings = false;
        hideFooter = true;
      };
      cssThemes = ["nord-frost"];
      customColors = {
        primary = "#81a1c1";
        background = "#2e3440";
      };
      pageInfo = {
        title = "Minimal Dashy";
        description = "A minimal Dashy config with no extra services.";
        navLinks = [
          {
            title = "Home";
            path = "/";
          }
        ];
      };
      sections = [
        {
          name = "Welcome";
          icon = "fas fa-server";
          displayData = {
            collapsed = false;
            cols = 2;
            itemSize = "medium";
          };
          items = [
            {
              title = "Hello from Dashy!";
              description = "Minimal example with no trailing commas";
              icon = "fas fa-smile";
              url = "http://localhost:${toString config.services.customDashy.port}";
            }
          ];
        }
      ];
    };

    ################################################################################
    # 4) systemd service
    ################################################################################
    systemd.services.customdashy = {
      description = "Minimal Custom Dashy Dashboard";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        User = "customdashy";
        Group = "customdashy";

        # This is where the Node process tries to run dashy.js
        # If dashy.js isn't actually in /var/lib/customdashy/, it will fail.
        ExecStart = ''
          ${pkgs.nodejs}/bin/node /var/lib/customdashy/dashy.js \
            --config /etc/customdashy/config.json
        '';

        Restart = "on-failure";
        RestartSec = 5;
        Environment = "NODE_ENV=production";
        WorkingDirectory = "/var/lib/customdashy";
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
      };
    };

    ################################################################################
    # 5) Firewall
    ################################################################################
    networking.firewall.allowedTCPPorts = [
      config.services.customDashy.port
    ];
  };
}
