# ~/NixOS/modules/home/programs/zsh.nix
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
    home-manager.users.${cfg.username}.programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      enableCompletion = true;
      autocd = true;
      defaultKeymap = "emacs";

      # replaced deprecated initExtra with initContent
      initContent = ''
        # zoxide integration
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

        # history opts
        setopt EXTENDED_HISTORY
        setopt SHARE_HISTORY
        setopt HIST_IGNORE_DUPS
        setopt NO_NOMATCH
        setopt GLOB_DOTS

        # dircolors
        if [ -x "$(command -v dircolors)" ]; then
          eval "$(dircolors -b)"
        fi

        autoload -U colors && colors
        autoload -Uz compinit && compinit
        bindkey '^[^?' backward-kill-word
        bindkey '^X^E' edit-command-line

        # starship prompt
        eval "$(${pkgs.starship}/bin/starship init zsh)"
      '';

      history = {
        size = 50000;
        save = 50000;
        path = "$HOME/.zsh_history";
        ignoreDups = true;
        share = true;
        extended = true;
      };

      shellAliases = {
        ls = "eza -l --icons --git";
        ll = "eza -la --icons --git";
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gst = "git status -sb";
      };

      plugins = [
        {
          name = "zsh-syntax-highlighting";
          src = pkgs.zsh-syntax-highlighting;
        }
        {
          name = "zsh-autosuggestions";
          src = pkgs.zsh-autosuggestions;
        }
        {
          name = "zsh-completions";
          src = pkgs.zsh-completions;
        }
      ];

      oh-my-zsh = {
        enable = true;
        plugins = ["git" "sudo" "command-not-found"];
      };

      envExtra = ''
        export EDITOR='nvim'
        export VISUAL='nvim'
        export PATH="$HOME/.local/bin:$PATH"
      '';
    };
  };
}
