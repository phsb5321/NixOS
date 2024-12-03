# ~/NixOS/hosts/modules/home/programs/zellij.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username} = {
      programs.zellij = {
        enable = true;
        settings = {
          theme = "one-half-dark";
          default_shell = "fish";
        };
      };
    };
  };
}
