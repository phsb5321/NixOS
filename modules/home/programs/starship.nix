# ~/NixOS/modules/home/programs/starship.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.home;
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.${cfg.username}.programs.starship = {
      enable = true;
      enableZshIntegration = true;
      package = pkgs.starship;
      settings = {
        add_newline = false;
        format = "$directory$git_branch$character";
      };
    };
  };
}
