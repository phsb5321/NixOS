# ~/NixOS/modules/home-server/default.nix
{
  config,
  lib,
  ...
}: {
  options.homeServer.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to enable all "home-server" services like
      LanguageTool, qBittorrent, Custom Plex, etc.
    '';
  };

  imports = [
    ./languagetool.nix
    ./qbittorrent.nix
    ./plex.nix
    ./homepage.nix
  ];

  config = {
    services.languagetool.enable = lib.mkDefault config.homeServer.enable;
    services.qbittorrent.enable = lib.mkDefault config.homeServer.enable;
    services.customPlex.enable = lib.mkDefault config.homeServer.enable;

    services.home-dashboard = {
      enable = lib.mkDefault config.homeServer.enable;
      settings = {
        title = "Home Server Dashboard";
        theme = "dark";
        color = "slate";
        language = "en";
        headerStyle = "clean";
      };

      services = [
        {
          Media = [
            {
              Plex = {
                href = "http://localhost:32400/web";
                icon = "plex.png";
                description = "Media server";
              };
            }
            {
              qBittorrent = {
                href = "http://localhost:8080";
                icon = "qbittorrent.png";
                description = "Download manager";
              };
            }
          ];
        }
        {
          Tools = [
            {
              LanguageTool = {
                href = "http://localhost:8081";
                icon = "language.png";
                description = "Grammar checker API";
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
        {
          datetime = {
            format = "MMMM Do, h:mm a";
            background = true;
          };
        }
      ];
    };
  };
}
