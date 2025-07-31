# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;

  # Override shared configuration as needed
  modules.networking.hostName = hostname;
  # Note: Home Manager removed - packages are now managed at system level

  # Enable auto-login for laptop convenience
  modules.desktop.autoLogin = {
    enable = true;
    user = "notroot";
  };

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex.enable = false; # Disabled for laptop to save space
  };

  # Laptop-specific package preferences (disabled gaming to save battery)
  modules.packages.gaming.enable = false;

  # Laptop-specific extra packages
  modules.packages.extraPackages = with pkgs; [
    # Laptop-specific utilities
    powertop
    tlp

    # Development tools for mobile work
    git
    vim
    curl
    wget
  ];

  # Laptop-specific power management
  services.power-profiles-daemon.enable = false; # Use TLP instead
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Laptop-specific networking - no special ports needed
  modules.networking.firewall.openPorts = [22]; # SSH only

  # Enable explicit keyboard configuration for laptop (ABNT2)
  modules.core.keyboard = {
    enable = true;
    variant = ",abnt2";
  };

  # NVIDIA GPU configuration for laptop
  modules.hardware.nvidia = {
    enable = true;
    intelBusId = "PCI:0:2:0"; # Intel UHD Graphics
    nvidiaBusId = "PCI:1:0:0"; # GeForce GTX 1650 Mobile
    prime.mode = "sync"; # Use sync mode for better GNOME compatibility
    driver.version = "stable";
    driver.openSource = false; # Use proprietary drivers for GTX 1650
    powerManagement.enable = false; # Disabled for sync mode
    powerManagement.finegrained = false; # Disabled for sync mode
    performance.forceFullCompositionPipeline = true; # Reduce tearing
  };

  # Laptop-specific bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop configuration - NVIDIA requires X11
  modules.desktop.displayManager = {
    wayland = false; # X11 for NVIDIA compatibility
    autoSuspend = false; # Keep laptop awake
  };
  # Disable problematic GNOME services for NVIDIA
  services.gnome.tinysparql.enable = false;
  services.gnome.localsearch.enable = false;
  # NVIDIA-specific X11 environment variables
  environment.sessionVariables = {
    # Force X11 for NVIDIA compatibility
    XDG_SESSION_TYPE = "x11";
    GDK_BACKEND = "x11";
    QT_QPA_PLATFORM = "xcb";

    # NVIDIA optimizations
    __GL_SYNC_TO_VBLANK = "1";
    __GL_VRR_ALLOWED = "0";
    MUTTER_DEBUG_FORCE_KMS_MODE = "simple";
  };

  # Additional laptop-specific NVIDIA fixes

  # Force NVIDIA as primary GPU for GNOME
  services.xserver.screenSection = ''
    Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option "AllowIndirectGLXProtocol" "off"
    Option "TripleBuffer" "on"
  '';
}
