# ~/NixOS/hosts/modules/home/programs/zsh.nix
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
      programs = {
        zsh = {
          enable = true;
          autosuggestion.enable = true;
          enableCompletion = true;
          autocd = true;
          defaultKeymap = "emacs";

          initExtra = ''
            # Load and initialize zoxide
            eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

            # Zellij Settings
            export ZELLIJ_AUTO_ATTACH=false
            export ZELLIJ_AUTO_EXIT=false

            if [[ -z "$ZELLIJ" ]]; then
                if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
                    zellij attach -c
                else
                    zellij
                fi

                if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
                    exit
                fi
            fi


            # ZSH Options
            setopt EXTENDED_HISTORY
            setopt SHARE_HISTORY
            setopt HIST_EXPIRE_DUPS_FIRST
            setopt HIST_IGNORE_DUPS
            setopt HIST_IGNORE_ALL_DUPS
            setopt HIST_FIND_NO_DUPS
            setopt HIST_SAVE_NO_DUPS
            setopt HIST_REDUCE_BLANKS
            setopt NO_NOMATCH
            setopt GLOB_DOTS

            # Custom functions
            vscatch() {
              for f in "$@"; do code "$f"; done
            }

            zedcatch() {
              for f in "$@"; do zeditor "$f"; done
            }

            # Directory colors using dircolors instead of vivid
            if [ -x "$(command -v dircolors)" ]; then
              eval "$(dircolors -b)"
            fi

            # Load colors module
            autoload -U colors && colors

            # Keybindings
            bindkey '^[^?' backward-kill-word
            bindkey '^X^E' edit-command-line

            # Initialize basic completion system
            autoload -Uz compinit && compinit

            # Load starship prompt
            eval "$(${pkgs.starship}/bin/starship init zsh)"

            # Completion styles
            zstyle ':completion:*' menu select
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
            zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
            zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
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
            lt = "eza -T --icons --git-ignore";
            tree = "eza --tree --icons";
            cat = "bat --style=full --paging=never";
            grep = "grep --color=auto";
            diff = "diff --color=auto";
            ip = "ip --color=auto";

            g = "git";
            ga = "git add";
            gc = "git commit";
            gp = "git push";
            gpl = "git pull";
            gst = "git status -sb";
            glo = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            gb = "git branch";
            gd = "git diff";
            gco = "git checkout";

            zshconfig = "source ~/.zshrc";
            textractor = "~/NixOS/user-scripts/textractor.sh";
            nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh ${cfg.hostName}";
            nix-select-shell = "~/NixOS/user-scripts/nix-shell-selector.sh";
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
            {
              name = "zsh-history-substring-search";
              src = pkgs.zsh-history-substring-search;
            }
            {
              name = "fast-syntax-highlighting";
              src = pkgs.fetchFromGitHub {
                owner = "zdharma-continuum";
                repo = "fast-syntax-highlighting";
                rev = "v1.55";
                sha256 = "sha256-DWVFBoICroKaKgByLmDEo4O+xo6eA8YO792g8t8R7kA=";
              };
            }
            {
              name = "zsh-you-should-use";
              src = pkgs.zsh-you-should-use;
            }
            {
              name = "fzf-tab";
              src = pkgs.fetchFromGitHub {
                owner = "Aloxaf";
                repo = "fzf-tab";
                rev = "v1.1.1";
                sha256 = "sha256-0/YOL1/G2SWncbLNaclSYUz7VyfWu+OB8TYJYm4NYkM=";
              };
            }
            {
              name = "zsh-nix-shell";
              src = pkgs.fetchFromGitHub {
                owner = "chisui";
                repo = "zsh-nix-shell";
                rev = "v0.8.0";
                sha256 = "sha256-Z6EYQdasvpl1P78poj9efnnLj7QQg13Me8x1Ryyw+dM=";
              };
            }
          ];

          oh-my-zsh = {
            enable = true;
            plugins = [
              "git"
              "sudo"
              "command-not-found"
              "colored-man-pages"
              "docker"
              "docker-compose"
              "git-flow"
              "gitfast"
              "github"
              "git-extras"
              "pip"
              "python"
              "aws"
              "terraform"
              "kubectl"
              "helm"
            ];
          };

          envExtra = ''
            export PATH="$HOME/.local/bin:$PATH"
            export EDITOR='nvim'
            export VISUAL='nvim'
            export LESS='-R --use-color -Dd+r$Du+b'
            export LESS_TERMCAP_mb=$'\E[1;31m'
            export LESS_TERMCAP_md=$'\E[1;36m'
            export LESS_TERMCAP_me=$'\E[0m'
            export LESS_TERMCAP_se=$'\E[0m'
            export LESS_TERMCAP_so=$'\E[01;44;33m'
            export LESS_TERMCAP_ue=$'\E[0m'
            export LESS_TERMCAP_us=$'\E[1;32m'
            export LANG=en_US.UTF-8
            export LC_ALL=en_US.UTF-8
          '';
        };

        # Enable starship without additional configuration
        starship.enable = true;
      };
    };
  };
}
