# ~/NixOS/modules/home/shared.nix
# Shared Home Manager configuration across all hosts
{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:
with lib; {
  # Common programs for all hosts
  programs = {
    # Shell configuration
    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''
        # Common shell initialization
        eval "$(starship init zsh)"
        eval "$(zoxide init zsh)"

        # Common aliases
        alias ls="eza --icons"
        alias ll="eza --icons --long --all"
        alias cat="bat"
        alias grep="rg"
        alias find="fd"
        alias cd="z"
      '';

      shellAliases = {
        nixos-rebuild-switch = "sudo nixos-rebuild switch --flake ~/NixOS#${hostname}";
        nixos-rebuild-test = "sudo nixos-rebuild test --flake ~/NixOS#${hostname}";
        nixos-rebuild-build = "nixos-rebuild build --flake ~/NixOS#${hostname}";
        hm-switch = "home-manager switch --flake ~/NixOS#notroot@${hostname}";
        flake-update = "cd ~/NixOS && nix flake update";
      };
    };

    # Starship prompt
    starship = {
      enable = true;
      settings = {
        format = "[](#9A348E)$os$username[](bg:#DA627D fg:#9A348E)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#86BBD8)$c$elixir$elm$golang$gradle$haskell$java$julia$nodejs$nim$rust$scala[](fg:#86BBD8 bg:#06969A)$docker_context[](fg:#06969A bg:#33658A)$time[ ](fg:#33658A)";

        os = {
          style = "bg:#9A348E fg:#ffffff";
          symbols = {
            NixOS = " ";
          };
        };

        username = {
          show_always = true;
          style_user = "bg:#9A348E fg:#ffffff";
          style_root = "bg:#9A348E fg:#ffffff";
          format = "[$user ]($style)";
        };

        directory = {
          style = "fg:#ffffff bg:#DA627D";
          format = "[ $path ]($style)";
          truncation_length = 3;
          truncation_symbol = "…/";
        };

        git_branch = {
          symbol = "";
          style = "bg:#FCA17D";
          format = "[[ $symbol $branch ](fg:#ffffff bg:#FCA17D)]($style)";
        };

        git_status = {
          style = "bg:#FCA17D";
          format = "[[($all_status$ahead_behind )](fg:#ffffff bg:#FCA17D)]($style)";
        };

        nodejs = {
          symbol = "";
          style = "bg:#86BBD8";
          format = "[[ $symbol( $version) ](fg:#ffffff bg:#86BBD8)]($style)";
        };

        rust = {
          symbol = "";
          style = "bg:#86BBD8";
          format = "[[ $symbol( $version) ](fg:#ffffff bg:#86BBD8)]($style)";
        };

        golang = {
          symbol = "";
          style = "bg:#86BBD8";
          format = "[[ $symbol( $version) ](fg:#ffffff bg:#86BBD8)]($style)";
        };

        time = {
          disabled = false;
          time_format = "%R";
          style = "bg:#33658A";
          format = "[[  $time ](fg:#ffffff bg:#33658A)]($style)";
        };
      };
    };

    # Git configuration
    git = {
      enable = true;
      userName = "Pedro Balbino";
      userEmail = "pehdroobalbinoo@gmail.com";

      extraConfig = {
        init.defaultBranch = "main";
        core.editor = "nvim";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };

    # Direnv for project environments
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    # Zoxide for smart directory jumping
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Fzf for fuzzy finding
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    # Bat for better cat
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };

    # Eza for better ls
    eza = {
      enable = true;
      enableZshIntegration = true;
      git = true;
      icons = "auto";
    };
  };

  # Essential packages for all hosts (user-level tools only)
  home.packages = with pkgs; [
    # Shell utilities
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-you-should-use
    zsh-fast-syntax-highlighting

    # File management
    yazi
    tree

    # Network tools
    wget
    curl
    rsync
  ];

  # Common environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    SHELL = "${pkgs.zsh}/bin/zsh";
    TERM = "xterm-256color";
  };

  # XDG directories
  xdg.enable = true;
}
