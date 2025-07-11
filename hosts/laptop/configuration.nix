# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  bleedPkgs,
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
  modules.home.hostName = "laptop";

  # Enable auto-login for laptop convenience
  modules.desktop.autoLogin = {
    enable = lib.mkForce true;
    user = "notroot";
  };

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = lib.mkForce false; # Disabled for laptop to save space
    };
  };

  # 🎯 NVIDIA GPU: Enable Nvidia GPU support with optimized laptop configuration
  modules.hardware.nvidia = {
    enable = true;

    # GPU Bus IDs (verified with lspci)
    intelBusId = "PCI:0:2:0";  # Intel UHD Graphics
    nvidiaBusId = "PCI:1:0:0"; # GeForce GTX 1650 Mobile

    # Driver configuration - GTX 1650 Mobile uses Turing architecture
    driver = {
      version = "stable";
      openSource = true; # Turing architecture supports open drivers
    };

    # PRIME configuration - offload mode for battery efficiency
    prime = {
      mode = "offload"; # Use Intel by default, offload to Nvidia when needed
      allowExternalGpu = false;
    };

    # Power management optimized for laptops
    powerManagement = {
      enable = false; # Disable experimental power management
      finegrained = true; # Enable fine-grained power management for Turing+
    };

    # Performance settings
    performance = {
      forceFullCompositionPipeline = false; # Don't force to avoid WebGL issues
    };

    # Laptop-specific features
    laptop = {
      enableSpecializations = true; # Enable performance/battery boot options
      enableOffloadWrapper = true; # Create nvidia-offload command
    };
  };

  # Laptop-specific package preferences
  modules.packages.gaming.enable = true; # Enable gaming with Nvidia GPU

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
  services.power-profiles-daemon.enable = lib.mkForce false; # Disable to use TLP instead
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Laptop-specific networking - no special ports needed
  modules.networking.firewall.openPorts = [22]; # SSH only

  # Laptop-specific bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
