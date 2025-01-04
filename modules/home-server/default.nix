# ~/NixOS/modules/home-server/default.nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  ########################################
  # 1) Define top-level homeServer.enable
  ########################################
  options.homeServer.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to enable all "home-server" services like
      LanguageTool, qBittorrent, Plex, etc.
    '';
  };

  ########################################
  # 2) Import All Submodules
  ########################################
  imports = [
    ./languagetool.nix
    ./homepage.nix
    ./qbittorrent.nix
    ./plex.nix
  ];

  ###################################################
  # 3) Tie each submodule's .enable to homeServer.enable
  ###################################################
  config = {
    # LanguageTool (fixed service name)
    services.languagetool.enable = lib.mkDefault config.homeServer.enable;

    # qBittorrent
    services.qbittorrent.enable = lib.mkDefault config.homeServer.enable;

    # Plex
    services.plex.enable = lib.mkDefault config.homeServer.enable;

    # Homepage Dashboard
    services.homepage.enable = lib.mkDefault config.homeServer.enable;
  };
}
