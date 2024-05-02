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
    settings = {
      confirm_os_window_close = -0;
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
      dashboard.enable = true;
      nvim-tree = {
        enable = true;
        openOnSetupFile = true;
        autoReloadOnWrite = true;
      };
      treesitter = {
        enable = true;
        nixGrammars = true;
        indent = true;
      };
      treesitter-context.enable = true;
      rainbow-delimiters.enable = true;
      obsidian.enable = true;
      lsp = {
        enable = true;
        servers = {
          tsserver.enable = true; # JavaScript/TypeScript
          lua-ls.enable = true; # Lua
          rust-analyzer = { enable = true; installCargo = true; installRustc = true; }; # Rust
        };
        keymaps.lspBuf = {
          "gd" = "definition";
          "gD" = "references";
          "gt" = "type_definition";
          "gi" = "implementation";
          "K" = "hover";
        };
      };
      rust-tools.enable = true;
    };
    globals.mapleader = " ";
    keymaps = [
      { key = "<leader>n"; action = "<cmd>NvimTreeToggle<cr>"; }
      # Global Mappings
      # Default mode is "" which means normal-visual-op
      {
        # Toggle NvimTree
        key = "<C-n>";
        action = "<CMD>NvimTreeToggle<CR>";
      }
      {
        # Format file
        key = "<leader>fm";
        action = "<CMD>lua vim.lsp.buf.format()<CR>";
      }

      # Terminal Mappings
      {
        # Escape terminal mode using ESC
        mode = "t";
        key = "<esc>";
        action = "<C-\\><C-n>";
      }

      # Rust
      {
        # Start standalone rust-analyzer (fixes issues when opening files from nvim tree)
        mode = "n";
        key = "<leader>rs";
        action = "<CMD>RustStartStandaloneServerForBuffer<CR>";
      }

    ];
  };
}
