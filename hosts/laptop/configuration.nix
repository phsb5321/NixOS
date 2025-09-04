# ~/NixOS/hosts/laptop/configuration.nix
# Laptop host configuration using modular profile system
{
  config,
  pkgs,
  systemVersion,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Allow insecure packages (required for ventoy)
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.05"
  ];

  # Use the laptop profile for automatic configuration
  modules.profiles.laptop = {
    enable = true;
    variant = "standard"; # Options: "ultrabook", "gaming", "workstation", "standard"

    gnomeExtensions = {
      minimal = false; # Use full extension set
      productivity = true; # Enable productivity extensions
    };
  };

  # Host-specific overrides
  modules.core = {
    enable = true;
    stateVersion = systemVersion;

    # Brazil locale settings
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";

    # Enable explicit keyboard configuration for laptop (ABNT2)
    keyboard = {
      enable = true;
      variant = ",abnt2";
    };
  };

  # Networking configuration
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;

    # Laptop-specific network settings
    firewall = {
      enable = true;
      allowPing = lib.mkDefault false; # More secure on public WiFi
      openPorts = [
        22 # SSH
        3000 # Development server
        8080 # Development server
      ];
    };
  };

  # Package configuration with laptop optimizations
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    utilities.enable = true;
    terminal.enable = true;
    media.enable = true;
    audioVideo.enable = true;
    gaming.enable = false; # Save battery by default

    # Additional laptop-specific packages
    extraPackages = with pkgs; [
      # Development tools for workstation variant
      insomnia
      mongodb-compass

      # The fun cat extension you requested!
      gnomeExtensions.runcat # Running cat shows CPU usage

      # Communication tools
      slack
      teams-for-linux
      zoom-us

      # Note-taking and productivity
      obsidian
      logseq

      # Cloud CLI tools
      google-cloud-sdk

      # Containerization
      podman-compose

      # Additional utilities
      ventoy-full # For creating bootable USB drives
      # etcher # Alternative USB flashing tool - package not found
    ];
  };

  # Hardware-specific overrides
  modules.hardware.laptop = {
    batteryManagement.chargeThreshold = 85; # Preserve battery health

    powerManagement = {
      profile = "balanced";
      suspendTimeout = 900; # 15 minutes
    };

    # Additional laptop hardware packages
    extraPackages = with pkgs; [
      # Fingerprint support (if available)
      fprintd

      # Better WiFi management
      iw
      wirelesstools
    ];
  };

  # NVIDIA Configuration (if applicable)
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Important for laptops!
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Boot configuration optimized for laptops
  boot = {
    # Use systemd-boot for UEFI systems
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # Keep last 10 generations
      };
      efi.canTouchEfiVariables = true;
      timeout = 3; # Boot menu timeout in seconds
    };

    # Quiet boot for better laptop experience
    kernelParams = [
      "quiet"
      "splash"
      "i915.enable_fbc=1" # Frame buffer compression
      "i915.enable_psr=2" # Panel self refresh
      "nvme.noacpi=1" # Better NVMe power management
    ];

    # Plymouth for graphical boot
    plymouth = {
      enable = true;
      theme = "breeze";
    };

    # Faster boot times
    initrd.systemd.enable = true;
  };

  # Services specific to laptop use cases
  services = {
    # Enable fingerprint reader if available
    fprintd.enable = true;

    # Better laptop integration
    hardware.bolt.enable = true; # Thunderbolt support

    # Enable location services for weather, maps, etc.
    geoclue2.enable = true;

    # Printing support (often needed on laptops)
    printing = {
      enable = true;
      drivers = [pkgs.hplip pkgs.gutenprint];
    };

    # Optimize SSD performance
    fstrim.enable = true;
  };

  # User configuration
  users.users.notroot = {
    extraGroups = [
      "networkmanager"
      "wheel"
      "video" # For brightness control
      "input" # For touchpad gestures
      "power" # For power management
    ];
  };

  # Environment variables for laptop usage
  environment.sessionVariables = {
    # Better touchpad gestures in Firefox
    MOZ_USE_XINPUT2 = "1";

    # Electron apps scaling
    ELECTRON_FORCE_IS_PACKAGED = "true";
    ELECTRON_TRASH = "gio";
  };

  # This value determines the NixOS release
  system.stateVersion = systemVersion;
}
