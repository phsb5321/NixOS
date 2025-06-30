# ~/NixOS/modules/home/programs/ghostty.nix
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
    # Ensure terminfo database is properly available system-wide
    environment.systemPackages = with pkgs; [
      ghostty
      ncurses # Provides terminfo tools
    ];

    # Create system-wide terminfo for Ghostty compatibility
    environment.pathsToLink = [
      "/share/terminfo"
    ];

    home-manager.users.${cfg.username} = {
      programs.ghostty = {
        enable = true;
        package = pkgs.ghostty;
        enableZshIntegration = true;
        settings = {
          # Terminal configuration for maximum compatibility
          shell = "${pkgs.zsh}/bin/zsh";
          command_flags = ["-l"];

          # Use standard terminal type for SSH compatibility
          term = "xterm-256color";

          # Font configuration with fallbacks
          font_family = "JetBrainsMono Nerd Font";
          font_size = 12;
          font_feature = [
            "ss01" # Stylistic set 1
            "ss02" # Stylistic set 2
          ];

          # Theme and appearance
          theme = "catppuccin-mocha";
          background_opacity = 0.95;

          # Window settings
          window_padding_x = 8;
          window_padding_y = 8;
          window_decoration = true;

          # Performance and rendering optimizations
          gpu_renderer = "opengl";
          renderer = "opengl";

          # Terminal behavior
          scrollback_lines = 10000;
          mouse_hide_while_typing = true;

          # Copy/paste behavior
          copy_on_select = false;
          click_repeat_interval = 500;

          # Bell configuration
          audible_bell = false;
          visual_bell = true;

          # Cursor configuration
          cursor_style = "block";
          cursor_style_blink = false;

          # Key bindings optimization
          macos_non_native_fullscreen = false;
        };
      };

      # Ensure proper terminfo setup for SSH compatibility
      home.packages = with pkgs; [
        ghostty
        ncurses # For infocmp and tic commands
      ];

      # Set up environment variables for terminal compatibility
      home.sessionVariables = {
        # Use xterm-256color for SSH sessions and compatibility
        TERM = "xterm-256color";
        # Ensure terminfo database path is available
        TERMINFO_DIRS = "$HOME/.local/share/terminfo:/run/current-system/sw/share/terminfo:/usr/share/terminfo";
      };

      # Create local terminfo directory and copy Ghostty terminfo
      home.file = {
        # Create terminfo directory structure
        ".local/share/terminfo/.keep".text = "";

        # Copy Ghostty terminfo if available
        ".local/share/terminfo/x/xterm-ghostty" = mkIf (pathExists "${pkgs.ghostty}/share/terminfo/x/xterm-ghostty") {
          source = "${pkgs.ghostty}/share/terminfo/x/xterm-ghostty";
        };

        # Create a script to export terminfo for remote servers
        ".local/bin/export-ghostty-terminfo" = {
          text = ''
            #!/usr/bin/env bash
            # Export Ghostty terminfo for remote server installation

            if command -v infocmp >/dev/null 2>&1; then
              if infocmp xterm-ghostty >/dev/null 2>&1; then
                echo "# To install on remote server, run:"
                echo "# infocmp xterm-ghostty | ssh user@host 'tic -x -'"
                echo ""
                infocmp xterm-ghostty
              else
                echo "Error: xterm-ghostty terminfo not found"
                echo "Make sure Ghostty is properly installed"
                exit 1
              fi
            else
              echo "Error: infocmp command not found"
              echo "Install ncurses package"
              exit 1
            fi
          '';
          executable = true;
        };
      };

      # ZSH integration for better terminal compatibility
      programs.zsh = {
        sessionVariables = {
          # Ensure proper terminal detection
          TERM = "xterm-256color";
        };

        shellAliases = {
          # Add alias for easy terminfo export
          export-terminfo = "$HOME/.local/bin/export-ghostty-terminfo";
        };

        initExtra = ''
          # Ghostty terminal integration
          if [[ "$TERM" == "xterm-ghostty" ]]; then
            # Set fallback TERM for better compatibility
            export TERM="xterm-256color"
          fi

          # Function to install terminfo on remote servers
          install-terminfo() {
            if [[ -z "$1" ]]; then
              echo "Usage: install-terminfo user@hostname"
              return 1
            fi

            if command -v infocmp >/dev/null 2>&1; then
              if infocmp xterm-ghostty >/dev/null 2>&1; then
                echo "Installing Ghostty terminfo on $1..."
                infocmp xterm-ghostty | ssh "$1" 'tic -x -'
                echo "Terminfo installed successfully"
              else
                echo "Error: xterm-ghostty terminfo not found locally"
                return 1
              fi
            else
              echo "Error: infocmp command not found"
              return 1
            fi
          }
        '';
      };
    };
  };
}
