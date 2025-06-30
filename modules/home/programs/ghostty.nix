# ~/NixOS/modules/home/programs/ghostty.nix
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
    home-manager.users.${cfg.username}.programs.ghostty = {
      enable = true;
      package = pkgs.ghostty;
      enableZshIntegration = true;
      settings = {
        listen = "127.0.0.1:3000";
        shell = "${pkgs.zsh}/bin/zsh";
        command_flags = ["-l"];
        web_app = "${pkgs.ghostty}/share/ghostty/webapp";
      };
    };
  };
}
