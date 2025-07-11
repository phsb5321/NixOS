# ~/NixOS/hosts/modules/home/programs/nixvim.nix
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username} = {
      programs.nixvim = {
        enable = true;
        colorschemes.gruvbox = {
          enable = true;
        };

        globals.mapleader = " ";

        opts = {
          number = true;
          shiftwidth = 2;
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
              conceallevel = 2;
              daily_notes = {
                folder = "3. Resources/Daily";
                date_format = "%Y/%m-%B/%d (%A)";
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
          # neo-tree = {  # Temporarily disabled due to network issues
          #   enable = true;
          #   closeIfLastWindow = true;
          #   window.width = 30;
          # };
          which-key.enable = true;
          comment.enable = true;
          nvim-autopairs.enable = true;
          neoscroll.enable = true;
          indent-blankline.enable = true;
          markdown-preview.enable = true;
          dashboard.enable = true;
          web-devicons.enable = true;
          copilot-vim = {
            enable = false;
            settings = {};
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
    };
  };
}
