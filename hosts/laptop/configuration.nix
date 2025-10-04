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

  # Allow insecure packages for USB boot creation tool
  # TODO: Monitor for secure ventoy releases and remove this exception
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.07" # Required for ventoy-full package - bootable USB creation
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

    # Enable gaming for Steam integration
    gaming = {
      enable = true;
      enableSteam = true;
    };
  };

  # Networking configuration with Tailscale
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;


    # Tailscale for secure mobile connectivity
    tailscale = {
      enable = true;
      useRoutingFeatures = "client"; # Can use exit nodes and subnet routes
      extraUpFlags = [
        "--accept-routes"
        "--accept-dns"
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
    gaming.enable = true; # Enable for Steam integration

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

      # AI Development Tools
      claude-code # Claude Code terminal-based coding assistant (binary name: claude)
      # Usage: claude --help for options, claude for interactive mode
      # Note: Also install Claude Code VS Code extension manually:
      # - Open VS Code Extensions (Ctrl+Shift+X)
      # - Search for "claude-code" by Anthropic
      # - Install the extension for IDE integration

      # NVIDIA tools for manual gaming usage
      nvidia-system-monitor-qt
      nvtopPackages.full
    ];
  };

  # Enable GNOME desktop
  modules.desktop.gnome = {
    enable = true;
    wayland.enable = lib.mkForce false; # Force X11 for NVIDIA compatibility
  };

  # Enable OpenGL/Vulkan for gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam and 32-bit games
  };

  # Firewall configuration for laptop (more secure on public WiFi)
  modules.networking.firewall = {
    enable = true;
    allowedServices = [ "ssh" ];
    developmentPorts = [ 3000 8080 ];
    tailscaleCompatible = lib.mkForce true;  # Since Tailscale is enabled
  };

  # Remote Desktop Configuration
  modules.networking.remoteDesktop = {
    enable = true;
    client.enable = true;  # Enable VNC/RDP client tools
    server = {
      enable = false;  # Set to true if you want to access this machine remotely
      gnomeRemoteDesktop = true;  # Use GNOME's modern remote desktop
      vnc.enable = false;  # Traditional VNC server
      rdp.enable = false;  # xrdp server
    };
    firewall.openPorts = false;  # Set to true when server is enabled
  };

  # Hardware-specific overrides
  modules.hardware.laptop = {
    enable = true;

    # Disable hybrid graphics - causing blank screen issues
    graphics = {
      hybridGraphics = false; # Disable NVIDIA to restore display
      intelBusId = "PCI:0:2:0"; # Intel UHD Graphics
      nvidiaBusId = "PCI:1:0:0"; # GeForce GTX 1650 Mobile
    };

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

  # NVIDIA Configuration is now handled by modules.hardware.laptop

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
      drivers = [
        pkgs.hplip
        pkgs.gutenprint
      ];
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

    # Steam optimizations
    STEAM_RUNTIME = "1";
    STEAM_RUNTIME_HEAVY = "1";

    # DXVK optimizations for laptop
    DXVK_STATE_CACHE_PATH = "/tmp/dxvk_cache";
    DXVK_LOG_LEVEL = "warn";
  };

  # System state version
  system.stateVersion = systemVersion;
}
