# ~/NixOS/modules/roles/laptop.nix
# Laptop role - power management, minimal features
{ config, lib, ... }:

{
  options.modules.roles.laptop = {
    enable = lib.mkEnableOption "laptop role";
  };

  config = lib.mkIf config.modules.roles.laptop.enable {
    # Placeholder - will be populated in Task 3.3
  };
}
