# WiFi configuration module for NetworkManager
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.wifi;
in {
  options.modules.networking.wifi = {
    enable = mkEnableOption "WiFi configuration";

    networks = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          psk = mkOption {
            type = types.str;
            description = "WiFi password/PSK";
          };
          priority = mkOption {
            type = types.int;
            default = 100;
            description = "Network priority (higher = preferred)";
          };
          autoConnect = mkOption {
            type = types.bool;
            default = true;
            description = "Auto-connect to this network";
          };
        };
      });
      default = {};
      description = "WiFi networks to configure";
    };

    enablePowersave = mkOption {
      type = types.bool;
      default = false;
      description = "Enable WiFi power saving (may reduce performance)";
    };
  };

  config = mkIf cfg.enable {
    # Ensure NetworkManager is configured for WiFi
    networking.networkmanager = {
      enable = true;
      wifi = {
        powersave = cfg.enablePowersave;
        scanRandMacAddress = true;
      };
    };

    # Add wireless tools
    environment.systemPackages = with pkgs; [
      iw
      wirelesstools
      wpa_supplicant
    ];

    # Configure WiFi networks through NetworkManager
    environment.etc = lib.mapAttrs' (name: network: {
      name = "NetworkManager/system-connections/${name}.nmconnection";
      value = {
        mode = "0600";
        text = ''
          [connection]
          id=${name}
          type=wifi
          autoconnect=${if network.autoConnect then "true" else "false"}
          autoconnect-priority=${toString network.priority}

          [wifi]
          mode=infrastructure
          ssid=${name}

          [wifi-security]
          key-mgmt=wpa-psk;sae
          psk=${network.psk}
          ieee80211w=1

          [ipv4]
          method=auto

          [ipv6]
          method=auto
        '';
      };
    }) cfg.networks;
  };
}