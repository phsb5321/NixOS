# Modify services configuration with intranet IP and update languagetool URL
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
                href = "http://192.168.1.87:32400/web"; # Replace with intranet IP
                icon = "plex.png";
                description = "Media server";
              };
            }
            {
              qBittorrent = {
                href = "http://192.168.1.87:8080"; # Replace with intranet IP
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
                href = "http://192.168.1.87:8081/check"; # Updated to intranet IP and `/check` route
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
