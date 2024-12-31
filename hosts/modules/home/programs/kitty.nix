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
      # Add the font package to user packages
      home.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];

      programs.kitty = {
        enable = true;
        theme = "Gruvbox Dark";
        shellIntegration.enableFishIntegration = true;
        settings = {
          # Basic settings
          font_family = "JetBrainsMonoNerdFontMono-Regular";
          bold_font = "JetBrainsMonoNerdFontMono-Bold";
          italic_font = "JetBrainsMonoNerdFontMono-Italic";
          bold_italic_font = "JetBrainsMonoNerdFontMono-BoldItalic";
          font_size = 18;

          # Disable ligatures to rule out any related issues
          disable_ligatures = "never";

          # Other settings
          scrollback_lines = 10000;
          enable_audio_bell = false;
          copy_on_select = true;
          selection_foreground = "none";
          selection_background = "none";
          window_padding_width = 2;

          # Clipboard control
          clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
        };
      };
    };
  };
}
