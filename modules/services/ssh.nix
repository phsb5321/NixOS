# ~/NixOS/modules/services/ssh.nix
# SSH service configuration
{ config, lib, ... }:

{
  options.modules.services.ssh = {
    enable = lib.mkEnableOption "SSH service";
  };

  config = lib.mkIf config.modules.services.ssh.enable {
    # Placeholder - will be populated in Task 2.3
  };
}
