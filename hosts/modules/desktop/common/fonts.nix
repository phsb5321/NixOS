# hosts/modules/desktop/common/fonts.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.fonts;
in {
  options.modules.desktop.fonts = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the desktop fonts configuration.";
    };

    packages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [
        nerd-fonts-jetbrains-mono
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-symbols
        jetbrains-mono
      ];
      description = "List of font packages to install.";
    };

    enableDefaultPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable default font packages.";
    };

    defaultFonts = {
      serif = mkOption {
        type = with types; listOf str;
        default = ["Noto Serif" "Liberation Serif"];
        description = "Default serif fonts.";
      };

      sansSerif = mkOption {
        type = with types; listOf str;
        default = ["Noto Sans" "Liberation Sans"];
        description = "Default sans-serif fonts.";
      };

      monospace = mkOption {
        type = with types; listOf str;
        default = ["JetBrainsMono Nerd Font Mono" "JetBrains Mono" "Fira Code" "Liberation Mono"];
        description = "Default monospace fonts.";
      };
    };
  };

  config = mkIf (config.modules.desktop.enable && cfg.enable) {
    fonts = {
      fontDir.enable = true;
      packages = cfg.packages;
      enableDefaultPackages = cfg.enableDefaultPackages;

      fontconfig = {
        defaultFonts = {
          serif = cfg.defaultFonts.serif;
          sansSerif = cfg.defaultFonts.sansSerif;
          monospace = cfg.defaultFonts.monospace;
        };
      };
    };

    # Additional font-related configurations
    environment.systemPackages = with pkgs; [
      fontconfig # Font configuration utility
      gnome-font-viewer # Font viewer
    ];
  };
}
