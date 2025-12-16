<<<<<<< HEAD
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dotfiles;
  dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";
in
{
=======
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.dotfiles;
  dotfilesPath = "${config.users.users.${cfg.username}.home}/${cfg.projectDir}/dotfiles";
in {
>>>>>>> origin/host/server
  options.modules.dotfiles.autoSync = {
    enable = mkEnableOption "automatic dotfiles synchronization";

    interval = mkOption {
      type = types.str;
      default = "5min";
      description = "How often to check for dotfiles changes";
    };
  };

  config = mkIf (cfg.enable && cfg.autoSync.enable) {
    # User systemd service to apply dotfiles
    systemd.user.services.dotfiles-sync = {
      description = "Synchronize dotfiles with chezmoi";

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.chezmoi}/bin/chezmoi apply --source ${dotfilesPath}";
      };
    };

    # Timer to run periodically
    systemd.user.timers.dotfiles-sync = {
      description = "Timer for dotfiles synchronization";
<<<<<<< HEAD
      wantedBy = [ "timers.target" ];
=======
      wantedBy = ["timers.target"];
>>>>>>> origin/host/server

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.autoSync.interval;
        Unit = "dotfiles-sync.service";
      };
    };

    # Path watcher - apply immediately when dotfiles directory changes
    systemd.user.paths.dotfiles-watch = {
      description = "Watch dotfiles directory for changes";
<<<<<<< HEAD
      wantedBy = [ "paths.target" ];
=======
      wantedBy = ["paths.target"];
>>>>>>> origin/host/server

      pathConfig = {
        PathModified = dotfilesPath;
        Unit = "dotfiles-sync.service";
      };
    };
  };
}
