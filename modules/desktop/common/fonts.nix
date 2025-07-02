# ~/NixOS/modules/desktop/common/fonts.nix
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
        # 🔥 CRITICAL: Nerd Fonts with Symbols (FIXES EMOJI ISSUES)
        nerd-fonts.symbols-only          # 🎯 THE KEY MISSING COMPONENT!
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.roboto-mono
        nerd-fonts.source-code-pro
        nerd-fonts.hack
        nerd-fonts.noto                  # Noto with Nerd Font patches

        # 🎨 Enhanced Emoji Support
        noto-fonts-color-emoji           # Primary emoji font (best compatibility)
        
        # 📝 Standard fonts for comprehensive coverage
        font-awesome                     # Icon font for web/applications
        noto-fonts                       # Google's unicode coverage
        noto-fonts-cjk-sans             # CJK support (Chinese, Japanese, Korean)
        noto-fonts-extra                 # Extended Noto fonts
        liberation_ttf                   # Microsoft-compatible fonts
        xorg.font-misc-misc             # Basic X11 fonts

        # 🖋️ High-quality fonts for better rendering
        ubuntu_font_family              # Ubuntu's font family
        dejavu_fonts                    # DejaVu font family (excellent fallback)
        source-code-pro                 # Adobe's monospace font
        freetype                        # TrueType rendering engine
        cantarell-fonts                 # GNOME default fonts
        droid-fonts                     # Android "Droid" fonts
        ibm-plex                        # IBM's Plex font family
        terminus_font                   # Terminus monospace font
        
        # 🔤 Additional professional fonts
        cascadia-code                   # Microsoft's programming font
        iosevka                         # Versatile monospace font
        inter                           # Modern sans-serif font
        jetbrains-mono                  # JetBrains programming font (non-Nerd version)
        fira-code                       # Mozilla's programming font
      ];
      description = ''
        Comprehensive font packages including Nerd Fonts with symbols, emoji support,
        and professional fonts for optimal rendering across all applications.
      '';
    };

    # Enable default font packages
    enableDefaultPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable the default NixOS font packages";
    };

    # 🎯 Enhanced Default font configurations
    defaultFonts = {
      serif =
        mkOption (mkFontOption "serif")
        // {
          default = [
            "Noto Serif"
            "DejaVu Serif"
            "Liberation Serif"
            "Cantarell"
            "IBM Plex Serif"
          ];
        };

      sansSerif =
        mkOption (mkFontOption "sans-serif")
        // {
          default = [
            "Inter"                      # Modern, clean sans-serif
            "Noto Sans"
            "DejaVu Sans"
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
            "JetBrainsMono Nerd Font Mono"    # Primary with icons
            "CascadiaCode Nerd Font Mono"     # Microsoft's excellent programming font
            "FiraCode Nerd Font Mono"         # Secondary with ligatures
            "Hack Nerd Font Mono"             # Clean monospace with icons
            "RobotoMono Nerd Font Mono"       # Google's monospace with icons
            "SourceCodePro Nerd Font Mono"    # Adobe's monospace with icons
            "Iosevka Nerd Font Mono"          # Versatile monospace with icons
            "DejaVu Sans Mono"                # Reliable fallback
            "Liberation Mono"                 # Final fallback
          ];
        };

      emoji =
        mkOption (mkFontOption "emoji")
        // {
          default = [
            "Noto Color Emoji"          # Primary emoji font
            "Symbols Nerd Font Mono"    # 🎯 CRITICAL: Nerd Font symbols
            "Symbols Nerd Font"         # 🎯 CRITICAL: Non-mono variant
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

        # 🚀 COMPREHENSIVE FONTCONFIG - FIXES ALL EMOJI/NERD FONT ISSUES
        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>
            <!-- 🚫 Disable bitmap fonts for better rendering -->
            <selectfont>
              <rejectfont>
                <pattern>
                  <patelt name="scalable"><bool>false</bool></patelt>
                </pattern>
              </rejectfont>
            </selectfont>

            <!-- 🔧 Enable TrueType hinting -->
            <match target="font">
              <edit name="hinting" mode="assign"><bool>true</bool></edit>
              <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
              <edit name="antialias" mode="assign"><bool>true</bool></edit>
            </match>

            <!-- 🎯 CRITICAL: Nerd Fonts configuration for monospace -->
            <match target="pattern">
              <test name="family" qual="any">
                <string>monospace</string>
              </test>
              <edit binding="same" mode="prepend" name="family">
                <string>JetBrainsMono Nerd Font Mono</string>
                <string>CascadiaCode Nerd Font Mono</string>
                <string>FiraCode Nerd Font Mono</string>
                <string>Hack Nerd Font Mono</string>
                <string>RobotoMono Nerd Font Mono</string>
                <string>SourceCodePro Nerd Font Mono</string>
                <string>Iosevka Nerd Font Mono</string>
              </edit>
            </match>

            <!-- 🎨 EMOJI SUPPORT: Universal emoji fallback for ALL font families -->
            <match target="pattern">
              <test name="family"><string>serif</string></test>
              <edit name="family" mode="append_last">
                <string>Noto Color Emoji</string>
                <string>Symbols Nerd Font</string>
              </edit>
            </match>

            <match target="pattern">
              <test name="family"><string>sans-serif</string></test>
              <edit name="family" mode="append_last">
                <string>Noto Color Emoji</string>
                <string>Symbols Nerd Font</string>
              </edit>
            </match>

            <match target="pattern">
              <test name="family"><string>monospace</string></test>
              <edit name="family" mode="append_last">
                <string>Noto Color Emoji</string>
                <string>Symbols Nerd Font Mono</string>
              </edit>
            </match>

            <!-- 🎯 SYMBOLS: Dedicated Nerd Font symbols mapping -->
            <match target="pattern">
              <test name="family"><string>FontAwesome</string></test>
              <edit name="family" mode="prepend">
                <string>Symbols Nerd Font</string>
                <string>Font Awesome 6 Free</string>
              </edit>
            </match>

            <!-- 📱 APP-SPECIFIC: Improve font substitution for application compatibility -->
            <match target="pattern">
              <test name="family"><string>Arial</string></test>
              <edit name="family" mode="prepend">
                <string>Liberation Sans</string>
                <string>DejaVu Sans</string>
              </edit>
            </match>

            <match target="pattern">
              <test name="family"><string>Times New Roman</string></test>
              <edit name="family" mode="prepend">
                <string>Liberation Serif</string>
                <string>DejaVu Serif</string>
              </edit>
            </match>

            <match target="pattern">
              <test name="family"><string>Courier New</string></test>
              <edit name="family" mode="prepend">
                <string>Liberation Mono</string>
                <string>DejaVu Sans Mono</string>
              </edit>
            </match>

            <!-- 🔤 CONSOLE/TERMINAL: Ensure proper monospace rendering -->
            <match target="pattern">
              <test name="family"><string>console</string></test>
              <edit name="family" mode="prepend">
                <string>JetBrainsMono Nerd Font Mono</string>
                <string>DejaVu Sans Mono</string>
              </edit>
            </match>

            <!-- 🎨 COLOR EMOJI: Force color emoji rendering -->
            <match target="font">
              <test name="family" qual="any">
                <string>Noto Color Emoji</string>
              </test>
              <edit name="color" mode="assign"><bool>true</bool></edit>
            </match>

            <!-- 📐 SIZE OPTIMIZATION: Prevent font size issues -->
            <match target="font">
              <test name="pixelsize" compare="less">
                <double>8</double>
              </test>
              <edit name="pixelsize" mode="assign">
                <double>8</double>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };

    # 🛠️ Install font management and debugging tools
    environment.systemPackages = with pkgs; [
      fontconfig              # Font configuration utility
      gnome-font-viewer       # GUI font viewer
      font-manager            # Advanced font management
      gucharmap               # Unicode character viewer
    ];

    # 🔄 Font cache setup and regeneration
    system.activationScripts.fonts = {
      text = ''
        echo "🔄 Setting up enhanced fontconfig cache..."
        
        # Create cache directories
        mkdir -p /var/cache/fontconfig
        chmod 755 /var/cache/fontconfig
        
        # User cache directories
        for user_home in /home/*; do
          if [ -d "$user_home" ]; then
            user=$(basename "$user_home")
            mkdir -p "$user_home/.cache/fontconfig"
            chown "$user:users" "$user_home/.cache/fontconfig" 2>/dev/null || true
          fi
        done
        
        # Force font cache regeneration
        echo "♻️  Regenerating font cache..."
        ${pkgs.fontconfig}/bin/fc-cache -rf
        
        echo "✅ Font configuration complete!"
        echo "🎯 Emoji and Nerd Font support enabled"
      '';
      deps = ["users"];
    };

    # 🔧 Additional system configuration for better font rendering
    environment.variables = {
      # Ensure fontconfig finds all fonts
      FONTCONFIG_PATH = "${config.fonts.fontconfig.confPackages}";
      
      # Better font rendering in applications
      GDK_USE_XFT = "1";
      QT_XFT = "true";
      
      # Enable color emoji in applications
      GNOME_DISABLE_EMOJI_PICKER = "0";
    };
  };
}
