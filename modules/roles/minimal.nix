# ~/NixOS/modules/roles/minimal.nix
# Minimal role - basic system only
{ config, lib, ... }:

{
  options.modules.roles.minimal = {
    enable = lib.mkEnableOption "minimal role";
  };

  config = lib.mkIf config.modules.roles.minimal.enable {
    # Placeholder - for future use
  };
}
