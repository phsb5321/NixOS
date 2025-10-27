# NixOS Laptop Configuration - Role-Based (New Architecture)
# This is the new modular configuration using laptop profile and role-based modules
{
  config,
  pkgs,
  lib,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Allow insecure packages for USB boot creation tool
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.07" # Required for ventoy-full package
  ];

  # ===== LAPTOP PROFILE =====
  # Laptop profile with standard variant for balanced performance/battery
  modules.profiles.laptop = {
    enable = true;
    variant = "standard"; # Options: "ultrabook", "gaming", "workstation", "standard"

    gnomeExtensions = {
      minimal = false; # Use full extension set
      productivity = true; # Enable productivity extensions
    };
  };

  # ===== GNOME DESKTOP =====
  modules.desktop.gnome = {
    enable = true;

    # Base configuration
    displayManager = true;
    coreServices = true;
    coreApplications = true;
    themes = true;
    portal = true;
    powerManagement = true;

    # Extensions
    extensions = {
      enable = true;
      appIndicator = true;
      dashToDock = true;
      userThemes = true;
      justPerfection = true;
      vitals = true;
      caffeine = true;
      clipboard = true;
      gsconnect = true;
      workspaceIndicator = true;
    };

    # Settings
    settings = {
      enable = true;
      darkMode = true;
      animations = true;
      hotCorners = false;
      batteryPercentage = true;
      weekday = true;
    };

    # Wayland configuration - Force X11 for NVIDIA compatibility
    wayland = {
      enable = lib.mkForce false; # Use X11 for NVIDIA laptop
      electronSupport = false;
      screenSharing = false;
      variant = "software";
    };
  };

  # ===== PACKAGE CONFIGURATION =====
  modules.packages = {
    # Browsers
    browsers = {
      enable = true;
      chrome = true;
      brave = true;
      librewolf = true;
      zen = false; # Less critical for laptop
    };

    # Development tools
    development = {
      enable = true;
      editors = true;
      apiTools = true;
      runtimes = true;
      compilers = true;
      languageServers = true;
      versionControl = true;
      utilities = true;
      database = true;
      containers = true;
      debugging = true;
      networking = true;
    };

    # Media
    media = {
      enable = true;
      vlc = true;
      spotify = true;
      discord = true;
      streaming = false; # Less critical for laptop
      imageEditing = true;
    };

    # Gaming - Steam integration
    gaming = {
      enable = true;
      performance = true;
      launchers = true;
      wine = true;
      gpuControl = false; # NVIDIA disabled
      minecraft = false;
    };

    # Utilities
    utilities = {
      enable = true;
      diskManagement = true;
      fileSync = false; # Syncthing handled by profile
      compression = true;
      security = true;
      pdfViewer = true;
      messaging = true;
      fonts = true;
    };

    # Audio/Video
    audioVideo = {
      enable = true;
      pipewire = true;
      audioEffects = true;
      audioControl = true;
      webcam = true;
    };

    # Terminal
    terminal = {
      enable = true;
      fonts = true;
      shell = true;
      theme = true;
      modernTools = true;
      plugins = true;
      editor = true;
      applications = true;
    };
  };

  # ===== HOST-SPECIFIC PACKAGES =====
  environment.systemPackages = with pkgs; [
    # Development tools
    insomnia
    mongodb-compass

    # Fun extension
    gnomeExtensions.runcat # Running cat shows CPU usage

    # Communication
    slack
    teams-for-linux
    zoom-us

    # Productivity
    obsidian
    logseq

    # Cloud CLI
    google-cloud-sdk

    # Containerization
    podman-compose

    # Utilities
    ventoy-full # Bootable USB creation

    # AI Development
    claude-code

    # NVIDIA tools (for when discrete GPU is used manually)
    nvidia-system-monitor-qt
    nvtopPackages.full

    # Laptop-specific tools
    fprintd # Fingerprint support
    iw # WiFi management
    wirelesstools
  ];

  # ===== SERVICES =====
  # Fingerprint reader
  services.fprintd.enable = true;

  # Thunderbolt support
  services.hardware.bolt.enable = true;

  # Location services
  services.geoclue2.enable = true;

  # Printing
  services.printing = {
    enable = true;
    drivers = [
      pkgs.hplip
      pkgs.gutenprint
    ];
  };

  # SSD optimization
  services.fstrim.enable = true;

  # ===== NETWORKING =====
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;
  };

  # Enable WPA3/SAE support in NetworkManager using iwd backend
  networking.networkmanager.wifi.backend = "iwd";

  modules.networking.wifi = {
    enable = true;
    enablePowersave = true; # For laptop battery life
    networks = {
      # WiFi network configuration
      "LIVE TIM_4122" = {
        psk = "benicio-tem-4-patas-cinzas";
        priority = 100;
        autoConnect = true;
      };
    };
  };

  modules.networking.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    extraUpFlags = [
      "--accept-routes"
      "--accept-dns"
    ];
  };

  modules.networking.firewall = {
    enable = true;
    allowedServices = [ "ssh" ];
    developmentPorts = [ 3000 8080 ];
    tailscaleCompatible = true;
  };

  modules.networking.remoteDesktop = {
    enable = true;
    client.enable = true;
    server.enable = false;
    firewall.openPorts = false;
  };

  # ===== CORE MODULES =====
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";

    # ABNT2 keyboard for Brazil
    keyboard = {
      enable = true;
      variant = ",abnt2";
    };

    # Gaming for Steam
    gaming = {
      enable = true;
      enableSteam = true;
    };

    pipewire = {
      enable = true;
      highQualityAudio = true;
      bluetooth.enable = true;
      bluetooth.highQualityProfiles = true;
      lowLatency = false;
      tools.enable = true;
    };

    documentTools = {
      enable = true;
      latex = {
        enable = true;
        minimal = false;
      };
      markdown = {
        enable = true;
        lsp = true;
        linting.enable = true;
        formatting.enable = true;
        preview.enable = true;
        utilities.enable = true;
      };
    };
  };

  # ===== DOTFILES =====
  modules.dotfiles = {
    enable = true;
    enableHelperScripts = true;
  };

  # ===== HARDWARE =====
  # Enable WiFi firmware
  hardware.enableRedistributableFirmware = true;

  # OpenGL/Vulkan for gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For Steam and 32-bit games
  };

  # Laptop hardware module (already configured by profile, but can override)
  modules.hardware.laptop = {
    enable = true;

    # Disable hybrid graphics - causes blank screen
    graphics = {
      hybridGraphics = false; # NVIDIA disabled
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    batteryManagement.chargeThreshold = 85;

    powerManagement = {
      profile = "balanced";
      suspendTimeout = 900; # 15 minutes
    };
  };

  # ===== BOOT CONFIGURATION =====
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    kernelParams = [
      "quiet"
      "splash"
      "i915.enable_fbc=1" # Frame buffer compression
      "i915.enable_psr=2" # Panel self refresh
      "nvme.noacpi=1" # Better NVMe power management
    ];

    plymouth = {
      enable = true;
      theme = "breeze";
    };

    initrd.systemd.enable = true;
  };

  # ===== USER CONFIGURATION =====
  users.users.notroot = {
    isNormalUser = true;
    description = "Not Root";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video" # Brightness control
      "input" # Touchpad gestures
      "power" # Power management
    ];
  };

  # ===== ENVIRONMENT VARIABLES =====
  environment.sessionVariables = {
    # Touchpad gestures in Firefox
    MOZ_USE_XINPUT2 = "1";

    # Electron apps scaling
    ELECTRON_FORCE_IS_PACKAGED = "true";
    ELECTRON_TRASH = "gio";

    # Steam optimizations
    STEAM_RUNTIME = "1";
    STEAM_RUNTIME_HEAVY = "1";

    # DXVK optimizations
    DXVK_STATE_CACHE_PATH = "/tmp/dxvk_cache";
    DXVK_LOG_LEVEL = "warn";
  };

  # ===== SYSTEM STATE VERSION =====
  system.stateVersion = systemVersion;
}
