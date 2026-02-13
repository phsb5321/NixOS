# ~/NixOS/modules/packages/categories/terminal.nix
# Terminal and shell tools
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.packages.terminal;
in {
  options.modules.packages.terminal = {
    enable = lib.mkEnableOption "terminal and shell tools";

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
    # Shell
      (lib.optionals cfg.shell [
        zsh
        oh-my-zsh
      ])
      # Theme
      ++ (lib.optionals cfg.theme [
        zsh-powerlevel10k
        starship
        grc
      ])
      # Modern tools (eza, bat already in core)
      ++ (lib.optionals cfg.modernTools [
        vivid
      ])
      # Plugins
      ++ (lib.optionals cfg.plugins [
        zsh-syntax-highlighting
        zsh-autosuggestions
        zsh-you-should-use
        zsh-fast-syntax-highlighting
      ])
      # Editor (zoxide already in core)
      ++ (lib.optionals cfg.editor [
        neovim
        ffmpeg
      ])
      # Applications (remmina, zellij already in core; texlive in latex module)
      ++ (lib.optionals cfg.applications [
        yazi-unwrapped
        dbeaver-bin
        amberol
        obsidian
        d2
        ngrok
      ])
      # Extra packages
      ++ cfg.extraPackages;
  };
}
