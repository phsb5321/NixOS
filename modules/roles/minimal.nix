# ~/NixOS/modules/roles/minimal.nix
# Minimal role - basic system only
{ config, lib, ... }:

{
  options.modules.roles.minimal = {
    enable = lib.mkEnableOption "minimal installation role";
  };

  config = lib.mkIf config.modules.roles.minimal.enable {
    # Basic services only
    modules.services = {
      ssh.enable = true;
    };

    # Hardware - absolute minimum
    hardware = {
      enableRedistributableFirmware = true;
      bluetooth.enable = false;
      graphics.enable = false;
    };

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [ "wheel" ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
    };
  };
}
