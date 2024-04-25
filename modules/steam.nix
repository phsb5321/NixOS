{ config, pkgs, lib, ... }:

{
  options.programs.steam = {
    enable = lib.mkEnableOption "Steam game platform";
    remotePlay.openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open ports in the firewall for Steam Remote Play";
    };
    dedicatedServer.openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open ports in the firewall for Source Dedicated Server";
    };
  };

  config = lib.mkIf config.programs.steam.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = config.programs.steam.remotePlay.openFirewall;
      dedicatedServer.openFirewall = config.programs.steam.dedicatedServer.openFirewall;
    };

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];

  };
}
