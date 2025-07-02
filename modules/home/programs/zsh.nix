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

      # Modified initContent to fix path and shell issues
      initContent = ''
        # Ensure ZSH is in the PATH
        export PATH="${pkgs.zsh}/bin:$PATH"

        # Fix SHELL environment variable to use full path - use the actual installed path
        export SHELL="/etc/profiles/per-user/notroot/bin/zsh"

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

        # Fix for SSH sessions
        if [[ -n "$SSH_CONNECTION" ]]; then
          # Use bash for SSH sessions to ensure stability
          export SHELL="${pkgs.bash}/bin/bash"
          # Override TERM for SSH compatibility
          export TERM="xterm-256color"
        else
          # Set explicit shell path for local sessions
          export SHELL="/etc/profiles/per-user/notroot/bin/zsh"
        fi

        # starship prompt
        eval "$(${pkgs.starship}/bin/starship init zsh)"

        # NVIDIA GPU offload function
        nvidia-run() {
          if [ $# -eq 0 ]; then
            echo "🎮 NVIDIA GPU Offload Function"
            echo "Usage: nvidia-run <command> [args...]"
            echo "Example: nvidia-run steam"
            echo "         nvidia-run lutris"
            echo "         nvidia-run glxgears"
            return 0
          fi
          __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia "$@"
        }

        # Better history search
        autoload -U up-line-or-beginning-search
        autoload -U down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search # Up
        bindkey "^[[B" down-line-or-beginning-search # Down

        # Quick directory navigation
        setopt AUTO_PUSHD           # Push the current directory visited on the stack.
        setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
        setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.

        # Advanced completion
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' menu select

        # Quick functions for development
        mkcd() { mkdir -p "$1" && cd "$1"; }
        extract() {
          if [ -f "$1" ]; then
            case "$1" in
              *.tar.bz2)   tar xjf "$1"   ;;
              *.tar.gz)    tar xzf "$1"   ;;
              *.bz2)       bunzip2 "$1"   ;;
              *.rar)       unrar x "$1"   ;;
              *.gz)        gunzip "$1"    ;;
              *.tar)       tar xf "$1"    ;;
              *.tbz2)      tar xjf "$1"   ;;
              *.tgz)       tar xzf "$1"   ;;
              *.zip)       unzip "$1"     ;;
              *.Z)         uncompress "$1";;
              *.7z)        7z x "$1"      ;;
              *)           echo "'$1' cannot be extracted via extract()" ;;
            esac
          else
            echo "'$1' is not a valid file"
          fi
        }
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
        # Enhanced ls with eza
        ls = "eza -l --icons --git";
        ll = "eza -la --icons --git";
        la = "eza -la --icons --git";
        lt = "eza --tree --icons --git";

        # Git shortcuts
        ga = "git add";
        gc = "git commit";
        gp = "git push";
        gl = "git pull";
        gst = "git status -sb";
        gco = "git checkout";
        gb = "git branch";
        gd = "git diff";

        # System management
        cat = "bat";
        grep = "rg";
        find = "fd";
        ps = "procs";
        top = "btop";

        # NixOS system management aliases
        nixswitch = "cd $HOME/NixOS && ./user-scripts/nixswitch"; # Auto-detect host with beautiful gum UI
        nixs = "cd $HOME/NixOS && ./user-scripts/nixswitch"; # Short alias

        # Host-specific aliases
        nixswitch-default = "cd $HOME/NixOS && ./user-scripts/nixswitch default";
        nixswitch-laptop = "cd $HOME/NixOS && ./user-scripts/nixswitch laptop";
        nixs-default = "cd $HOME/NixOS && ./user-scripts/nixswitch default";
        nixs-laptop = "cd $HOME/NixOS && ./user-scripts/nixswitch laptop";

        # Other system scripts
        nix-shell-select = "cd $HOME/NixOS && ./user-scripts/nix-shell-selector.sh";
        textractor = "cd $HOME/NixOS && ./user-scripts/textractor.sh";

        # Quick navigation
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../..";
        "....." = "cd ../../../..";

        # System info
        myip = "curl ifconfig.me";
        ports = "netstat -tulanp";
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
        plugins = ["git" "command-not-found"];
      };

      envExtra = ''
        export EDITOR='nvim'
        export VISUAL='nvim'
        export PATH="$HOME/.local/bin:$PATH"

        # Explicitly set SHELL to ensure correct operation
        if [[ -n "$SSH_CONNECTION" ]]; then
          export SHELL="${pkgs.bash}/bin/bash"
        else
          export SHELL="/etc/profiles/per-user/notroot/bin/zsh"
        fi
      '';
    };
  };
}
