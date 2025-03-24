# hosts/modules/desktop/common/fonts.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.fonts;

  # Helper function to create font paths for fontconfig
  mkFontPath = path: "${path}/share/fonts";

  # Define commonly used font options
  mkFontOption = name: {
    type = types.listOf types.str;
    description = "List of ${name} fonts to use in order of preference";
  };
in {
  options.modules.desktop.fonts = {
    enable =
      mkEnableOption "Desktop fonts configuration"
      // {
        description = "Whether to enable the desktop fonts configuration module.";
      };

    # Font packages configuration
    packages = mkOption {
      type = with types; listOf package;
      default = with pkgs; [
        # Nerd Fonts - Programming fonts with icons
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.roboto-mono
        nerd-fonts.source-code-pro
        nerd-fonts.hack

        # Standard fonts for good coverage
        font-awesome # Icon font
        noto-fonts # Google's font family for unicode coverage
        noto-fonts-cjk-sans # CJK support (Chinese, Japanese, Korean)
        noto-fonts-emoji # Emoji support
        liberation_ttf # Microsoft-compatible fonts
        xorg.font-misc-misc

        # Optional but recommended fonts
        ubuntu_font_family # Ubuntu's font family
        dejavu_fonts # DejaVu font family
        source-code-pro # Adobe's monospace font
        freetype # TrueType rendering engine
        cantarell-fonts # GNOME default fonts
        droid-fonts # Android "Droid" fonts
        ibm-plex # IBM's Plex font family
        terminus_font # Terminus monospace font
      ];
      description = ''
        List of font packages to install system-wide.
        Includes Nerd Fonts variants, standard fonts, and optional recommended fonts.
      '';
    };

    # Enable default font packages
    enableDefaultPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the default NixOS font packages";
    };

    # Default font configurations
    defaultFonts = {
      serif =
        mkOption (mkFontOption "serif")
        // {
          default = [
            "DejaVu Serif"
            "Noto Serif"
            "Liberation Serif"
            "Cantarell"
            "IBM Plex Serif"
          ];
        };

      sansSerif =
        mkOption (mkFontOption "sans-serif")
        // {
          default = [
            "DejaVu Sans"
            "Noto Sans"
            "Liberation Sans"
            "Ubuntu"
            "Cantarell"
            "IBM Plex Sans"
          ];
        };

      monospace =
        mkOption (mkFontOption "monospace")
        // {
          default = [
            "JetBrainsMono Nerd Font Mono" # Primary monospace font with icons
            "FiraCode Nerd Font Mono" # Secondary monospace font with icons
            "Hack Nerd Font Mono" # Additional monospace font with icons
            "RobotoMono Nerd Font Mono" # Another monospace font with icons
            "SourceCodePro Nerd Font Mono" # Yet another monospace font with icons
            "DejaVu Sans Mono" # Fallback monospace
            "Liberation Mono" # Final fallback
            "Terminus" # Alternative fallback
          ];
        };

      emoji =
        mkOption (mkFontOption "emoji")
        // {
          default = [
            "Noto Color Emoji"
            "Segoe UI Emoji"
          ];
        };
    };

    # Font rendering options
    rendering = {
      # Anti-aliasing settings
      antialias = mkOption {
        type = types.bool;
        default = true;
        description = "Enable font anti-aliasing";
      };

      # Sub-pixel rendering settings
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

      # Hinting settings
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

  config = mkIf (config.modules.desktop.enable && cfg.enable) {
    fonts = {
      # Enable font directory
      fontDir.enable = true;

      # Install font packages
      packages = cfg.packages;

      # Enable default font packages
      enableDefaultPackages = cfg.enableDefaultPackages;

      # Font configuration
      fontconfig = {
        # Default fonts configuration
        defaultFonts = cfg.defaultFonts;

        # Font rendering configuration
        antialias = cfg.rendering.antialias;
        subpixel = {
          rgba = cfg.rendering.subpixel.rgba;
          lcdfilter = "default";
        };

        # Hinting configuration
        hinting = {
          enable = cfg.rendering.hinting.enable;
          style = cfg.rendering.hinting.style;
        };

        # Additional fontconfig configuration - Fix for the XML error
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
                <string>Hack Nerd Font Mono</string>
                <string>RobotoMono Nerd Font Mono</string>
                <string>SourceCodePro Nerd Font Mono</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };

    # Install font management tools
    environment.systemPackages = with pkgs; [
      fontconfig # Font configuration utility
      gnome-font-viewer # GUI font viewer
      font-manager # Advanced font management
    ];

    # Add fontconfig cache directories
    system.activationScripts.fonts.text = ''
      echo "Setting up fontconfig cache directories..."
      mkdir -p /var/cache/fontconfig
      chmod 755 /var/cache/fontconfig
    '';
  };
}
