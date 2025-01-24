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
      programs.zsh = {
        enable = true;
        enableAutosuggestions = true;
        enableCompletion = true;
        autocd = true;
        defaultKeymap = "emacs";

        # Initialize zoxide
        initExtra = ''
          # Load and initialize zoxide
          eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

          # Zellij Settings
          export ZELLIJ_AUTO_ATTACH=false
          export ZELLIJ_AUTO_EXIT=false

          # Better history handling
          setopt EXTENDED_HISTORY       # Write the history file in the ":start:elapsed;command" format.
          setopt SHARE_HISTORY         # Share history between all sessions.
          setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history.
          setopt HIST_IGNORE_DUPS      # Don't record an entry that was just recorded again.
          setopt HIST_IGNORE_ALL_DUPS  # Delete old recorded entry if new entry is a duplicate.
          setopt HIST_FIND_NO_DUPS     # Do not display a line previously found.
          setopt HIST_SAVE_NO_DUPS     # Don't write duplicate entries in the history file.
          setopt HIST_REDUCE_BLANKS    # Remove superfluous blanks before recording entry.

          # Define custom CLI tool "vscatch" to open matching files in VSCode
          vscatch() {
            for f in "$@"; do code "$f"; done
          }

          # Define custom CLI tool "zedcatch" to open matching files in Zed
          zedcatch() {
            for f in "$@"; do zeditor "$f"; done
          }

          # Better word handling for Ctrl+W
          autoload -U select-word-style
          select-word-style bash
          bindkey '^[^?' backward-kill-word  # Alt+Backspace for backward-kill-word

          # Command line editing
          autoload -U edit-command-line
          zle -N edit-command-line
          bindkey '^X^E' edit-command-line   # Open current command in editor

          # Initialize completion system
          autoload -Uz compinit
          compinit

          # Use modern completion system
          zstyle ':completion:*' auto-description 'specify: %d'
          zstyle ':completion:*' completer _expand _complete _correct _approximate
          zstyle ':completion:*' format 'Completing %d'
          zstyle ':completion:*' group-name '''
          zstyle ':completion:*' menu select=2
          eval "$(dircolors -b)"
          zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}
          zstyle ':completion:*' list-colors '''
          zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
          zstyle ':completion:*' matcher-list ''' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
          zstyle ':completion:*' menu select=long
          zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
          zstyle ':completion:*' use-compctl false
          zstyle ':completion:*' verbose true

          # Enhanced ! history expansion
          setopt BANG_HIST              # Treat the '!' character specially during expansion.
          setopt HIST_VERIFY           # Don't execute immediately upon history expansion.
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
          # Reload ZSH configuration
          zshconfig = "source ~/.zshrc";

          # Utility scripts
          textractor = "~/NixOS/user-scripts/textractor.sh";
          nixswitch = "~/NixOS/user-scripts/nixos-rebuild.sh ${cfg.hostName}";
          nix-select-shell = "~/NixOS/user-scripts/nix-shell-selector.sh";

          # Modern replacements
          ls = "eza -l --icons";
          ll = "eza -la --icons";
          cat = "bat";

          # Git shortcuts
          g = "git";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gst = "git status";
        };

        plugins = [
          {
            name = "zsh-syntax-highlighting";
            src = pkgs.fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-syntax-highlighting";
              rev = "0.7.1";
              sha256 = "sha256-gOG0NLlaJfotJfs+SUhGgLTNOnGLjoqnUp54V9aFJg8=";
            };
          }
          {
            name = "zsh-autosuggestions";
            src = pkgs.fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-autosuggestions";
              rev = "v0.7.0";
              sha256 = "sha256-KLUYpUu4DHRumQZ3w59m9aTW6TBKMCXl2UcKi4uMd7w=";
            };
          }
          {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
          {
            name = "powerlevel10k-config";
            src = pkgs.writeTextFile {
              name = "p10k-config";
              text = ''
                # Powerlevel10k Configuration
                POWERLEVEL9K_MODE='nerdfont-complete'
                POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
                POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
                POWERLEVEL9K_PROMPT_ON_NEWLINE=true
                POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
                POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="$ "
              '';
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
          ];
        };

        envExtra = ''
          # Add local bin to PATH
          export PATH="$HOME/.local/bin:$PATH"

          # Set default editor
          export EDITOR='nvim'
          export VISUAL='nvim'

          # Configure less
          export LESS='-R --use-color -Dd+r$Du+b'

          # Set language
          export LANG=en_US.UTF-8
          export LC_ALL=en_US.UTF-8
        '';
      };
    };
  };
}
