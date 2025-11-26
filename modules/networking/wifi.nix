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
            type = types.nullOr types.str;
            default = null;
            description = "WiFi password/PSK (plain text, not recommended)";
          };
          pskFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path to file containing WiFi password/PSK (recommended for secrets)";
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

  config = mkIf cfg.enable (mkMerge [
    {
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
    }

    # Networks with direct PSK (plain text)
    (mkIf (any (n: n.psk != null) (attrValues cfg.networks)) {
      environment.etc = lib.mapAttrs' (name: network:
        lib.nameValuePair
        "NetworkManager/system-connections/${name}.nmconnection"
        {
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
        })
      (lib.filterAttrs (_: n: n.psk != null) cfg.networks);
    })

    # Networks with PSK from file (secrets)
    (mkIf (any (n: n.pskFile != null) (attrValues cfg.networks)) {
      systemd.services = lib.mapAttrs' (name: network:
        lib.nameValuePair
        "wifi-secret-${lib.replaceStrings [" " "_"] ["-" "-"] name}"
        {
          description = "Setup WiFi connection ${name} with secret";
          wantedBy = ["multi-user.target"];
          after = ["NetworkManager.service"];
          before = ["network-online.target"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = let
            pskValue = "$(cat ${network.pskFile})";
          in ''
            # Create NetworkManager connection file with secret
            mkdir -p /etc/NetworkManager/system-connections
            cat > /etc/NetworkManager/system-connections/${name}.nmconnection <<EOF
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
            psk=${pskValue}
            ieee80211w=1

            [ipv4]
            method=auto

            [ipv6]
            method=auto
            EOF

            chmod 0600 /etc/NetworkManager/system-connections/${name}.nmconnection

            # Reload NetworkManager to pick up the new connection
            ${pkgs.networkmanager}/bin/nmcli connection reload
          '';
        })
      (lib.filterAttrs (_: n: n.pskFile != null) cfg.networks);
    })
  ]);
}
