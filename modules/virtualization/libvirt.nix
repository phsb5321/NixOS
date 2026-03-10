# QEMU/KVM + libvirt Virtualization
# Provides virt-manager, SPICE display, VirtIO drivers, and optional Windows 11 support
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.virtualization.libvirt;
in {
  options.modules.virtualization.libvirt = with lib; {
    enable = mkEnableOption "QEMU/KVM virtualization with libvirt and virt-manager";

    windowsSupport = mkOption {
      type = types.bool;
      default = true;
      description = "Enable OVMF Secure Boot, TPM 2.0 emulation, and VirtIO/SPICE Windows drivers";
    };

    nestedVirtualization = mkOption {
      type = types.bool;
      default = false;
      description = "Allow running VMs inside VMs (Intel VMX / AMD SVM)";
    };

    ignoreMSRs = mkOption {
      type = types.bool;
      default = true;
      description = "Ignore unhandled MSRs to prevent Windows guest BSODs";
    };

    vfioPrepare = mkOption {
      type = types.bool;
      default = false;
      description = "Future: load VFIO kernel modules and enable IOMMU for GPU passthrough";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── libvirtd daemon ──────────────────────────────────────────────
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore"; # Don't auto-start VMs at boot
      onShutdown = "shutdown"; # Gracefully shut down running VMs

      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = cfg.windowsSupport;

        vhostUserPackages = [pkgs.virtiofsd];
      };
    };

    # ── SPICE USB redirection ────────────────────────────────────────
    virtualisation.spiceUSBRedirection.enable = true;

    # ── virt-manager GUI ─────────────────────────────────────────────
    programs.virt-manager.enable = true;

    # ── Packages ─────────────────────────────────────────────────────
    environment.systemPackages = with pkgs;
      [
        virt-manager
        virt-viewer
        spice-gtk
        spice-protocol
        virtiofsd
        dnsmasq
      ]
      ++ lib.optionals cfg.windowsSupport [
        virtio-win
        win-spice
      ];

    # ── Networking ───────────────────────────────────────────────────
    # Trust the default libvirt NAT bridge for VM traffic
    networking.firewall.trustedInterfaces = ["virbr0"];

    # ── User groups ──────────────────────────────────────────────────
    users.users.notroot.extraGroups = lib.mkAfter ["libvirtd" "kvm"];

    # ── Kernel / modprobe tunables ───────────────────────────────────
    boot.extraModprobeConfig = let
      nested =
        lib.optionalString cfg.nestedVirtualization
        "options kvm_intel nested=1";
      msrs =
        lib.optionalString cfg.ignoreMSRs
        "options kvm ignore_msrs=1 report_ignored_msrs=0";
    in
      lib.concatStringsSep "\n" (lib.filter (s: s != "") [nested msrs]);
  };
}
