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
          name = "JetBrainsMono Nerd Font";
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

        # Comprehensive settings for optimal GNOME + Wayland experience
        settings = {
          # Terminal behavior
          scrollback_lines = 50000;
          scrollback_pager_history_size = 50000;
          wheel_scroll_multiplier = 3.0;
          touch_scroll_multiplier = 1.0;

          # Audio and visual feedback
          enable_audio_bell = false;
          visual_bell_duration = 0.0;
          window_alert_on_bell = true;
          bell_on_tab = "🔔 ";

          # Text selection and clipboard
          copy_on_select = true;
          strip_trailing_spaces = "smart";
          select_by_word_characters = "@-./_~?&=%+#";
          click_interval = "0.5";
          focus_follows_mouse = false;
          default_pointer_shape = "beam";
          pointer_shape_when_grabbed = "arrow";
          pointer_shape_when_dragging = "beam";

          # Clipboard integration (essential for GNOME)
          clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
          clipboard_max_size = 64;

          # Window appearance and layout
          remember_window_size = true;
          initial_window_width = "120c";
          initial_window_height = "30c";
          window_padding_width = 8;
          window_margin_width = 0;
          single_window_margin_width = -1;
          window_border_width = "0.5pt";
          draw_minimal_borders = true;
          window_logo_alpha = 0.4;
          window_logo_position = "bottom-right";
          resize_debounce_time = "0.1";
          resize_draw_strategy = "size";
          resize_in_steps = false;

          # Colors and styling
          background_opacity = 0.95;
          dynamic_background_opacity = true;
          dim_opacity = 0.75;
          selection_foreground = "none";
          selection_background = "none";

          # Cursor configuration
          cursor_shape = "block";
          cursor_beam_thickness = "1.5";
          cursor_underline_thickness = 2.0;
          cursor_blink_interval = -1;
          cursor_stop_blinking_after = 15.0;

          # Font rendering (optimized for modern displays)
          font_size = 12.0;
          force_ltr = false;
          adjust_line_height = "0";
          adjust_column_width = "0";
          adjust_baseline = 0;
          disable_ligatures = "never";
          font_features = "JetBrainsMono-Regular +zero +onum";
          box_drawing_scale = "0.001, 1, 1.5, 2";
          text_composition_strategy = "platform";
          text_fg_override_threshold = 0;

          # Tab bar
          tab_bar_edge = "bottom";
          tab_bar_margin_width = "0.0";
          tab_bar_margin_height = "0.0 0.0";
          tab_bar_style = "powerline";
          tab_bar_align = "left";
          tab_bar_min_tabs = 2;
          tab_switch_strategy = "previous";
          tab_fade = "0.25 0.5 0.75 1";
          tab_separator = " ┇";
          tab_powerline_style = "slanted";
          tab_activity_symbol = "🔥";
          tab_title_max_length = 0;
          tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}{' :{}' if layout_name == 'stack' and num_windows > 1 else ''}";

          # Advanced features
          allow_remote_control = "socket-only";
          listen_on = "unix:/tmp/kitty";
          update_check_interval = 24;
          file_transfer_confirmation_bypass = "";
          allow_hyperlinks = true;
          shell_integration = "enabled";
          term = "xterm-kitty";

          # Performance optimizations
          repaint_delay = 10;
          input_delay = 3;
          sync_to_monitor = true;

          # Wayland-specific optimizations
          wayland_titlebar_color = "system";
          linux_display_server = "auto";

          # URL handling
          url_color = "#0087bd";
          url_style = "curly";
          open_url_with = "default";
          url_prefixes = "file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh";
          detect_urls = true;
          url_excluded_characters = "";
          show_hyperlink_targets = false;

          # Mouse actions
          clear_all_mouse_actions = false;
          mouse_hide_wait = 3.0;

          # Window management
          confirm_os_window_close = 1;
          close_on_child_death = false;

          # Advanced Wayland features (if supported)
          background_blur = 0;
          background_image = "none";
          background_image_layout = "tiled";
          background_image_linear = false;
          background_tint = 0.0;
          background_tint_gaps = 1.0;
        };

        # Key bindings optimized for GNOME workflow
        keybindings = {
          # Tab management
          "ctrl+shift+t" = "new_tab";
          "ctrl+shift+w" = "close_tab";
          "ctrl+shift+q" = "close_os_window";
          "ctrl+shift+right" = "next_tab";
          "ctrl+shift+left" = "previous_tab";
          "ctrl+shift+." = "move_tab_forward";
          "ctrl+shift+," = "move_tab_backward";
          "ctrl+shift+alt+t" = "set_tab_title";

          # Window management
          "ctrl+shift+enter" = "new_window";
          "ctrl+shift+n" = "new_os_window";
          "f11" = "toggle_fullscreen";
          "ctrl+shift+u" = "kitten unicode_input";
          "ctrl+shift+f2" = "edit_config_file";

          # Font size
          "ctrl+shift+equal" = "change_font_size all +2.0";
          "ctrl+shift+plus" = "change_font_size all +2.0";
          "ctrl+shift+minus" = "change_font_size all -2.0";
          "ctrl+shift+backspace" = "change_font_size all 0";

          # Clipboard
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";
          "ctrl+shift+s" = "paste_from_selection";

          # Scrolling
          "ctrl+shift+up" = "scroll_line_up";
          "ctrl+shift+down" = "scroll_line_down";
          "ctrl+shift+page_up" = "scroll_page_up";
          "ctrl+shift+page_down" = "scroll_page_down";
          "ctrl+shift+home" = "scroll_home";
          "ctrl+shift+end" = "scroll_end";
          "ctrl+shift+h" = "show_scrollback";

          # Search
          "ctrl+shift+f" = "show_last_command_output";

          # Layouts
          "ctrl+shift+l" = "next_layout";
          "ctrl+shift+alt+l" = "goto_layout stack";

          # Hints (for URL/file opening)
          "ctrl+shift+e" = "open_url_with_hints";
          "ctrl+shift+p>f" = "kitten hints --type path --program @";
          "ctrl+shift+p>shift+f" = "kitten hints --type path";
          "ctrl+shift+p>l" = "kitten hints --type line --program @";
          "ctrl+shift+p>w" = "kitten hints --type word --program @";
          "ctrl+shift+p>h" = "kitten hints --type hash --program @";
          "ctrl+shift+p>n" = "kitten hints --type linenum";

          # Remote control
          "ctrl+shift+escape" = "kitty_shell window";

          # Miscellaneous
          "ctrl+shift+f5" = "load_config_file";
          "ctrl+shift+f6" = "debug_config";
          "f1" = "show_kitty_doc overview";

          # GNOME-style shortcuts
          "ctrl+alt+t" = "new_os_window";
        };

        # Environment variables for optimal GNOME integration
        environment = {
          # Ensure proper Wayland support
          "KITTY_ENABLE_WAYLAND" = "1";
          "KITTY_WAYLAND_DETECT_MODIFIERS" = "1";

          # Better font rendering
          "KITTY_DEVELOP" = "0";

          # Integration with GNOME
          "TERMINAL" = "kitty";

          # Performance
          "KITTY_CACHE_CONTROL" = "1";
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
        noDisplay = false;
        settings = {
          Keywords = "shell;prompt;command;commandline;cmd;terminal;tty;";
          StartupWMClass = "kitty";
          SingleMainWindow = "false";
          X-MultipleArgs = "false";
        };
        actions = {
          "new-window" = {
            name = "New Window";
            exec = "kitty";
          };
          "new-tab" = {
            name = "New Tab";
            exec = "kitty --single-instance";
          };
        };
      };

      # Configure Kitty as default terminal for GNOME
      dconf.settings = {
        "org/gnome/desktop/default-applications/terminal" = {
          exec = "kitty";
          exec-arg = "";
        };
      };

      # XDG terminal configuration for Ubuntu/GNOME (modern method)
      home.file.".config/xdg-terminals.list".text = ''
        kitty.desktop
        gnome-terminal.desktop
        org.gnome.Console.desktop
      '';

      home.file.".config/ubuntu-xdg-terminals.list".text = ''
        kitty.desktop
        gnome-terminal.desktop
        org.gnome.Console.desktop
      '';

      home.file.".config/gnome-xdg-terminals.list".text = ''
        kitty.desktop
        gnome-terminal.desktop
        org.gnome.Console.desktop
      '';

      # Set environment variables for terminal detection
      home.sessionVariables = {
        TERMINAL = "kitty";
        TERM = lib.mkDefault "xterm-kitty";
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
