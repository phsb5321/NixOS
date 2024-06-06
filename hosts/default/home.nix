{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  # User and Home Directory Configuration
  home.username = "notroot";
  home.homeDirectory = "/home/notroot";
  home.stateVersion = "23.11"; # Compatible Home Manager release version

  # Package Installation
  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    fish
    kitty
    grc
    eza

    # Development Tools
    nodejs_22 # Necessary for copilot nvim plugin

    # Ebooks
    calibre

    # Virtualization
    virt-manager
    qemu
  ];

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Initialize zoxide for fish
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # Initialize Zellij
      set -gx ZELLIJ_AUTO_ATTACH false # Zellij will not attach to the current session

      set -gx ZELLIJ_AUTO_EXIT false # Zellij will not exit when the last pane is closed

      # Set ZELLIJ_AUTO_START to fish
      #   eval (zellij setup --generate-auto-start fish | string collect)

    '';
    shellAliases = {
      vim = "nvim";
      fishconfig = "source ~/.config/fish/config.fish";
      textractor = "~/NixOS/user-scripts/file-text-extractor";
      nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh default"; # Default flake
      ls = "eza -l --icons";
    };
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
  };

  #Kitty Configuration
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font.name = "JetBrainsMono Nerd Font";
    font.size = 18;
    shellIntegration.enableFishIntegration = true;
    settings = {
      copy_on_select = true;
      clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
    };
  };

  # Zellij Configuration
  programs.zellij = {
    enable = true;
    settings = {
      theme = "one-half-dark";
      default_shell = "fish";
    };
  };

  # Environment Variables
  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.fish}/bin/fish"; # Environment shell set to Fish
  };

  # Dotfiles Management
  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };



  # Home Manager Self-Management
  programs.home-manager.enable = true;

}
