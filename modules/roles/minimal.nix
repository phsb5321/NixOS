# ~/NixOS/modules/roles/minimal.nix
# Minimal role - basic system only
{
  config,
  lib,
  ...
}: {
  imports = [
    ../../profiles/common.nix
  ];

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

    # Minimal uses only base groups from common.nix (networkmanager, wheel)
    # No additional groups needed
  };
}
