# ~/NixOS/modules/services/syncthing.nix
# Syncthing file synchronization service
{ config, lib, ... }:

{
  options.modules.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing file synchronization";
  };

  config = lib.mkIf config.modules.services.syncthing.enable {
    # Placeholder - will be populated in Task 2.2
  };
}
