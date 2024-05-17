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
  ];

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Initialize zoxide for fish
      ${pkgs.zoxide}/bin/zoxide init fish | source
    '';
    shellAliases = {
      vim = "nvim";
      fishconfig = "source ~/.config/fish/config.fish";
      textractor = "~/NixOS/user-scripts/file-text-extractor";
      nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh";
      ls = "eza -l --icons";
    };
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
    ];
  };

  #Kitty config
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font.name = "JetBrainsMono Nerd Font";
    shellIntegration.enableFishIntegration = true;
    settings = {
      copy_on_select = true;
      clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
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
