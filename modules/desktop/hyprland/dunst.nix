{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.dunst;
in {
  options.modules.dunst.enable = mkEnableOption "Dunst configuration";

  config = mkIf (cfg.enable && config.modules.desktop.enable) {
    home-manager.users.${config.modules.desktop.autoLogin.user} = {pkgs, ...}: {
      services.dunst = {
        enable = true;
        settings = {
          global = {
            font = "JetBrains Mono Nerd Font 11";
            frame_width = 2;
            frame_color = "#89b4fa";
            separator_color = "frame";
            corner_radius = 10;
          };

          urgency_low = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            timeout = 5;
          };

          urgency_normal = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            timeout = 10;
          };

          urgency_critical = {
            background = "#1e1e2e";
            foreground = "#cdd6f4";
            frame_color = "#f38ba8";
            timeout = 0;
          };
        };
      };

      home.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
    };
  };
}
