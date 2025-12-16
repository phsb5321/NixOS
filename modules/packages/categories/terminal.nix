# ~/NixOS/modules/packages/categories/terminal.nix
# Terminal and shell tools
<<<<<<< HEAD
{ config, lib, pkgs, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  ...
}: let
>>>>>>> origin/host/server
  cfg = config.modules.packages.terminal;
in {
  options.modules.packages.terminal = {
    enable = lib.mkEnableOption "terminal and shell tools";

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install terminal fonts (JetBrains Mono Nerd Font, Noto)";
    };

    shell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install ZSH and Oh-My-Zsh framework";
    };

    theme = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install shell themes (Powerlevel10k, Starship)";
    };

    modernTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install modern CLI replacements (eza, bat, vivid)";
    };

    plugins = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install ZSH plugins (syntax highlighting, autosuggestions)";
    };

    editor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install terminal editors (Neovim)";
    };

    applications = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install terminal applications (yazi, dbeaver, obsidian, etc.)";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional terminal packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Fonts
      (lib.optionals cfg.fonts [
        nerd-fonts.jetbrains-mono
        noto-fonts-color-emoji
        noto-fonts
        noto-fonts-cjk-sans
      ])
      
      # Shell
      ++ (lib.optionals cfg.shell [
        zsh
        oh-my-zsh
      ])
      
      # Theme
      ++ (lib.optionals cfg.theme [
        zsh-powerlevel10k
        starship
        grc
      ])
      
      # Modern tools
      ++ (lib.optionals cfg.modernTools [
        eza
        bat
        vivid
        btop
        htop
        lsd
        fzf
        ripgrep
        fd
        tree
        tldr
        curl
        wget
        unzip
        zip
        ncdu
        duf
        du-dust
        procs
        bandwhich
        hyperfine
      ])
      
      # Plugins
      ++ (lib.optionals cfg.plugins [
        zsh-syntax-highlighting
        zsh-autosuggestions
        zsh-you-should-use
        zsh-fast-syntax-highlighting
      ])
      
      # Editor
      ++ (lib.optionals cfg.editor [
        neovim
        ffmpeg
        zoxide
      ])
      
      # Applications
      ++ (lib.optionals cfg.applications [
        kitty  # Terminal emulator - THIS WAS MISSING!
        alacritty  # Alternative terminal emulator
        yazi-unwrapped
        texlive.combined.scheme-full
        dbeaver-bin
        amberol
        remmina
        obsidian
        d2
        ngrok
        zellij
        tmux  # Terminal multiplexer
        screen  # Alternative terminal multiplexer
      ])
      
      # Extra packages
      ++ cfg.extraPackages;
  };
}
