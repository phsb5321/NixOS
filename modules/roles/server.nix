# ~/NixOS/modules/roles/server.nix
# Server role - headless, services-focused
{ config, lib, ... }:

{
  options.modules.roles.server = {
    enable = lib.mkEnableOption "server role";
  };

  config = lib.mkIf config.modules.roles.server.enable {
    # Placeholder - for future use
  };
}
