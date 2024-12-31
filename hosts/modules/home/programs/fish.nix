# ~/NixOS/hosts/modules/home/programs/fish.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  config = mkIf cfg.enable {
    home-manager.users.${cfg.username} = {
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
          nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh ${cfg.hostName}";
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
    };
  };
}
