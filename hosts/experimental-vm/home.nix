{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  home = {
    username = "notroot";
    homeDirectory = "/home/notroot";
    stateVersion = "24.05";

    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      noto-fonts-emoji
      noto-fonts
      fish
      kitty
      eza
      htop
      neofetch
      git
      gh
      wget
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

  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };
    settings = {
      copy_on_select = true;
      enable_ligatures = true;
    };
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

  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;
    globals.mapleader = " ";
    options = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      expandtab = true;
      clipboard = "unnamedplus";
    };
    plugins = {
      lualine.enable = true;
      treesitter.enable = true;
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
        };
      };
      gitsigns.enable = true;
      which-key.enable = true;
      comment.enable = true;
    };
  };

  programs.home-manager.enable = true;
}
