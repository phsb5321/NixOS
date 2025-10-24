# NixOS Server Configuration - Integrated with modular ecosystem
# Uses X11 mode for VM compatibility but leverages shared modules
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

  # GNOME Desktop Environment - X11 mode for VM compatibility
  modules.desktop.gnome = {
    enable = true;
    variant = "hardware";
    wayland.enable = false; # Use X11 for better VM compatibility
  };

  # Force X11 backend for GNOME in VM environment
  environment.sessionVariables = {
    # Force GNOME to use X11 backend in VM
    MUTTER_DEBUG_FORCE_KMS_MODE = "off";
    MUTTER_DEBUG_FORCE_BACKEND = "x11";
    # Disable Wayland environment variables from shared config
    NIXOS_OZONE_WL = lib.mkForce "0";
    XDG_SESSION_TYPE = lib.mkForce "x11";
    GDK_BACKEND = lib.mkForce "x11";
    QT_QPA_PLATFORM = lib.mkForce "xcb";
  };

  # X server configuration for VM-optimized drivers and keyboard
  services.xserver = {
    enable = true;
    # QXL is optimal for KVM/QEMU VMs, fallback to modesetting
    videoDrivers = lib.mkForce ["qxl" "modesetting"];

    # Configure keymap to match original config
    xkb = {
      layout = "br";
      variant = lib.mkForce "";
    };
  };

  # Bootloader - GRUB for BIOS systems
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # VM hardware optimization
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Enable Docker
  virtualisation.docker.enable = true;

  # Configure console keymap to match original config
  console.keyMap = lib.mkForce "br-abnt2";

  # Enable automatic login for the user (matching original config)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

  # Workaround for GNOME autologin (from original config)
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Exclude problematic packages from GNOME to work around Qt6 build issues
  environment.gnome.excludePackages = with pkgs; [
    qgnomeplatform  # Exclude the broken Qt6 package
  ];

  # Disable Qt theming to avoid qgnomeplatform Qt6 build issues
  qt.enable = lib.mkForce false;

  # Enable selected desktop packages (temporarily reduced due to Qt6 build issues)
  modules.packages = {
    browsers.enable = lib.mkForce true;
    media.enable = lib.mkForce true; # Re-enable with Qt6 workaround
    gaming.enable = lib.mkForce false; # Keep disabled for server
    audioVideo.enable = lib.mkForce true; # Re-enable with Qt6 workaround

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
    ];
  };

  # Note: stateVersion is managed by the flake system
}
