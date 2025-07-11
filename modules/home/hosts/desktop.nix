# ~/NixOS/modules/home/hosts/desktop.nix
# Desktop-specific Home Manager configuration
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

  # Desktop-specific packages
  home.packages = with pkgs; [
    # Development Tools - Desktop specific
    postman
    dbeaver-bin
    android-studio
    android-tools
    calibre
    anydesk

    # Media and Graphics - Desktop workstation
    gimp
    inkscape
    blender
    krita
    kdenlive
    obs-studio

    # Communication - Desktop
    discord
    telegram-desktop
    slack
    zoom-us

    # Gaming (desktop only)
    steam
    lutris
    wine
    winetricks

    # Productivity - Desktop
    obsidian
    notion-app-enhanced

    # AMD GPU specific tools
    vulkan-tools
    vulkan-loader
    vulkan-validation-layers
    libva-utils
    vdpauinfo
    glxinfo

    # System monitoring
    htop
    btop
    nvtop-amd
    lact
  ];

  # Desktop-specific program configurations
  programs = {
    # Terminal configuration for desktop
    kitty = {
      enable = true;
      settings = {
        font_family = "JetBrainsMono Nerd Font";
        font_size = 12;
        enable_audio_bell = false;

        # Desktop-optimized colors
        foreground = "#f8f8f2";
        background = "#282a36";

        # Window settings for large monitor
        window_padding_width = 8;
        remember_window_size = true;
        initial_window_width = 1200;
        initial_window_height = 800;
      };
    };

    # VSCode with desktop-specific extensions
    vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        ms-python.python
        ms-vscode.cpptools
        rust-lang.rust-analyzer
        bradlc.vscode-tailwindcss
        esbenp.prettier-vscode
        ms-vscode.vscode-typescript-next
        ms-vscode-remote.remote-ssh
        ms-vscode.hexeditor
        jnoortheen.nix-ide
      ];

      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'monospace'";
        "editor.fontSize" = 14;
        "editor.lineHeight" = 1.5;
        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
        "workbench.colorTheme" = "Default Dark+";
        "editor.formatOnSave" = true;
        "files.autoSave" = "afterDelay";
        "editor.minimap.enabled" = true;
        "editor.rulers" = [80 120];
      };
    };
  };

  # Desktop-specific dotfiles and configurations
  home.file = {
    # LACT configuration for AMD GPU
    ".config/lact/config.yaml".text = ''
      daemon:
        log_level: warn
        admin_groups:
          - wheel
    '';
  };

  # Desktop environment variables
  home.sessionVariables = {
    # AMD GPU optimizations
    AMD_VULKAN_ICD = "RADV";
    RADV_PERFTEST = "gpl";

    # Desktop development
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };
}
