# ~/NixOS/hosts/modules/home/default.nix
{
  config,
  lib,
  pkgs,
  inputs,
  systemVersion,
  ...
}:
with lib; let
  cfg = config.modules.home;
in {
  imports = [
    ./programs # We'll organize program-specific configurations in separate files
  ];

  options.modules.home = {
    enable = mkEnableOption "Home configuration module";

    username = mkOption {
      type = types.str;
      default = "notroot";
      description = "Username for home configuration";
    };

    hostName = mkOption {
      type = types.str;
      description = "Host name for system-specific configurations";
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional packages to install for the user";
    };
  };

  config = mkIf cfg.enable {
    home-manager = {
      extraSpecialArgs = {inherit inputs;};
      backupFileExtension = "bkp";

      users.${cfg.username} = {pkgs, ...}: {
        imports = [
          inputs.nixvim.homeManagerModules.nixvim
        ];

        nixpkgs.config = {
          allowUnfree = true;
        };

        # User Configuration
        home = {
          username = cfg.username;
          homeDirectory = "/home/${cfg.username}";

          # 👇🏻 System Version for Home Manager
          stateVersion = systemVersion;

          packages = with pkgs;
            [
              # Fonts
              nerd-fonts.jetbrains-mono
              noto-fonts-emoji
              noto-fonts
              noto-fonts-cjk-sans

              # Shell and Terminal
              fish
              zsh
              starship # Cross-shell prompt
              kitty
              grc # Generic colorizer
              eza # Modern ls replacement
              bat # Modern cat replacement
              vivid # LS_COLORS generator
              zsh-syntax-highlighting
              zsh-autosuggestions
              zsh-you-should-use
              zsh-fast-syntax-highlighting
              fishPlugins.tide
              fishPlugins.grc

              # Development Tools
              ffmpeg
              gh
              git
              zoxide # Smart directory jumper
              fzf # Fuzzy finder
              ripgrep # Fast grep
              fd # Fast find

              # Applications
              brave
              yazi-unwrapped
              texlive.combined.scheme-full
              dbeaver-bin
              amberol
              remmina
              obsidian
              d2
              inputs.nixvim
              ngrok
            ]
            ++ cfg.extraPackages;

          sessionVariables = {
            EDITOR = "nvim";
            SHELL = "${pkgs.zsh}/bin/zsh";
          };
        };

        # Enable Home Manager itself
        programs.home-manager.enable = true;
      };
    };
  };
}
