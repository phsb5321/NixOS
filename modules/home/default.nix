# ~/NixOS/modules/home/default.nix
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
    ./programs
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
    # First, forcefully disable the home-manager service to avoid conflicts
    systemd.services."home-manager-${cfg.username}".enable = lib.mkForce false;

    # Home Manager core settings
    home-manager = {
      backupFileExtension = "bkp";
      extraSpecialArgs = {
        inherit inputs;
        forceActivation = true;
      };

      # User-specific Home Manager configuration
      users.${cfg.username} = {pkgs, ...}: {
        imports = [
          inputs.nixvim.homeManagerModules.nixvim
        ];

        # Explicitly enable this
        home.enableNixpkgsReleaseCheck = false;

        home = {
          username = cfg.username;
          homeDirectory = "/home/${cfg.username}";
          stateVersion = systemVersion;

          # File management options - handles conflicts
          file = {
            ".config".enable = false; # Skip managing whole .config directory
          };

          packages = with pkgs;
            [
              # Same packages as before...
              nerd-fonts.jetbrains-mono
              noto-fonts-emoji
              fish
              zsh
              starship
              kitty
              zellij
              ghostty
              ffmpeg
              gh
              git
              zoxide
              fzf
              ripgrep
              fd
            ]
            ++ cfg.extraPackages;

          sessionVariables = {
            EDITOR = "nvim";
            SHELL = "zsh";
          };
        };

        # Enable home-manager
        programs.home-manager.enable = true;

        # PipeWire Bluetooth fix - avoid conflicts by putting this in the user's home directory
        home.file.".config/pipewire/pipewire-pulse.conf.d/99-soundcore-fix.conf".text = ''
          pulse.properties = {
            bluez5.hw-offload         = true
            bluez5.autoswitch-profile = true
            bluez5.roles              = [ hfp_hf hfp_ag hsp_hs hsp_ag a2dp_sink a2dp_source ]
          }
        '';

        # Disable any legacy ghostty config to avoid collisions
        home.file.".config/ghostty/config".enable = false;
      };
    };
  };
}
