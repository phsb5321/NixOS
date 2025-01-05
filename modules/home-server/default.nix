# ~/NixOS/modules/home-server/default.nix
{
  config,
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
      LanguageTool, qBittorrent, Custom Plex, etc.
    '';
  };

  ########################################
  # 2) Import All Submodules
  ########################################
  imports = [
    ./languagetool.nix
    ./qbittorrent.nix
    ./plex.nix
    # ./dashy.nix
  ];

  ###################################################
  # 3) Tie each submodule's .enable to homeServer.enable
  ###################################################
  config = {
    # LanguageTool (fixed service name)
    services.languagetool.enable = lib.mkDefault config.homeServer.enable;

    # qBittorrent
    services.qbittorrent.enable = lib.mkDefault config.homeServer.enable;

    # Custom Plex (renamed to avoid conflicts)
    services.customPlex.enable = lib.mkDefault config.homeServer.enable;

    # Dashboard (renamed to avoid conflicts)
    # services.customDashy.enable = lib.mkDefault config.homeServer.enable;
  };
}
