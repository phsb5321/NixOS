# ~/NixOS/hosts/modules/home/programs/kitty.nix
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
      programs.kitty = {
        enable = true;
        theme = "Gruvbox Dark";
        font = {
          name = "JetBrainsMono Nerd Font Mono";
          size = 18;
        };
        shellIntegration.enableFishIntegration = true;
        settings = {
          copy_on_select = true;
          clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
          enable_ligatures = true;
          font_family = "JetBrainsMono Nerd Font Mono";
          bold_font = "JetBrainsMono Nerd Font Mono Bold";
          italic_font = "JetBrainsMono Nerd Font Mono Italic";
          bold_italic_font = "JetBrainsMono Nerd Font Mono Bold Italic";
        };
      };
    };
  };
}
