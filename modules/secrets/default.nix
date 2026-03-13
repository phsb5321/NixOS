# modules/secrets/default.nix
#
# Module: Secrets Management
# Purpose: Manages encrypted secrets with sops-nix (age encryption)
{
  config,
  lib,
  inputs,
  ...
}: let
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

    # Cloudflare Tunnel secrets
    cloudflareTunnel = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Cloudflare tunnel credential secrets";
      };

      credentialsOwner = lib.mkOption {
        type = lib.types.str;
        default = "notroot";
        description = "User who owns the decrypted credentials file";
      };
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
      inherit (cfg) defaultSopsFile;
      age.keyFile = cfg.ageKeyFile;

      secrets = lib.mkMerge [
        # Cloudflare tunnel credentials (decrypted JSON file)
        (lib.mkIf cfg.cloudflareTunnel.enable {
          cloudflare_credentials = {
            owner = cfg.cloudflareTunnel.credentialsOwner;
            mode = "0400";
            # This is the raw JSON content from the sops file,
            # written to /run/secrets/cloudflare_credentials
          };
        })

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
    system.activationScripts.setupSopsNix = ''
      mkdir -p $(dirname ${cfg.ageKeyFile})
    '';
  };
}
