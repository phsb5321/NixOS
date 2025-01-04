# ~/NixOS/modules/home-server/homepage.nix
{
  lib,
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
      listenPort = 8082;

      settings = {
        title = "Home Server Dashboard";
        headerStyle = "clean";

        layout = {
          Resources = {
            style = "row";
            columns = 4;
          };
          Network = {
            style = "row";
            columns = 3;
          };
        };

        # Configure services that are running
        services = [
          {
            Network = [
              {
                qBittorrent = {
                  icon = "qbittorrent";
                  href = "http://localhost:8080";
                  description = "Torrent Client";
                };
              }
              {
                LanguageTool = {
                  icon = "mdi-language-markdown";
                  href = "http://localhost:8081";
                  description = "Grammar Checker";
                };
              }
            ];
          }
        ];

        widgets = [
          {
            resources = {
              cpu = true;
              memory = true;
              disk = "/";
            };
          }
        ];
      };
    };

    # Open the homepage dashboard port
    networking.firewall.allowedTCPPorts = [8082];
  };
}
