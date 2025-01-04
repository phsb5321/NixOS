# ~/NixOS/modules/home-server/homepage.nix
{
  lib,
  pkgs,
  config,
  ...
}: {
  options.services.homepage = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable the Homepage dashboard.";
    };
  };

  config = lib.mkIf config.services.homepage.enable {
    services.homepage-dashboard = {
      enable = true;
      # Use default port 8082
      listenPort = 8082;

      # Basic settings
      settings = {
        title = "My Home Server";
        headerStyle = "clean";
        layout = {
          media = {
            style = "row";
            columns = 3;
          };
          infra = {
            style = "row";
            columns = 4;
          };
        };
      };

      # Configure services that are running
      services = [
        {
          Media = [
            {
              Plex = {
                icon = "plex";
                href = "http://${config.networking.hostName}:32400/web";
                description = "Media Server";
                widget = {
                  type = "plex";
                  url = "http://${config.networking.hostName}:32400";
                };
              };
            }
          ];
        }
        {
          Network = [
            {
              qBittorrent = {
                icon = "qbittorrent";
                href = "http://${config.networking.hostName}:8080";
                description = "Torrent Client";
              };
            }
            {
              LanguageTool = {
                icon = "languagetool";
                href = "http://${config.networking.hostName}:${toString config.services.myLanguageTool.port}";
                description = "Grammar Checker";
              };
            }
          ];
        }
      ];
    };

    # Open the homepage dashboard port
    networking.firewall.allowedTCPPorts = [8082];
  };
}
