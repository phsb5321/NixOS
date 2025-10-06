# ~/NixOS/modules/roles/desktop.nix
# Desktop role - full features, gaming, development
{ config, lib, ... }:

{
  options.modules.roles.desktop = {
    enable = lib.mkEnableOption "desktop role";
  };

  config = lib.mkIf config.modules.roles.desktop.enable {
    # Placeholder - will be populated in Task 3.2
  };
}
