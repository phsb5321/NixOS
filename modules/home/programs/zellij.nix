# ~/NixOS/modules/home/programs/zellij.nix
{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username}.programs.zellij = {
      enable = true;
      package = pkgs.zellij;
      attachExistingSession = false;
      exitShellOnExit = false;
      enableZshIntegration = true;
      settings = {
        session_serialization = true;
        pane_viewport_serialization = true;
        plugins = ["zjstatus" "room" "resize_panes"];
      };
    };
  };
}
