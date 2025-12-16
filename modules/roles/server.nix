# ~/NixOS/modules/roles/server.nix
# Server role - headless, services-focused
<<<<<<< HEAD
{ config, lib, ... }:

{
=======
{
  config,
  lib,
  ...
}: {
>>>>>>> origin/host/server
  options.modules.roles.server = {
    enable = lib.mkEnableOption "server role";
  };

  config = lib.mkIf config.modules.roles.server.enable {
    # Server services
    modules.services = {
      ssh.enable = true;
    };

    # Hardware - minimal
    hardware = {
      enableRedistributableFirmware = true;
<<<<<<< HEAD
      bluetooth.enable = false;  # Not needed on server
      graphics.enable = false;   # Headless
=======
      bluetooth.enable = false; # Not needed on server
      graphics.enable = false; # Headless
>>>>>>> origin/host/server
    };

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
<<<<<<< HEAD
        "networkmanager" "wheel"
=======
        "networkmanager"
        "wheel"
>>>>>>> origin/host/server
      ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
    };
  };
}
