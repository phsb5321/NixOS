# ~/NixOS/modules/services/syncthing.nix
# Syncthing file synchronization service
{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.services.syncthing;
in {
  options.modules.services.syncthing = {
    enable = mkEnableOption "Syncthing file synchronization";

    user = mkOption {
      type = types.str;
      default = "notroot";
      description = "User to run Syncthing as";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/Sync";
      description = "Directory for synchronized files";
    };

    configDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/.config/syncthing";
      description = "Directory for Syncthing configuration";
    };

    overrideDevices = mkOption {
      type = types.bool;
      default = true;
      description = "Override device configuration";
    };

    overrideFolders = mkOption {
      type = types.bool;
      default = true;
      description = "Override folder configuration";
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      dataDir = cfg.dataDir;
      configDir = cfg.configDir;
      overrideDevices = cfg.overrideDevices;
      overrideFolders = cfg.overrideFolders;
    };
  };
}
