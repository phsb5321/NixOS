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
    # Use themeFile instead of theme
    themeFile = "${pkgs.kitty-themes}/share/kitty-themes/Tokyo_Night.conf";
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

  # NixVim Configuration
  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;

    # Global options
    globals.mapleader = " ";

    # General options
    options = {
      number = true; # Show line numbers
      shiftwidth = 2; # Tab width should be 2
      clipboard = "unnamedplus"; # Use system clipboard
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
          conceallevel = 2;
          daily_notes = {
            folder = "3. Resources/Daily";
            date_format = "%Y/%B/%d (%A)";
          };
        };
      };
      treesitter.enable = true;
      lsp = {
        enable = true;
        servers = {
          rust-analyzer.enable = true;
          pyright.enable = true;
          tsserver.enable = true;
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
      };
    };
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
    systemdIntegration = true;
    xwayland.enable = true;
  };

  # Waybar configuration
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      /* Your custom CSS here */
    '';
    settings = [{
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" "hyprland/mode" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" ];
      # Add more configuration as needed
    }];
  };

  # Home Manager Self-Management
  programs.home-manager.enable = true;
}
