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
    # Home Manager core settings
    home-manager = {
      backupFileExtension = "bkp";
      useGlobalPkgs = true;
      useUserPackages = true;

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

          packages = with pkgs;
            [
              # Core Home Manager packages (user-level only)
              # All application packages should be at system level
            ]
            ++ cfg.extraPackages;

          sessionVariables = {
            EDITOR = "nvim";
            SHELL = "${pkgs.zsh}/bin/zsh";
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
      };
    };
  };
}
