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

    enable3DAcceleration = mkEnableOption "3D acceleration for QEMU/KVM";

    username = mkOption {
      type = types.str;
      default = "notroot"; # Replace with your actual username
      description = "The username to add to the libvirtd and kvm groups.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = mkIf cfg.enableLibvirtd {
      libvirtd = {
        enable = true;
        qemu = {
          ovmf.enable = true;
          runAsRoot = true;
          swtpm.enable = true;
          package =
            if cfg.enable3DAcceleration
            then pkgs.qemu_kvm.override { gtkSupport = true; virglSupport = true; spiceSupport = true; }
            else pkgs.qemu_kvm;
        };
        onBoot = "start";
        onShutdown = "shutdown";
      };
    };

    # Define the network XML file
    environment.etc."libvirt/qemu/networks/default.xml".text = ''
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

    # Adjust the systemd service to handle the network
    systemd.services.libvirtd-default-network = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      requires = [ "libvirtd.service" ];
      after = [ "libvirtd.service" ];
      # Use 'script' for ExecStart
      script = ''
        #!/usr/bin/env bash
        # If the network is already defined, skip defining it
        if ! ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1; then
          ${pkgs.libvirt}/bin/virsh net-define /etc/libvirt/qemu/networks/default.xml
        fi
        ${pkgs.libvirt}/bin/virsh net-autostart default
        ${pkgs.libvirt}/bin/virsh net-start default
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        # Define ExecStop directly
        ExecStop = "${pkgs.bash}/bin/bash -c '\
          ${pkgs.libvirt}/bin/virsh net-destroy default || true;\
          ${pkgs.libvirt}/bin/virsh net-undefine default || true\
        '";
      };
    };

    programs.virt-manager = mkIf cfg.enableVirtManager {
      enable = true;
    };

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virglrenderer
      win-virtio
      win-spice
    ] ++ lib.optionals cfg.enable3DAcceleration [
      mesa
      mesa.drivers
    ] ++ lib.optionals cfg.enableQemu [
      qemu
    ];

    # Enable dconf, which virt-manager requires to remember settings
    programs.dconf.enable = cfg.enableVirtManager;

    # Add the specified user to the libvirtd and kvm groups
    users.users.${cfg.username}.extraGroups = mkIf cfg.enableLibvirtd [ "libvirtd" "kvm" ];

    # Ensure the libvirtd service starts at boot
    systemd.services.libvirtd = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
    };
  };
}
