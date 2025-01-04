# ~/NixOS/modules/home-server/languagetool.nix
{
  lib,
  pkgs,
  config,
  ...
}: {
  options.services.myLanguageTool = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable the custom MyLanguageTool service.
      '';
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8081;
      description = ''
        Port on which the custom MyLanguageTool listens.
      '';
    };
  };

  config = lib.mkIf config.services.myLanguageTool.enable {
    # Create system user/group for LanguageTool
    users.users.languagetool = {
      isSystemUser = true;
      group = "languagetool";
      description = "LanguageTool service user";
    };
    users.groups.languagetool = {};

    systemd.services.myLanguageTool = {
      description = "Custom MyLanguageTool Grammar Checker Service";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];

      serviceConfig = {
        Type = "simple";
        User = "languagetool";
        Group = "languagetool";
        ExecStart = ''
          ${pkgs.openjdk17}/bin/java -cp ${pkgs.languagetool}/share/languagetool-server.jar org.languagetool.server.HTTPServer \
            --port ${toString config.services.myLanguageTool.port} \
            --public \
            --allow-origin "*"
        '';
        Restart = "on-failure";
        RestartSec = "5";

        # Basic hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };

    # Open the port in the firewall
    networking.firewall.allowedTCPPorts = [config.services.myLanguageTool.port];
  };
}
