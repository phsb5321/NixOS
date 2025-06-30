# ~/NixOS/modules/home/programs/ghostty.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.home;
  desktopCfg = config.modules.desktop;
in {
  config = mkIf cfg.enable {
    # Ensure Ghostty and dependencies are available system-wide
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
        enableBashIntegration = true;

        settings = {
          # Font configuration with excellent defaults
          font-family = "JetBrainsMono Nerd Font";
          font-style = "Regular";
          font-size = 13;
          font-thicken = true;

          # Font features for better programming experience
          adjust-underline-position = "40%";
          adjust-underline-thickness = "-60%";

          # Cursor configuration
          cursor-style = "block";
          cursor-style-blink = false;

          # Shell integration optimized for modern workflows
          shell-integration = "zsh";
          shell-integration-features = "no-cursor";

          # Window and padding configuration
          window-width = 120;
          window-height = 45;
          window-padding-x = 8;
          window-padding-y = 8;
          window-decoration = true;
          window-colorspace = "display-p3";

          # Behavior settings for better UX
          confirm-close-surface = false;
          clipboard-paste-protection = false;
          unfocused-split-opacity = "1.0";

          # Performance and rendering optimizations for GNOME/Wayland
          gtk-single-instance = true;
          gtk-wide-tabs = true;
          gtk-adwaita = true;

          # Terminal behavior
          scrollback-lines = 10000;
          mouse-hide-while-typing = true;
          copy-on-select = false;
          click-repeat-interval = 500;

          # Audio settings
          audible-bell = false;
          visual-bell = true;

          # Theme and appearance
          theme =
            if desktopCfg.theming.preferDark
            then "catppuccin-mocha"
            else "catppuccin-latte";
          background-opacity = 0.95;

          # Custom colors for better integration
          background =
            if desktopCfg.theming.preferDark
            then "#1e1e2e"
            else "#eff1f5";
          foreground =
            if desktopCfg.theming.preferDark
            then "#cdd6f4"
            else "#4c4f69";
          cursor-color =
            if desktopCfg.theming.preferDark
            then "#f38ba8"
            else "#dc8a78";

          # Selection colors
          selection-background =
            if desktopCfg.theming.preferDark
            then "#313244"
            else "#acb0be";
          selection-foreground =
            if desktopCfg.theming.preferDark
            then "#cdd6f4"
            else "#4c4f69";

          # Custom palette for accent colors
          palette = [
            "0=#45475a" # Black
            "1=#f38ba8" # Red
            "2=#a6e3a1" # Green
            "3=#f9e2af" # Yellow
            "4=#89b4fa" # Blue
            "5=#f5c2e7" # Magenta
            "6=#94e2d5" # Cyan
            "7=#bac2de" # White
            "8=#585b70" # Bright Black
            "9=#f38ba8" # Bright Red
            "10=#a6e3a1" # Bright Green
            "11=#f9e2af" # Bright Yellow
            "12=#89b4fa" # Bright Blue
            "13=#f5c2e7" # Bright Magenta
            "14=#94e2d5" # Bright Cyan
            "15=#a6adc8" # Bright White
          ];

          # Key bindings for productivity
          keybind = [
            "ctrl+shift+t=new_tab"
            "ctrl+shift+w=close_surface"
            "ctrl+shift+n=new_window"
            "ctrl+shift+c=copy_to_clipboard"
            "ctrl+shift+v=paste_from_clipboard"
            "ctrl+shift+equal=increase_font_size:1"
            "ctrl+shift+minus=decrease_font_size:1"
            "ctrl+shift+0=reset_font_size"
            "super+backslash=new_split:right"
            "super+shift+backslash=new_split:down"
            "f12=toggle_quick_terminal"
          ];

          # Advanced terminal features
          working-directory = "inherit";
          auto-update = "check";

          # Platform-specific optimizations for Linux/GNOME
          linux-cgroup = "systemd";
          linux-cgroup-memory-limit = "1GB";
          linux-cgroup-cpu-weight = 100;
        };
      };

      # Set up environment variables for proper terminal behavior
      home.sessionVariables = {
        # Critical GSK renderer fix for GNOME
        GSK_RENDERER = "opengl";

        # Terminal compatibility
        TERM = "xterm-256color";

        # Ensure terminfo database path is available
        TERMINFO_DIRS = "$HOME/.local/share/terminfo:/run/current-system/sw/share/terminfo:/usr/share/terminfo";
      };

      # Create desktop entry for proper GNOME integration
      xdg.desktopEntries.ghostty = {
        name = "Ghostty";
        comment = "A fast, native terminal emulator";
        icon = "ghostty";
        exec = "ghostty";
        categories = ["System" "TerminalEmulator"];
        mimeType = ["application/x-shellscript" "text/plain"];
        startupNotify = true;
        settings = {
          Keywords = "shell;prompt;command;commandline;cmd;terminal;tty;";
          StartupWMClass = "com.mitchellh.ghostty";
        };
      };

      # Configure Ghostty for GNOME default terminal (alternative to Kitty)
      # Uncomment these lines if you want Ghostty as default instead of Kitty
      # dconf.settings = {
      #   "org/gnome/desktop/default-applications/terminal" = {
      #     exec = "ghostty";
      #     exec-arg = "";
      #   };
      # };

      # Create local terminfo directory and setup
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
                echo "Using fallback xterm-256color terminfo"
                infocmp xterm-256color
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
        shellAliases = {
          # Add alias for easy terminfo export
          export-terminfo = "$HOME/.local/bin/export-ghostty-terminfo";
          ghostty-config = "ghostty +show-config";
        };

        initContent = ''
          # Ghostty terminal integration
          if [[ "$TERM" == "xterm-ghostty" ]]; then
            # Enhanced terminal capabilities
            export COLORTERM="truecolor"
          fi

          # Function to install terminfo on remote servers
          install-ghostty-terminfo() {
            if [[ -z "$1" ]]; then
              echo "Usage: install-ghostty-terminfo user@hostname"
              return 1
            fi

            if command -v infocmp >/dev/null 2>&1; then
              if infocmp xterm-ghostty >/dev/null 2>&1; then
                echo "Installing Ghostty terminfo on $1..."
                infocmp xterm-ghostty | ssh "$1" 'tic -x -'
                echo "Terminfo installed successfully"
              else
                echo "Ghostty terminfo not found, using xterm-256color fallback"
                infocmp xterm-256color | ssh "$1" 'tic -x -'
              fi
            else
              echo "Error: infocmp command not found"
              return 1
            fi
          }

          # Function to test Ghostty features
          test-ghostty() {
            echo "Testing Ghostty terminal capabilities..."
            echo "✓ Unicode: 🚀 🎉 ⚡ 🔥"
            echo "✓ Colors: $(tput setaf 1)Red$(tput setaf 2) Green$(tput setaf 4) Blue$(tput sgr0)"
            echo "✓ Bold: $(tput bold)Bold Text$(tput sgr0)"
            echo "✓ TERM: $TERM"
            echo "✓ Terminal: $(ps -p $$ -o comm=)"
          }
        '';
      };

      # Shell aliases for easy access
      programs.bash.shellAliases = {
        export-terminfo = "$HOME/.local/bin/export-ghostty-terminfo";
        ghostty-config = "ghostty +show-config";
      };
    };
  };
}
