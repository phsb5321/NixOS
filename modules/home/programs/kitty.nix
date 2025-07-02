# ~/NixOS/modules/home/programs/kitty.nix
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
    # System-level Kitty package installation for proper GNOME integration
    environment.systemPackages = with pkgs; [
      kitty
    ];

    # Home Manager configuration for Kitty
    home-manager.users.${cfg.username} = {
      # Kitty configuration
      programs.kitty = {
        enable = true;
        package = pkgs.kitty;

        # Font configuration optimized for programming
        font = {
          name = "JetBrainsMono Nerd Font Mono";
          size = 12;
        };

        # Use a theme that respects GNOME's dark/light preference
        themeFile =
          if desktopCfg.theming.preferDark
          then "tokyo_night_night"
          else "tokyo_night_day";

        # Enable shell integrations for better terminal experience
        shellIntegration = {
          enableBashIntegration = true;
          enableZshIntegration = true;
          enableFishIntegration = true;
        };

        # Simplified settings for reliable GNOME + Wayland experience
        settings = {
          # CRITICAL FIX: Graphics rendering for NixOS 25.05 + GNOME
          # This fixes button rendering and other display issues
          env = "GSK_RENDERER=opengl";

          # Terminal behavior
          scrollback_lines = 10000;
          wheel_scroll_multiplier = 3.0;

          # Audio and visual feedback
          enable_audio_bell = false;
          visual_bell_duration = 0.0;

          # Text selection and clipboard (essential for GNOME)
          copy_on_select = true;
          strip_trailing_spaces = "smart";
          select_by_word_characters = "@-./_~?&=%+#";

          # Window appearance - simplified for stability
          remember_window_size = true;
          initial_window_width = "120c";
          initial_window_height = "30c";
          window_padding_width = 8;
          window_margin_width = 0;
          draw_minimal_borders = true;
          resize_in_steps = false;

          # Background and transparency
          background_opacity = 0.95;
          dynamic_background_opacity = true;

          # Cursor configuration
          cursor_shape = "block";
          cursor_blink_interval = -1;
          cursor_stop_blinking_after = 15.0;

          # Font rendering
          disable_ligatures = "never";
          text_composition_strategy = "platform";

          # Tab bar
          tab_bar_edge = "bottom";
          tab_bar_style = "powerline";
          tab_bar_min_tabs = 2;
          tab_switch_strategy = "previous";
          tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}";

          # Performance optimizations
          repaint_delay = 10;
          input_delay = 3;
          sync_to_monitor = true;

          # Wayland-specific optimizations for GNOME
          wayland_titlebar_color = "system";
          linux_display_server = "auto";

          # URL handling
          url_color = "#0087bd";
          url_style = "curly";
          open_url_with = "default";
          detect_urls = true;

          # Mouse behavior
          mouse_hide_wait = 3.0;

          # Window management
          confirm_os_window_close = 1;
          close_on_child_death = false;

          # Shell integration
          shell_integration = "enabled";
          term = "xterm-kitty";
        };

        # Essential key bindings for GNOME workflow
        keybindings = {
          # Tab management
          "ctrl+shift+t" = "new_tab";
          "ctrl+shift+w" = "close_tab";
          "ctrl+shift+q" = "close_os_window";
          "ctrl+shift+right" = "next_tab";
          "ctrl+shift+left" = "previous_tab";

          # Window management
          "ctrl+shift+enter" = "new_window";
          "ctrl+shift+n" = "new_os_window";
          "f11" = "toggle_fullscreen";

          # Font size
          "ctrl+shift+equal" = "change_font_size all +2.0";
          "ctrl+shift+minus" = "change_font_size all -2.0";
          "ctrl+shift+backspace" = "change_font_size all 0";

          # Clipboard
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";

          # Scrolling
          "ctrl+shift+up" = "scroll_line_up";
          "ctrl+shift+down" = "scroll_line_down";
          "ctrl+shift+page_up" = "scroll_page_up";
          "ctrl+shift+page_down" = "scroll_page_down";
          "ctrl+shift+home" = "scroll_home";
          "ctrl+shift+end" = "scroll_end";

          # GNOME-style shortcuts
          "ctrl+alt+t" = "new_os_window";
        };

        # Environment variables for optimal GNOME integration
        environment = {
          # CRITICAL: GSK renderer fix for GNOME rendering issues
          "GSK_RENDERER" = "opengl";

          # Wayland support
          "KITTY_ENABLE_WAYLAND" = "1";
          "KITTY_WAYLAND_DETECT_MODIFIERS" = "1";

          # Integration with GNOME
          "TERMINAL" = "kitty";
        };
      };

      # Set up desktop integration for GNOME
      xdg.desktopEntries.kitty = {
        name = "Kitty";
        comment = "Fast, feature-rich, GPU based terminal emulator";
        icon = "kitty";
        exec = "kitty";
        categories = ["System" "TerminalEmulator"];
        mimeType = ["application/x-shellscript" "text/plain"];
        startupNotify = true;
        settings = {
          Keywords = "shell;prompt;command;commandline;cmd;terminal;tty;";
          StartupWMClass = "kitty";
        };
      };

      # Configure Kitty as default terminal for GNOME
      dconf.settings = {
        "org/gnome/desktop/default-applications/terminal" = {
          exec = "kitty";
          exec-arg = "";
        };
      };

      # Set environment variables for terminal detection
      home.sessionVariables = {
        TERMINAL = "kitty";
        TERM = lib.mkDefault "xterm-kitty";
        # Critical GSK renderer fix for user session
        GSK_RENDERER = "opengl";
      };

      # Shell aliases for easy access
      programs.bash.shellAliases = {
        terminal = "kitty";
        term = "kitty";
      };

      programs.zsh.shellAliases = {
        terminal = "kitty";
        term = "kitty";
      };
    };

    # System-level gsettings for default terminal
    programs.dconf.profiles.user.databases = [
      {
        settings = {
          "org/gnome/desktop/default-applications/terminal" = {
            exec = "kitty";
            exec-arg = "";
          };
        };
      }
    ];
  };
}
