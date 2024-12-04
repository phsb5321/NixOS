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

              fish
              kitty
              grc
              eza
              ffmpeg
              gh
              brave
              yazi-unwrapped
              texlive.combined.scheme-full
              dbeaver-bin
              amberol
              awscli2
              remmina
              obsidian
              d2
              inputs.nixvim
              ngrok
              wakatime-cli
            ]
            ++ cfg.extraPackages;

          sessionVariables = {
            EDITOR = "nvim";
            SHELL = "${pkgs.fish}/bin/fish";
          };
        };

        # Enable Home Manager itself
        programs.home-manager.enable = true;
      };
    };
  };
}
