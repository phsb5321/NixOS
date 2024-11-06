{
  config,
  pkgs,
  inputs,
  ...
}: {
  # Import External Modules
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];

  nixpkgs.config = {
    allowUnfree = true;
  };

  # User Configuration
  home = {
    username = "notroot";
    homeDirectory = "/home/notroot";
    stateVersion = "24.05"; # Ensure compatibility with Home Manager release
    packages = with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
      noto-fonts-emoji
      noto-fonts
      noto-fonts-cjk-sans
      fish
      kitty
      grc
      eza
      ffmpeg
      gh
      brave
      yazi-unwrapped
      texlive.combined.scheme-full
      dbeaver-bin
      amberol
      awscli2
      remmina
      obsidian
      inputs.nixvim
      ngrok
      calibre
    ];
    sessionVariables = {
      EDITOR = "nvim";
      SHELL = "${pkgs.fish}/bin/fish"; # Use Fish as default shell
    };
    file = {
      # ".screenrc".source = dotfiles/screenrc;
      # ".gradle/gradle.properties".text = '''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # ''';
    };
  };

  # Fish Shell Configuration
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Initialize zoxide for fish
      ${pkgs.zoxide}/bin/zoxide init fish | source

      # Zellij Settings
      set -gx ZELLIJ_AUTO_ATTACH false
      set -gx ZELLIJ_AUTO_EXIT false

      # Define custom CLI tool "vscatch" to open matching files in VSCode
      function vscatch
        for f in $argv; code $f; end
      end

      # Define custom CLI tool "zedcatch" to open matching files in Zed
      function zedcatch
        for f in $argv; zeditor $f; end
      end
    '';
    shellAliases = {
      fishconfig = "source ~/.config/fish/config.fish";
      textractor = "~/NixOS/user-scripts/textractor.sh";
      ls = "eza -l --icons";
      nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh laptop"; # Default flake
      nix-select-shell = "~/NixOS/user-scripts/nix-shell-selector.sh";
    };
    plugins = [
      {
        name = "tide";
        src = pkgs.fishPlugins.tide.src;
      }
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
    ];
  };

  # Kitty Terminal Configuration
  programs.kitty = {
    enable = true;
    theme = "Tokyo Night";
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 18;
    };
    shellIntegration.enableFishIntegration = true;
    settings = {
      copy_on_select = true;
      clipboard_control = "write-clipboard read-clipboard write-primary read-primary";
      enable_ligatures = true;
      # Add fallback fonts for better emoji support
      font_family = "JetBrainsMono Nerd Font, Noto Color Emoji, Noto Sans Symbols";
    };
  };

  # Zellij Terminal Multiplexer Configuration
  programs.zellij = {
    enable = true;
    settings = {
      theme = "one-half-dark";
      default_shell = "fish";
    };
  };

  # DConf Settings (specific to GNOME)
  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Enable and configure Git
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
      number = true; # Show line numbers
      shiftwidth = 2; # Tab width should be 2
      # Use xclip to copy to clipboard
      clipboard = "unnamedplus";
    };

    plugins = {
      lualine.enable = true;
      obsidian = {
        enable = true;
        settings = {
          workspaces = [
            {
              name = "Notes";
              path = "~/Documents/Obsidian/Notes";
            }
          ];
          conceallevel = 2; # Set conceal level (0-2)
          daily_notes = {
            folder = "3. Resources/Daily";
            date_format = "%Y/%B/%d (%A)";
          };
        };
      };
      treesitter = {
        enable = true;
        settings.ensure_installed = "all";
      };
      lsp = {
        enable = true;
        servers = {
          rust_analyzer = {
            enable = true;
            installCargo = true;
            installRustc = true;
          };
          pyright.enable = true;
          ts_ls.enable = true;
          nil_ls.enable = true;
        };
      };
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
      };
      gitsigns.enable = true;
      neo-tree = {
        enable = true;
        closeIfLastWindow = true;
        window.width = 30;
      };
      which-key.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      neoscroll.enable = true;
      indent-blankline.enable = true;
      markdown-preview.enable = true;
      dashboard.enable = true;
      web-devicons.enable = true;
      copilot-vim = {
        enable = true;
        settings = {};
      };
    };
    # Additional settings for Obsidian markdown files
    extraConfigLua = ''
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          vim.opt_local.conceallevel = 2
          vim.opt_local.concealcursor = 'n'
        end
      })
    '';
  };

  # Home Manager Self-Management
  programs.home-manager.enable = true;
}
