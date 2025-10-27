# NixOS Server Configuration - Simplified modular approach like laptop
# VM host running GNOME in X11 mode for compatibility
{
  config,
  pkgs,
  pkgs-unstable,
  stablePkgs,
  inputs,
  systemVersion,
  hostname,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
    ./gnome.nix
  ];

  # Host-specific metadata
  modules.networking.hostName = lib.mkForce hostname;

  # Override shared networking config for server-specific needs
  modules.networking = {
    dns = {
      enableSystemdResolved = lib.mkForce false; # Override for manual DNS
      enableDNSOverTLS = lib.mkForce false;
    };
    firewall.openPorts = [22 3000]; # SSH and development server
  };

  # Manual DNS configuration for server stability
  networking = {
    nameservers = lib.mkForce ["8.8.8.8" "8.8.4.4" "1.1.1.1"];
    networkmanager.dns = lib.mkForce "none";
  };

  # Disable systemd-resolved to avoid conflicts
  services.resolved.enable = lib.mkForce false;

  # Disable gaming module - not needed for server and prevents NVIDIA vars
  modules.core.gaming.enable = lib.mkForce false;

  # Explicitly enable X11 for VM compatibility with proper video drivers
  services.xserver = {
    enable = true;
    # Video driver configuration for Proxmox QEMU VM
    # Supports both VirtIO-GPU and QXL display types
    videoDrivers = ["modesetting" "qxl" "virtio"];

    # Enable DRI3 for hardware acceleration in VirtIO-GPU VMs
    # This fixes "libEGL warning: DRI3 error: Could not get DRI3 device"
    deviceSection = ''
      Option "DRI" "3"
    '';
  };

  # Disable Qt theming due to qgnomeplatform Qt6 build issues on stable nixpkgs
  # This is a known issue - see: https://github.com/NixOS/nixpkgs/issues/315121
  qt = {
    enable = lib.mkForce false;
  };

  # Bootloader - GRUB for BIOS systems
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # Proxmox VM hardware optimization
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Enable 3D acceleration for Proxmox VMs with VirtIO-GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Mesa with full DRI drivers for VirtIO-GPU hardware acceleration
      mesa
      # VirtIO-GPU 3D acceleration support (VirGL renderer)
      virglrenderer
      # Additional OpenGL/EGL support
      libGL
      libGLU
      # Vulkan support for VirtIO-GPU
      vulkan-loader
    ];
  };

  # Proxmox VM-specific environment variables for graphics (override GNOME module)
  environment.sessionVariables = {
    # Enable software rendering fallback for compatibility
    LIBGL_ALWAYS_SOFTWARE = "0";
    # Mesa DRI driver configuration for VMs
    MESA_LOADER_DRIVER_OVERRIDE = "virtio_gpu";
    # GSK_RENDERER is now set in gnome.nix
  };

  # Enable Docker
  virtualisation.docker.enable = true;

  # Configure console keymap to match original config
  console.keyMap = lib.mkForce "br-abnt2";

  # Enable automatic login for the user (matching original config)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

  # Enable selected desktop packages
  modules.packages = {
    browsers.enable = lib.mkForce true;
    media.enable = lib.mkForce true;
    gaming.enable = lib.mkForce false; # Keep disabled for server
    audioVideo.enable = lib.mkForce true;

    # Server-specific monitoring packages
    extraPackages = with pkgs; [
      # Server monitoring and management
      iotop
      nethogs
      ncdu
      lsof
      strace
      htop
      btop

      # Additional server tools
      wget
      git
      claude-code

      # Proxmox VM guest tools
      qemu-utils
      spice-vdagent
    ];
  };

  # System state version
  system.stateVersion = systemVersion;
}
