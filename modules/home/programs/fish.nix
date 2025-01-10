# ~/NixOS/hosts/modules/home/programs/fish.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.home;

  # Bass source with correct hash
  bass-src = pkgs.fetchFromGitHub {
    owner = "edc";
    repo = "bass";
    rev = "79b62958ecf4e87334f24d6743e5766475bcf4d0";
    sha256 = "sha256-3d/qL+hovNA4VMWZ0n1L+dSM1lcz7P5CQJyy+/8exTc=";
  };
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

          # POSIX compatibility function
          function posix
            command bash -c "$argv"
          end

          # Support for !! and !$
          function bind_bang
            switch (commandline -t)
              case "!"
                commandline -t $history[1]
                commandline -f repaint
              case "*"
                commandline -i !
            end
          end

          function bind_dollar
            switch (commandline -t)
              case "!"
                commandline -t ""
                commandline -f history-token-search-backward
              case "*"
                commandline -i '$'
            end
          end

          # Define custom CLI tool "vscatch" to open matching files in VSCode
          function vscatch
            for f in $argv; code $f; end
          end

          # Define custom CLI tool "zedcatch" to open matching files in Zed
          function zedcatch
            for f in $argv; zeditor $f; end
          end

          # Bind the history expansion keys
          bind ! bind_bang
          bind '$' bind_dollar

          # Better Ctrl+w behavior
          bind \c] backward-kill-word
        '';

        shellAliases = {
          fishconfig = "source ~/.config/fish/config.fish";
          textractor = "~/NixOS/user-scripts/textractor.sh";
          ls = "eza -l --icons";
          ll = "eza -la --icons";
          nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh ${cfg.hostName}";
          nix-select-shell = "~/NixOS/user-scripts/nix-shell-selector.sh";

          # Git shortcuts
          g = "git";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gst = "git status";
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
          {
            name = "bass";
            src = bass-src;
          }
        ];
      };
    };
  };
}
