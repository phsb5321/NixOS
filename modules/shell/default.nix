# ~/NixOS/modules/shell/default.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.shell;
in {
  options.modules.shell = {
    enable = mkEnableOption "Shell configuration module";

    defaultShell = mkOption {
      type = types.package;
      default = pkgs.zsh;
      description = "Default system shell";
    };

    zsh = {
      enable = mkEnableOption "ZSH configuration" // {default = true;};

      ohMyZsh = {
        enable = mkEnableOption "Oh My ZSH" // {default = true;};
        plugins = mkOption {
          type = types.listOf types.str;
          default = [
            "git"
            "colored-man-pages"
            "command-not-found"
            "sudo"
            "history-substring-search"
          ];
          description = "Oh My ZSH plugins to enable";
        };
      };

      powerlevel10k = {
        enable = mkEnableOption "Powerlevel10k theme" // {default = true;};
      };

      plugins = {
        autosuggestions = mkEnableOption "ZSH autosuggestions" // {default = true;};
        syntaxHighlighting = mkEnableOption "ZSH syntax highlighting" // {default = true;};
        youShouldUse = mkEnableOption "ZSH you-should-use plugin" // {default = true;};
        fastSyntaxHighlighting = mkEnableOption "ZSH fast syntax highlighting" // {default = false;};
      };

      modernTools = {
        enable = mkEnableOption "Modern shell tools" // {default = true;};
        zoxide = mkEnableOption "Zoxide (better cd)" // {default = true;};
      };
    };
  };

  config = mkIf cfg.enable {
    # System-wide shell configuration
    users.defaultUserShell = cfg.defaultShell;

    # Enable ZSH system-wide
    programs.zsh = mkIf cfg.zsh.enable {
      enable = true;
      enableCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;

      # ZSH configuration that applies system-wide
      ohMyZsh = mkIf cfg.zsh.ohMyZsh.enable {
        enable = true;
        plugins = cfg.zsh.ohMyZsh.plugins;
        theme = ""; # We use Powerlevel10k instead
      };

      # Set up shell environment
      shellInit = ''
        # History configuration
        export HISTSIZE=10000
        export SAVEHIST=10000
        export HISTFILE="$HOME/.zsh_history"

        # ZSH options
        setopt hist_ignore_dups
        setopt hist_ignore_space
        setopt hist_verify
        setopt share_history
        setopt auto_cd
        setopt auto_pushd
        setopt pushd_ignore_dups
        setopt correct
        setopt complete_in_word
        setopt always_to_end
      '';
    };

    # Install shell packages
    environment.systemPackages = with pkgs;
      (optionals cfg.zsh.enable [
        zsh
        zsh-completions
      ])
      ++ (optionals cfg.zsh.ohMyZsh.enable [
        oh-my-zsh
      ])
      ++ (optionals cfg.zsh.powerlevel10k.enable [
        zsh-powerlevel10k
      ])
      ++ (optionals cfg.zsh.plugins.autosuggestions [
        zsh-autosuggestions
      ])
      ++ (optionals cfg.zsh.plugins.syntaxHighlighting [
        zsh-syntax-highlighting
      ])
      ++ (optionals cfg.zsh.plugins.youShouldUse [
        zsh-you-should-use
      ])
      ++ (optionals cfg.zsh.plugins.fastSyntaxHighlighting [
        zsh-fast-syntax-highlighting
      ])
      ++ (optionals cfg.zsh.modernTools.enable [
        # Modern shell tools
        eza # Better ls
        bat # Better cat
        fd # Better find
        ripgrep # Better grep
        fzf # Fuzzy finder
        tree # Directory tree
        htop # Better top
        btop # Modern system monitor
        dust # Better du
        procs # Better ps
        bottom # Cross-platform system monitor
        tokei # Count lines of code
        hyperfine # Benchmarking tool
        bandwhich # Network utilization
        broot # Directory navigation
        sd # Better sed
        tealdeer # Better tldr
        choose # Better cut
        dog # Better dig
      ])
      ++ (optionals cfg.zsh.modernTools.zoxide [
        zoxide
      ]);
  };
}
