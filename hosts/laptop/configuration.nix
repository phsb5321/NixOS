# NixOS Laptop Configuration - Role-Based (New Architecture)
# This is the new modular configuration using laptop profile and role-based modules
{
  config,
  pkgs,
  lib,
  systemVersion,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../../profiles/laptop.nix
    ./gnome.nix
  ];

  # Allow insecure packages for USB boot creation tool and development
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.10" # Required for ventoy-full package (uses binary blobs)
    "gradle-7.6.6" # Required for Java development - Gradle 7 EOL but needed for compatibility
  ];

  # CRITICAL: Pin kernel to 6.12.x to avoid boot failure regression in 6.17+
  # See: https://github.com/nixos/nixpkgs/issues/449939
  boot.kernelPackages = pkgs.linuxPackages_6_12;

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
      # soundOutputChooser removed: extension is dead on GNOME 45+
      # GNOME 45+ has native Quick Settings for audio output switching
      productivity = true;
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

    # Wayland configuration - NVIDIA-only mode (nvidia-drm.modeset=1 required)
    wayland = {
      enable = true;
      electronSupport = true;
      screenSharing = true;
      variant = "hardware"; # NVIDIA renders via GBM backend
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
      zen = true;
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
      streaming = true;
      imageEditing = true;
    };

    # Gaming - Steam integration
    gaming = {
      enable = true;
      performance = true;
      launchers = true;
      wine = true;
      gpuControl = false;
      minecraft = false;
    };

    # Utilities
    utilities = {
      enable = true;
      diskManagement = true;
      fileSync = false; # Syncthing handled separately
      compression = true;
      security = true;
      pdfViewer = true;
      messaging = true;
    };

    # Audio/Video
    audioVideo = {
      enable = true;
      audioControl = true;
      webcam = true;
    };

    # Terminal
    terminal = {
      enable = true;
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
    # AI Development
    claude-code

    # Development tools
    insomnia
    mongodb-compass

    # Fun extension
    gnomeExtensions.runcat

    # Communication
    telegram-desktop
    slack
    teams-for-linux
    zoom-us

    # Productivity
    notion-app-enhanced
    obsidian
    logseq

    # Advanced media (like desktop)
    blender
    krita
    kdePackages.kdenlive
    inkscape

    # Additional development tools
    git-crypt
    gnupg

    # System monitoring (like desktop)
    iotop
    atop
    smem
    numactl
    stress-ng
    memtester

    # Memory analysis (like desktop)
    heaptrack
    massif-visualizer

    # Disk utilities (like desktop)
    ncdu
    duf

    # Cloud CLI
    google-cloud-sdk

    # Containerization
    podman-compose

    # Utilities
    ventoy-full

    # NVIDIA tools (for when discrete GPU is used manually)
    nvidia-system-monitor-qt
    nvtopPackages.full

    # Laptop-specific tools
    fprintd
    iw
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

  # ===== SYNCTHING - Sync with Desktop over Tailscale =====
  # Device IDs and Tailscale IPs need to be filled in after first run
  # Run `syncthing --device-id` on each device to get IDs
  # Get Tailscale IPs with `tailscale ip -4`
  modules.services.syncthing = {
    enable = true;
    tailscaleOnly = true;
    tailscaleIP = "100.71.57.6"; # Laptop's Tailscale IP

    devices = {
      desktop = {
        id = "GBAOVC2-WXOS2NV-TOF6D7X-PR7734W-BDPSR6O-R7BEFJO-CGRLZVJ-ZTE76AU";
        addresses = ["tcp://100.84.167.121:22000"]; # Desktop's Tailscale IP
      };
    };

    folders = {
      # Code projects - bidirectional sync
      code = {
        path = "/home/notroot/Documents/Code";
        devices = ["desktop"];
        ignorePerms = true;
        versioning = {
          type = "staggered";
          params = {
            cleanInterval = "3600";
            maxAge = "2592000"; # 30 days
          };
        };
        ignorePatterns = [
          "**/postgres_data"
          "**/mongo_data"
          "**/mysql_data"
          "**/redis_data"
          "**/tmp_data"
          "**/node_modules"
          "**/.direnv"
          "**/__pycache__"
          "**/.venv"
          "**/venv"
          "**/target"
          "**/.next"
          "**/dist"
          "**/.gradle"
          "**/build"
        ];
      };

      # SSH keys and config (receive only for security)
      ssh-config = {
        path = "/home/notroot/.ssh";
        devices = ["desktop"];
        type = "receiveonly";
        ignorePerms = false;
      };

      # Dotfiles/chezmoi
      dotfiles = {
        path = "/home/notroot/.local/share/chezmoi";
        devices = ["desktop"];
        ignorePerms = true;
      };
    };
  };

  # ===== NETWORKING =====
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;
  };

  # Enable WPA3/SAE support in NetworkManager using iwd backend
  networking.networkmanager.wifi.backend = "iwd";

  # Prevent NetworkManager from blocking boot
  systemd.services.NetworkManager-wait-online.enable = false;

  modules.networking.wifi = {
    enable = true;
    enablePowersave = true;
    networks = {};
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
    allowedServices = ["ssh"];
    developmentPorts = [3000 8080];
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

    # Gaming - handled by modules/gaming/ (replaces old modules.core.gaming)

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
        extraPackages = with pkgs; [
          biber
          texlive.combined.scheme-context
        ];
      };
      markdown = {
        enable = true;
        lsp = true;
        linting = {
          enable = true;
          markdownlint = true;
          vale = {
            enable = true;
            styles = ["google" "write-good"];
          };
          linkCheck = true;
        };
        formatting = {
          enable = true;
          mdformat = true;
          prettier = false;
        };
        preview = {
          enable = true;
          glow = true;
          grip = false;
        };
        utilities = {
          enable = true;
          doctoc = true;
          mdbook = true;
          mermaid = true;
        };
      };
    };

    java = {
      enable = true;
      androidTools.enable = true;
    };
  };

  # ===== GAMING MODULES (replaces old modules.core.gaming) =====
  modules.gaming.steam = {
    enable = true;
    gamescopeSession.enable = true;
    remotePlay.enable = true;
  };
  modules.gaming.gamemode = {
    enable = true;
    customStart = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode activated' -i input-gaming";
    customEnd = "${pkgs.libnotify}/bin/notify-send 'GameMode' 'Performance mode deactivated' -i input-gaming";
  };
  modules.gaming.mangohud.enable = true;

  # Gamescope compositor - capSysNice disabled because the capability wrapper
  # fails inside Steam's FHS sandbox ("failed to inherit capabilities: Operation not permitted")
  # Gamescope falls back to regular-priority threads without it, which is acceptable.
  programs.gamescope = {
    enable = true;
    capSysNice = false;
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
    enable32Bit = true;
  };

  # Laptop hardware module
  modules.hardware.laptop = {
    enable = true;

    # Enable hybrid graphics with NVIDIA-only rendering for gaming
    # GTX 1650 Mobile renders everything; Intel iGPU used only for display output
    graphics = {
      hybridGraphics = true;
      primeMode = "nvidia-only";
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
      intelGeneration = "coffeelake"; # CML GT2 uses Coffee Lake-era i915
    };

    # Touchpad configuration (always enabled by the laptop module - cannot be disabled)
    touchpad = {
      naturalScrolling = true;
      tapToClick = true;
      disableWhileTyping = true;
    };

    # No charge threshold — laptop is always plugged in

    powerManagement = {
      profile = "performance";
      suspendTimeout = 900;
    };
  };

  # NVIDIA enabled in nvidia-only mode for gaming (GTX 1650 Mobile)

  # ===== GAMING SPECIALISATION =====
  # Default profile is already "performance", so this specialisation adds
  # mitigations=off for a 5-15% gaming boost at the cost of CPU vulnerability
  # mitigations. Select from systemd-boot menu.
  specialisation.gaming.configuration = {
    system.nixos.tags = ["gaming-mitigations-off"];

    boot.kernelParams = lib.mkAfter ["mitigations=off"];

    # Disable auto-suspend during gaming sessions
    modules.hardware.laptop.powerManagement.autoSuspend = lib.mkForce false;

    # GPU performance optimizations for gaming
    modules.gaming.gamemode.gpuOptimizations = lib.mkForce true;
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

    # NOTE: NVIDIA initrd modules are auto-configured by hardware.nix
    # when hybridGraphics=true and primeMode="nvidia-only"

    # NVIDIA-only GPU configuration
    kernelParams = lib.mkMerge [
      [
        "quiet"
        "splash"
        "i915.enable_fbc=1"
        "i915.enable_psr=1" # PSR1 only — PSR2 causes flickering on Gen9 (Coffee Lake)
        "nvme.noacpi=1" # Disables ACPI StorageD3Enable for suspend (not APST).
        # FR-008: To test removal, do 5 suspend/resume cycles and check
        # `journalctl -b | grep nvme` for disconnect errors. If none, remove.
        "nouveau.modeset=0" # Block nouveau (using proprietary NVIDIA driver)
        "nvidia-drm.modeset=1" # Required for Wayland with NVIDIA
        "nvidia-drm.fbdev=1" # Framebuffer device for early console
      ]
      (lib.mkAfter ["loglevel=3"])
    ];

    extraModprobeConfig = ''
      options iwlwifi bt_coex_active=0 swcrypto=1 11n_disable=0
      options iwlmvm power_scheme=1
      blacklist nouveau
    '';

    blacklistedKernelModules = [
      "nouveau"
      "acpi_power_meter"
    ];

    # BBR congestion control requires tcp_bbr module and fq qdisc.
    # The bbr sysctl is set by modules/networking (optimizeTCP = true by default).
    kernelModules = ["tcp_bbr"];
    kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
    };

    plymouth.enable = false;
    initrd.systemd.enable = true;
  };

  # ===== USER CONFIGURATION =====
  users.groups.plugdev = {};

  users.users.notroot = {
    isNormalUser = true;
    description = lib.mkForce "Not Root";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
      "power"
      "dialout"
      "libvirtd"
      "plugdev"
    ];
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # ===== TOUCHPAD =====
  # Touchpad is always enabled and permanently locked by the laptop hardware module.
  # See modules/hardware/laptop/hardware.nix for the implementation.

  # ===== ENVIRONMENT VARIABLES =====
  # NVIDIA-only Wayland rendering + Steam/gaming variables
  environment.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
    ELECTRON_FORCE_IS_PACKAGED = "true";
    ELECTRON_TRASH = "gio";
    STEAM_RUNTIME = "1";
    STEAM_RUNTIME_HEAVY = "1";
    DXVK_STATE_CACHE_PATH = "/tmp/dxvk_cache";
    DXVK_LOG_LEVEL = "warn";
  };

  # ===== SECURITY =====
  security = {
    pam.services = {
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };

    # auditd disabled — execve rule generated 162GB logs on desktop, adds ~98.5%
    # syscall overhead for monitored calls (Red Hat benchmarks). AppArmor provides
    # MAC enforcement independently.
    auditd.enable = false;
    audit.enable = false;

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # ===== SYSTEM STATE VERSION =====
  system.stateVersion = systemVersion;
}
