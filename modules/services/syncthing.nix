# ~/NixOS/modules/services/syncthing.nix
# Syncthing file synchronization service with Tailscale integration
#
# This module configures Syncthing to sync files between devices over Tailscale.
# For security, Syncthing only listens on the Tailscale interface.
#
# Usage in host configuration:
#   modules.services.syncthing = {
#     enable = true;
#     tailscaleOnly = true;  # Only listen on Tailscale interface
#     deviceId = "XXXXX";    # This device's Syncthing ID
#     devices = {
#       desktop = { id = "XXX"; addresses = ["tcp://100.x.x.x:22000"]; };
#       laptop = { id = "XXX"; addresses = ["tcp://100.x.x.x:22000"]; };
#     };
#     folders = {
#       code = { path = "~/Code"; devices = ["desktop" "laptop"]; };
#     };
#   };
{
  config,
  lib,
  pkgs,
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

    group = mkOption {
      type = types.str;
      default = "users";
      description = "Group to run Syncthing as";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}";
      description = "Default data directory (home directory)";
    };

    configDir = mkOption {
      type = types.str;
      default = "/home/${cfg.user}/.config/syncthing";
      description = "Directory for Syncthing configuration";
    };

    # Tailscale integration
    tailscaleOnly = mkOption {
      type = types.bool;
      default = true;
      description = "Only listen on Tailscale interface for security";
    };

    tailscaleIP = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Tailscale IP address for this device (e.g., 100.x.x.x)";
    };

    guiAddress = mkOption {
      type = types.str;
      default = "127.0.0.1:8384";
      description = "Address for Syncthing web GUI";
    };

    # Device configuration
    devices = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          id = mkOption {
            type = types.str;
            description = "Syncthing device ID";
          };
          addresses = mkOption {
            type = types.listOf types.str;
            default = ["dynamic"];
            description = "Device addresses (use Tailscale IPs for tailscaleOnly mode)";
          };
          introducer = mkOption {
            type = types.bool;
            default = false;
            description = "Whether this device is an introducer";
          };
        };
      });
      default = {};
      description = "Known Syncthing devices";
    };

    # Folder configuration
    folders = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          path = mkOption {
            type = types.str;
            description = "Path to sync folder";
          };
          devices = mkOption {
            type = types.listOf types.str;
            description = "Devices to sync this folder with";
          };
          versioning = mkOption {
            type = types.nullOr (types.attrsOf types.anything);
            default = null;
            description = "Versioning configuration";
          };
          ignorePerms = mkOption {
            type = types.bool;
            default = false;
            description = "Ignore permissions";
          };
          type = mkOption {
            type = types.enum ["sendreceive" "sendonly" "receiveonly"];
            default = "sendreceive";
            description = "Folder type";
          };
          rescanIntervalS = mkOption {
            type = types.int;
            default = 3600;
            description = "Rescan interval in seconds";
          };
          fsWatcherEnabled = mkOption {
            type = types.bool;
            default = true;
            description = "Enable filesystem watcher";
          };
        };
      });
      default = {};
      description = "Folders to synchronize";
    };

    overrideDevices = mkOption {
      type = types.bool;
      default = true;
      description = "Override device configuration on restart";
    };

    overrideFolders = mkOption {
      type = types.bool;
      default = true;
      description = "Override folder configuration on restart";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports (not needed with Tailscale)";
    };
  };

  config = mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = cfg.group;
      dataDir = cfg.dataDir;
      configDir = cfg.configDir;
      overrideDevices = cfg.overrideDevices;
      overrideFolders = cfg.overrideFolders;
      openDefaultPorts = cfg.openFirewall;
      guiAddress = cfg.guiAddress;

      settings = {
        # Listen addresses - Tailscale only or all interfaces
        options = {
          listenAddresses =
            if cfg.tailscaleOnly && cfg.tailscaleIP != null
            then ["tcp://${cfg.tailscaleIP}:22000" "quic://${cfg.tailscaleIP}:22000"]
            else ["default"];
          globalAnnounceEnabled = !cfg.tailscaleOnly;
          localAnnounceEnabled = !cfg.tailscaleOnly;
          relaysEnabled = !cfg.tailscaleOnly;
          natEnabled = !cfg.tailscaleOnly;
          urAccepted = -1; # Disable usage reporting
        };

        # Device configuration
        devices = mapAttrs (name: device: {
          inherit (device) id addresses introducer;
        }) cfg.devices;

        # Folder configuration
        folders = mapAttrs (name: folder: {
          inherit (folder) path devices type ignorePerms rescanIntervalS fsWatcherEnabled;
          versioning = folder.versioning;
        }) cfg.folders;
      };
    };

    # Ensure Tailscale is running before Syncthing if tailscaleOnly
    systemd.services.syncthing = mkIf cfg.tailscaleOnly {
      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
    };

    # Create sync directories
    systemd.tmpfiles.rules = mapAttrsToList (name: folder:
      "d ${folder.path} 0755 ${cfg.user} ${cfg.group} -"
    ) cfg.folders;
  };
}
