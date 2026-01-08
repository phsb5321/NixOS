{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.fonts;
in {
  options.modules.core.fonts = {
    enable = mkEnableOption "Core fonts configuration";

    packages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [
        # Nerd Fonts - Programming fonts with icons
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.symbols-only

        # Standard fonts for good coverage
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf
        cantarell-fonts

        # Additional fonts
        dejavu_fonts
        source-code-pro
      ];
      description = "List of font packages to install system-wide";
    };

    enableDefaultPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the default NixOS font packages";
    };

    defaultFonts = {
      serif = mkOption {
        type = types.listOf types.str;
        default = [
          "DejaVu Serif"
          "Liberation Serif"
        ];
        description = "List of serif fonts to use in order of preference";
      };

      sansSerif = mkOption {
        type = types.listOf types.str;
        default = [
          "DejaVu Sans"
          "Liberation Sans"
        ];
        description = "List of sans-serif fonts to use in order of preference";
      };

      monospace = mkOption {
        type = types.listOf types.str;
        default = [
          "JetBrainsMono Nerd Font Mono"
          "FiraCode Nerd Font Mono"
          "DejaVu Sans Mono"
          "Liberation Mono"
        ];
        description = "List of monospace fonts to use in order of preference";
      };

      emoji = mkOption {
        type = types.listOf types.str;
        default = [
          "Noto Color Emoji"
          "Segoe UI Emoji"
        ];
        description = "List of emoji fonts to use in order of preference";
      };
    };

    rendering = {
      antialias = mkOption {
        type = types.bool;
        default = true;
        description = "Enable font anti-aliasing";
      };

      subpixel = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable sub-pixel rendering for LCD screens";
        };

        rgba = mkOption {
          type = types.enum ["none" "rgb" "bgr" "vrgb" "vbgr"];
          default = "rgb";
          description = "Sub-pixel rendering order";
        };
      };

      hinting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable font hinting";
        };

        style = mkOption {
          type = types.enum ["none" "slight" "medium" "full"];
          default = "slight";
          description = "Font hinting style";
        };
      };
    };
  };

  config = mkIf (config.modules.core.enable && cfg.enable) {
    fonts = {
      fontDir.enable = true;
      inherit (cfg) packages;
      inherit (cfg) enableDefaultPackages;

      fontconfig = {
        inherit (cfg) defaultFonts;

        inherit (cfg.rendering) antialias;
        subpixel = {
          inherit (cfg.rendering.subpixel) rgba;
          lcdfilter = "default";
        };

        hinting = {
          inherit (cfg.rendering.hinting) enable;
          inherit (cfg.rendering.hinting) style;
        };

        # Note: localConf is handled by modules.desktop.fonts to avoid conflicts
        # when desktop environment is enabled
      };
    };

    environment.systemPackages = with pkgs; [
      fontconfig
      font-manager
    ];

    system.activationScripts.fonts.text = ''
      echo "Setting up fontconfig cache directories..."
      mkdir -p /var/cache/fontconfig
      chmod 755 /var/cache/fontconfig
    '';
  };
}
