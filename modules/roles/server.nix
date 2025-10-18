# ~/NixOS/modules/roles/server.nix
# Server role - headless, services-focused
{ config, lib, ... }:

{
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
      bluetooth.enable = false;  # Not needed on server
      graphics.enable = false;   # Headless
    };

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
        "networkmanager" "wheel"
      ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
    };
  };
}
