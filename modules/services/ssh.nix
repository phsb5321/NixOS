# ~/NixOS/modules/services/ssh.nix
# SSH service configuration
{ config, lib, ... }:

with lib;

let
  cfg = config.modules.services.ssh;
in
{
  options.modules.services.ssh = {
    enable = mkEnableOption "SSH service";

    permitRootLogin = mkOption {
      type = types.str;
      default = "no";
      description = "Whether to allow root login via SSH";
    };

    passwordAuthentication = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to allow password authentication";
    };

    kbdInteractiveAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to allow keyboard-interactive authentication";
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = cfg.permitRootLogin;
        PasswordAuthentication = cfg.passwordAuthentication;
        KbdInteractiveAuthentication = cfg.kbdInteractiveAuthentication;
      };
    };
  };
}
