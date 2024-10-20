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
      fish
      eza
      htop
      neofetch
      git
      gh
      wget
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

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 14;
    };
    settings = {
      copy_on_select = true;
      enable_ligatures = true;
      # Tokyo Night theme colors
      background = "#1a1b26";
      foreground = "#c0caf5";
      selection_background = "#33467C";
      selection_foreground = "#c0caf5";
      url_color = "#73daca";
      cursor = "#c0caf5";
      # normal
      color0 = "#15161E";
      color1 = "#f7768e";
      color2 = "#9ece6a";
      color3 = "#e0af68";
      color4 = "#7aa2f7";
      color5 = "#bb9af7";
      color6 = "#7dcfff";
      color7 = "#a9b1d6";
      # bright
      color8 = "#414868";
      color9 = "#f7768e";
      color10 = "#9ece6a";
      color11 = "#e0af68";
      color12 = "#7aa2f7";
      color13 = "#bb9af7";
      color14 = "#7dcfff";
      color15 = "#c0caf5";
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
        settings = { };
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

  # Wayland and Hyprland configuration
  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true; # Changed from systemdIntegration
    xwayland.enable = true;
  };

  # Home Manager Self-Management
  programs.home-manager.enable = true;
}
