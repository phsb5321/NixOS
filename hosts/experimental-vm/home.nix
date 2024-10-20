{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  nixpkgs.config.allowUnfree = true;

  home = {
    username = "notroot";
    homeDirectory = "/home/notroot";
    stateVersion = "24.05";

    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      noto-fonts-emoji
      noto-fonts
      eza
      htop
      zoxide
    ];

    sessionVariables = {
      EDITOR = "nvim";
      SHELL = "${pkgs.fish}/bin/fish";
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      ${pkgs.zoxide}/bin/zoxide init fish | source
    '';
    shellAliases = {
      ls = "eza -l --icons";
      nixswitch = "sudo nixos-rebuild switch --flake /home/notroot/NixOS/#experimental-vm";
      update = "cd ~/NixOS && git pull && nixswitch && cd -";
    };
    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
    ];
  };

  programs.git = {
    enable = true;
    userName = "Pedro Balbino";
    userEmail = "phsb5321@gmail.com";
    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "main";
    };
  };

  # NixVim Configuration
  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;

    # Global options
    globals.mapleader = " ";

    # General options
    opts = {
      number = true;
      shiftwidth = 2;
      clipboard = "unnamedplus";
    };

    plugins = {
      lualine.enable = true;
      treesitter.enable = true;
      telescope.enable = true;
      which-key.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      gitsigns.enable = true;
      web-devicons.enable = true;
    };
  };

  # Home Manager Self-Management
  programs.home-manager.enable = true;
}
