# ~/NixOS/modules/services/samba-mounts.nix
# Mount remote SAMBA/CIFS shares with credential files (passwords stay off git)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.sambaMounts;
in {
  options.modules.services.sambaMounts = {
    enable = lib.mkEnableOption "SAMBA/CIFS network mounts";

    mounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          remotePath = lib.mkOption {
            type = lib.types.str;
            description = "Remote CIFS path (e.g. //100.99.218.39/flatnotes)";
          };

          mountPoint = lib.mkOption {
            type = lib.types.str;
            description = "Local mount point path";
          };

          credentialsFile = lib.mkOption {
            type = lib.types.path;
            description = "Path to credentials file (username=..., password=...)";
          };

          uid = lib.mkOption {
            type = lib.types.int;
            default = 1000;
            description = "UID for mounted files";
          };

          gid = lib.mkOption {
            type = lib.types.int;
            default = 100;
            description = "GID for mounted files";
          };

          extraOptions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Extra mount options";
          };

          automount = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Use systemd automount (mount on first access, unmount after idle)";
          };

          idleTimeout = lib.mkOption {
            type = lib.types.str;
            default = "10min";
            description = "Idle timeout before auto-unmount (only with automount)";
          };
        };
      });
      default = {};
      description = "CIFS/SAMBA mounts to configure";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure cifs-utils is available
    environment.systemPackages = [pkgs.cifs-utils];

    # Create mount points and credentials directory via activation script
    system.activationScripts.sambaMountDirs = let
      mountDirs = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (_: m: "mkdir -p ${m.mountPoint}") cfg.mounts
      );
    in ''
      mkdir -p /etc/samba/credentials
      chmod 700 /etc/samba/credentials
      ${mountDirs}
    '';

    # Generate fileSystems entries for each mount
    fileSystems = lib.mkMerge (
      lib.mapAttrsToList (_name: m: {
        "${m.mountPoint}" = {
          device = m.remotePath;
          fsType = "cifs";
          options =
            [
              "credentials=${m.credentialsFile}"
              "uid=${toString m.uid}"
              "gid=${toString m.gid}"
              "file_mode=0664"
              "dir_mode=0775"
              "vers=3.0"
              "soft"
              "rsize=4194304"
              "wsize=4194304"
            ]
            ++ (
              if m.automount
              then [
                "noauto"
                "x-systemd.automount"
                "x-systemd.idle-timeout=${m.idleTimeout}"
                "x-systemd.mount-timeout=30s"
              ]
              else ["_netdev"]
            )
            ++ m.extraOptions;
        };
      })
      cfg.mounts
    );
  };
}
