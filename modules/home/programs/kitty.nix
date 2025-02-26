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
      # Enable fontconfig for the user
      fonts.fontconfig.enable = true;

      # Install the JetBrains Mono Nerd Font using the new package structure
      home.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];

      programs.kitty = {
        enable = true;
        # Fix the theme path - use theme name rather than full path
        theme = "Gruvbox Dark";
        shellIntegration.enableZshIntegration = true;
        font = {
          name = "JetBrainsMono Nerd Font";
          size = 18;
        };

        settings = {
          # Other settings
          scrollback_lines = 10000;
          enable_audio_bell = false;
          copy_on_select = true;
          selection_foreground = "none";
          selection_background = "none";
          window_padding_width = 2;

          # Font configuration
          adjust_line_height = "0";
          adjust_column_width = "0";
          disable_ligatures = "never";

          # Clipboard control
          clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
        };
      };
    };

    # System-level font configuration
    fonts.fontconfig = {
      enable = true;
      antialias = true;
      hinting = {
        enable = true;
        style = "slight";
      };
    };
  };
}
