# ~/NixOS/modules/secrets/default.nix
# Secrets management with sops-nix
{ config, lib, inputs, ... }:

let
  cfg = config.modules.secrets;
in {
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.modules.secrets = {
    enable = lib.mkEnableOption "secrets management with sops-nix";

    defaultSopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../secrets + "/${config.networking.hostName}.yaml";
      description = "Default sops file for this host";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sops-nix/key.txt";
      description = "Path to the age key file for decryption";
    };

    # Example secrets that can be enabled
    examples = {
      enableWifi = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable WiFi password secret";
      };

      enableGithubToken = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable GitHub token secret";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Base sops configuration
    sops = {
      defaultSopsFile = cfg.defaultSopsFile;
      age.keyFile = cfg.ageKeyFile;

      # Example secrets (disabled by default)
      secrets = lib.mkMerge [
        # WiFi password example
        (lib.mkIf cfg.examples.enableWifi {
          wifi_password = {
            mode = "0400";
          };
        })

        # GitHub token example
        (lib.mkIf cfg.examples.enableGithubToken {
          github_token = {
            owner = config.users.users.notroot.name or "notroot";
            mode = "0400";
          };
        })
      ];
    };

    # Ensure sops-nix key directory exists
    system.activationScripts.setupSopsNix = lib.mkIf cfg.enable ''
      mkdir -p $(dirname ${cfg.ageKeyFile})
    '';
  };
}
