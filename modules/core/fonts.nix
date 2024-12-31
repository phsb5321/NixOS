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

        # Standard fonts for good coverage
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf

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
      packages = cfg.packages;
      enableDefaultPackages = cfg.enableDefaultPackages;

      fontconfig = {
        defaultFonts = cfg.defaultFonts;

        antialias = cfg.rendering.antialias;
        subpixel = {
          rgba = cfg.rendering.subpixel.rgba;
          lcdfilter = "default";
        };

        hinting = {
          enable = cfg.rendering.hinting.enable;
          style = cfg.rendering.hinting.style;
        };

        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- Disable bitmap fonts -->
            <selectfont>
              <rejectfont>
                <pattern>
                  <patelt name="scalable"><bool>false</bool></patelt>
                </pattern>
              </rejectfont>
            </selectfont>

            <!-- Enable TrueType hinting -->
            <match target="font">
              <edit name="hinting" mode="assign"><bool>true</bool></edit>
            </match>

            <!-- Configure Nerd Fonts specifics -->
            <match target="pattern">
              <test name="family" qual="any">
                <string>monospace</string>
              </test>
              <edit binding="same" mode="prepend" name="family">
                <string>JetBrainsMono Nerd Font Mono</string>
                <string>FiraCode Nerd Font Mono</string>
              </edit>
            </match>

            <!-- Enable system-wide emoji support -->
            <match target="pattern">
              <test name="family"><string>monospace</string></test>
              <edit name="family" mode="append_last">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
          </fontconfig>
        '';
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
