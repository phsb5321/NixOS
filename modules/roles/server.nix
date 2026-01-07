# ~/NixOS/modules/roles/server.nix
# Server role - headless, services-focused
{
  config,
  lib,
  ...
}: {
  imports = [
    ../../profiles/common.nix
  ];

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
      bluetooth.enable = false; # Not needed on server
      graphics.enable = false; # Headless
    };

    # Server uses only base groups from common.nix (networkmanager, wheel)
    # No additional groups needed for headless server
  };
}
