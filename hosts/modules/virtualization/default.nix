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
      default = "notroot";
      description = "Username to add to virtualization groups";
    };
  };

  config = mkIf cfg.enable {
    # Enable libvirtd
    virtualisation.libvirtd = mkIf cfg.enableLibvirtd {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        ovmf.enable = true;
        runAsRoot = true;
      };
    };

    # VM-specific configurations to support Wayland compositors like Hyprland
    virtualisation.vmVariant = {
      virtualisation.qemu.options = [
        "-device virtio-vga-gl"
        "-display sdl,gl=on,show-cursor=off"
        # Wire up pipewire audio
        "-audiodev pipewire,id=audio0"
        "-device intel-hda"
        "-device hda-output,audiodev=audio0"
      ];

      environment.sessionVariables = lib.mkVMOverride {
        WLR_NO_HARDWARE_CURSORS = "1";
        WLR_RENDERER_ALLOW_SOFTWARE = "1";
        LIBGL_ALWAYS_SOFTWARE = "1";
      };
    };

    # Enable SPICE USB redirection
    services.spice-vdagentd.enable = true;

    # Set default libvirt URI
    environment.sessionVariables.LIBVIRT_DEFAULT_URI = "qemu:///system";

    # Virt-manager configuration
    programs.virt-manager = mkIf cfg.enableVirtManager {
      enable = true;
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

    # Load necessary kernel modules for virtualization
    boot.kernelModules = [ "kvm-intel" "kvm-amd" ];

    # Enable nested virtualization (if supported by hardware)
    boot.extraModprobeConfig = ''
      options kvm-intel nested=1
      options kvm-amd nested=1
    '';

    # Enable 3D acceleration
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Add user to necessary groups
    users.users.${cfg.username}.extraGroups = [ "libvirtd" "kvm" ];

    # Polkit rule to allow users in libvirt group to manage VMs
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("libvirtd")) {
          return polkit.Result.YES;
        }
      });
    '';

    # Network configuration for libvirt
    networking = {
      firewall = {
        trustedInterfaces = [ "virbr0" ];
        allowedUDPPorts = [ 5353 ];
        allowedTCPPorts = [ 22 5900 5901 ];
      };
      bridges = {
        "virbr0" = {
          interfaces = [ ];
        };
      };
    };

    # Systemd service to ensure the default network is started
    systemd.services.libvirtd-default-network = {
      description = "libvirt default network autostart";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.libvirt}/bin/virsh net-autostart default
          ${pkgs.libvirt}/bin/virsh net-start default
        '';
      };
    };
  };
}
