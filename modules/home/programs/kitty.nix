# ~/NixOS/modules/home/programs/kitty.nix
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
    home-manager.users.${cfg.username}.programs.kitty = {
      enable = true;
      package = pkgs.kitty;

      font = {
        name = "JetBrainsMono Nerd Font";
        size = 18;
      };

      # switch to a theme that actually exists in kitty-themes
      themeFile = "Dracula";

      shellIntegration.enableZshIntegration = true;

      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        copy_on_select = true;
        selection_foreground = "none";
        selection_background = "none";
        window_padding_width = 2;
        adjust_line_height = "0";
        adjust_column_width = "0";
        disable_ligatures = "never";
        clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
      };
    };
  };
}
