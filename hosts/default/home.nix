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
    fishPlugins.tide
  ];

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

  # NixVim Configuration
  programs.nixvim = {
    enable = true;
    enableMan = true;
    opts = {
      number = true; # Show line numbers
      relativenumber = true; # Show relative line numbers

      shiftwidth = 2; # Tab width should be 2
    };
    plugins = {
      bufferline.enable = true;
      lualine.enable = true;
      fzf-lua.enable = true;
      dashboard = {
        enable = true;
      };
      nvim-tree.enable = true;
      treesitter.enable = true;
      obsidian.enable = true;
      lsp = {
        enable = true;
        servers = {
          tsserver.enable = true; # JavaScript/TypeScript
          lua-ls.enable = true; # Lua
          rust-analyzer = { enable = true; installCargo = true; installRustc = true; }; # Rust
        };
      };
    };
    keymaps = [
      { key = "<leader>n"; action = "<cmd>NvimTreeToggle<cr>"; }
    ];
  };
}
