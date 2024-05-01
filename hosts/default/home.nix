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
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    plugins = [
      # Enable a plugin (here grc for colorized command output) from nixpkgs
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      # Manually packaging and enable a plugin
      {
        name = "z";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "z";
          rev = "e0e1b9dfdba362f8ab1ae8c1afc7ccf62b89f7eb";
          sha256 = "0dbnir6jbwjpjalz14snzd3cgdysgcs3raznsijd6savad3qhijc";
        };
      }
    ];
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
