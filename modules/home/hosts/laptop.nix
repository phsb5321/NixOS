# ~/NixOS/modules/home/hosts/laptop.nix
# Laptop-specific Home Manager configuration
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; {
  # Import shared configuration
  imports = [
    ../shared.nix
  ];

  # Laptop-specific packages (focused on mobility and battery life)
  home.packages = with pkgs; [
    # Development Tools - Laptop optimized
    vscode
    dbeaver-bin

    # Media - Lightweight options
    amberol # Lightweight music player
    vlc

    # Communication - Essential only
    discord
    telegram-desktop

    # Productivity - Mobile work
    # obsidian  # Temporarily disabled due to network issues
    libreoffice

    # Network and Remote tools
    remmina
    ngrok

    # Laptop-specific utilities
    brightnessctl
    acpi
    powertop
    tlp

    # LaTeX for documents on the go
    texlive.combined.scheme-full

    # Terminal multiplexer for mobile development
    zellij
    tmux
  ];

  # Laptop-specific program configurations
  programs = {
    # Terminal configuration optimized for laptop screen
    kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 11; # Slightly smaller for laptop screen
        enable_audio_bell = false;

        # Laptop-optimized colors (battery friendly)
        foreground = "#e0e0e0";
        background = "#1a1a1a";

        # Window settings for laptop
        window_padding_width = 4; # Less padding for smaller screen
        remember_window_size = true;
        initial_window_width = 1000;
        initial_window_height = 600;

        # Battery optimizations
        sync_to_monitor = false;
        repaint_delay = 10;
      };
    };

    # VSCode with laptop-specific optimizations
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        rust-lang.rust-analyzer
        esbenp.prettier-vscode
        ms-vscode.vscode-typescript-next
        ms-vscode-remote.remote-ssh
        jnoortheen.nix-ide
      ];

      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
        "editor.fontSize" = 13; # Optimized for laptop screen
        "editor.lineHeight" = 1.4;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
        "workbench.colorTheme" = "Default Dark+";
        "editor.formatOnSave" = true;
        "files.autoSave" = "afterDelay";
        "editor.minimap.enabled" = false; # Disable minimap to save space
        "editor.rulers" = [80];

        # Battery optimizations
        "editor.cursorBlinking" = "solid";
        "editor.smoothScrolling" = false;
        "workbench.animations" = false;
        "editor.fontLigatures" = false;
      };
    };

    # Tmux for session management
    tmux = {
      enable = true;
      shortcut = "a";
      aggressiveResize = true;
      baseIndex = 1;
      newSession = true;
      escapeTime = 0;

      extraConfig = ''
        # Laptop-specific tmux configuration
        set -g status-keys vi
        set -g mode-keys vi

        # Better mouse support
        set -g mouse on

        # Status bar
        set -g status-style 'bg=#1a1a1a fg=#e0e0e0'
        set -g status-left-length 40
        set -g status-left '#[fg=#00ff00]#S #[default]'
        set -g status-right '#[fg=#ffff00]%Y-%m-%d %H:%M#[default]'

        # Window navigation
        bind -n M-h previous-window
        bind -n M-l next-window
      '';
    };

    # Zellij as modern terminal multiplexer
    zellij = {
      enable = true;

      settings = {
        theme = "dark";

        keybinds = {
          normal = {
            "bind \"Alt h\"" = {MoveFocus = "Left";};
            "bind \"Alt j\"" = {MoveFocus = "Down";};
            "bind \"Alt k\"" = {MoveFocus = "Up";};
            "bind \"Alt l\"" = {MoveFocus = "Right";};
          };
        };
      };
    };
  };

  # Laptop-specific dotfiles and configurations
  home.file = {
    # Power management configuration
    ".config/powertop/powertop.conf".text = ''
      # Laptop power optimization
      echo 'auto' > '/sys/bus/pci/devices/0000:00:1f.3/power/control'
      echo 'auto' > '/sys/bus/i2c/devices/i2c-0/device/power/control'
    '';

    # Laptop-specific Git configuration
    ".gitconfig-laptop".text = ''
      [user]
        name = Pedro Balbino
        email = pehdroobalbinoo@gmail.com
      [core]
        editor = nvim
      [push]
        autoSetupRemote = true
      [pull]
        rebase = false
      [init]
        defaultBranch = main
      [alias]
        # Laptop-optimized git aliases
        s = status -s
        l = log --oneline -10
        b = branch
        co = checkout
        sync = !git pull && git push
    '';
  };

  # Laptop environment variables
  home.sessionVariables = {
    # Battery optimization
    POWERTOP_ENABLE = "1";

    # Development optimizations for mobile work
    DOCKER_BUILDKIT = "1";
    COMPOSE_DOCKER_CLI_BUILD = "1";

    # Terminal optimization
    TERM = "xterm-256color";
    COLORTERM = "truecolor";
  };

  # Laptop-specific services
  services = {
    # Automatic screen brightness adjustment
    gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6500;
        night = 4500;
      };
    };
  };
}
