{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization;
in
{
  options.modules.virtualization = {
    enable = mkEnableOption "Virtualization module";

    enableQemu = mkOption {
      type = types.bool;
      default = true;
      description = "Enable QEMU";
    };

    enableLibvirtd = mkOption {
      type = types.bool;
      default = true;
      description = "Enable libvirtd";
    };

    enableVirtManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable virt-manager";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = mkIf cfg.enableLibvirtd {
      libvirtd = {
        enable = true;
        qemu = {
          ovmf.enable = true;
          runAsRoot = true;
        };
        onBoot = "start"; # Changed from "ignore" to "start"
        onShutdown = "shutdown";

        # Configure the default network for libvirtd
        networks = {
          default = {
            autoStart = true;
            config = ''
              <network>
                <name>default</name>
                <bridge name="virbr0"/>
                <forward/>
                <ip address="192.168.122.1" netmask="255.255.255.0">
                  <dhcp>
                    <range start="192.168.122.2" end="192.168.122.254"/>
                  </dhcp>
                </ip>
              </network>
            '';
          };
        };
      };
    };

    programs.virt-manager = mkIf cfg.enableVirtManager {
      enable = true;
    };

    environment.systemPackages = mkIf cfg.enableQemu [
      pkgs.qemu
    ];

    # Enable dconf, which virt-manager requires to remember settings
    programs.dconf.enable = cfg.enableVirtManager;

    # Add the current user to the libvirtd group
    users.users.${config.user.name}.extraGroups = mkIf cfg.enableLibvirtd [ "libvirtd" ];

    # Ensure the libvirtd service starts at boot
    systemd.services.libvirtd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
    };

    # Ensure the default network starts automatically
    systemd.services.libvirtd-default-network = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStart = "${pkgs.libvirt}/bin/virsh net-start default";
        ExecStop = "${pkgs.libvirt}/bin/virsh net-destroy default";
      };
    };
  };
}
