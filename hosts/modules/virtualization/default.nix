{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.virtualization;
in
{
  options.modules.virtualization = {
    enable = mkEnableOption "Enable the virtualization module";

    enableLibvirtd = mkOption {
      type = types.bool;
      default = true;
      description = "Enable libvirtd for managing virtual machines";
    };

    enableVirtManager = mkOption {
      type = types.bool;
      default = true;
      description = "Enable virt-manager for VM GUI management";
    };

    username = mkOption {
      type = types.str;
      example = "alice";
      description = "Username to add to virtualization groups";
    };
  };

  config = mkIf cfg.enable {
    # Libvirtd configuration
    virtualisation.libvirtd = mkIf cfg.enableLibvirtd {
      enable = true;
      qemu = {
        ovmf.enable = true;
        runAsRoot = true;
        swtpm.enable = true;
        verbatimConfig = ''
          unix_sock_group = "libvirtd"
          unix_sock_rw_perms = "0770"
          spice_listen = "unix"
          spice_auto_unix_socket = "on"
          nographics_allow_host_audio = 1
          vnc_allow_host_audio = 1
          spice_gl = "on"
          spice_rendernode = "/dev/dri/renderD128"
        '';
      };
      onBoot = "start";
      onShutdown = "shutdown";
    };

    # QEMU configuration for SPICE and GL support
    virtualisation.spiceUSBRedirection.enable = true;
    environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

    # Virt-manager configuration
    programs.virt-manager = mkIf cfg.enableVirtManager {
      enable = true;
    };

    # Default network configuration for libvirtd
    environment.etc."libvirt/qemu/networks/default.xml".text = ''
      <network>
        <name>default</name>
        <bridge name="virbr0"/>
        <forward mode="nat"/>
        <ip address="192.168.122.1" netmask="255.255.255.0">
          <dhcp>
            <range start="192.168.122.2" end="192.168.122.254"/>
          </dhcp>
        </ip>
      </network>
    '';

    # Systemd service to ensure the default network is started
    systemd.services.libvirtd-default-network = mkIf cfg.enableLibvirtd {
      description = "libvirtd default network";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '
            ${pkgs.libvirt}/bin/virsh net-define /etc/libvirt/qemu/networks/default.xml
            ${pkgs.libvirt}/bin/virsh net-autostart default
            ${pkgs.libvirt}/bin/virsh net-start default
          '
        '';
      };
    };

    # Include necessary packages
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice-gtk
      spice-protocol
      qemu
      OVMF
    ];

    # Enable dconf for virt-manager settings persistence
    programs.dconf.enable = cfg.enableVirtManager;

    # Add the user to required groups for virtualization
    users.users.${cfg.username}.extraGroups = [
      "libvirtd"
      "kvm"
    ];

    # Load necessary kernel modules for virtualization
    boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

    # Enable nested virtualization (if supported by hardware)
    boot.extraModprobeConfig = ''
      options kvm-intel nested=1
      options kvm-amd nested=1
    '';

    # Enable 3D acceleration
    hardware.opengl.enable = true;
    hardware.opengl.driSupport32Bit = true;

    # Ensure libvirtd service is running and enabled
    systemd.services.libvirtd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.qemu ];
      serviceConfig = {
        KillMode = lib.mkForce "process";
        Restart = lib.mkForce "on-failure";
        RestartSec = lib.mkForce "1s";
      };
    };

    # Set permissions for libvirt socket directory
    systemd.tmpfiles.rules = [
      "d /var/run/libvirt 0755 root root -"
      "d /var/run/libvirt/qemu 0755 root root -"
    ];
  };
}
