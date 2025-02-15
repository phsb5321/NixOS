# ~/NixOS/hosts/modules/home/programs/git.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username} = {
      programs.git = {
        enable = true;
        userName = "Pedro Balbino";
        userEmail = "phsb5321@gmail.com";
        extraConfig = {
          core.editor = "nvim";
          init.defaultBranch = "main";
        };
      };
    };
  };
}
