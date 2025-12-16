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
    # inputs.sops-nix.nixosModules.sops  # Disabled until sops-nix is configured
  ];

  # Allow insecure packages for USB boot creation tool and development
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.07" # Required for ventoy-full package
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
      soundOutputChooser = true; # Add missing extension from desktop
      productivity = true; # Enable productivity bundle
      
      # Popular additional extensions (disabled by default)
      blurMyShell = false; # Beautiful blur effects
      popShell = false; # Tiling window management
      burnMyWindows = false; # Window close animations
      windowList = false; # Taskbar-style window list
      removableDriveMenu = true; # Useful for laptop
      altTab = true; # Better Alt+Tab behavior
      systemMonitor = true; # System monitoring extension
      batteryClock = true; # Battery info in top bar - useful for laptop
      gpuStats = false; # GPU monitoring (less useful on laptop)
      netspeedSimplified = true; # Network speed monitoring
      windowTitles = false; # Window titles on panel
      topIndicators = true; # Top indicators (TopHat)
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
      zen = true; # Enable Zen browser
      firefoxNightly = true; # Enable Firefox Nightly
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
      streaming = true; # Enable streaming like desktop
      imageEditing = true;
    };

    # Gaming - Steam integration
    gaming = {
      enable = true;
      performance = true;
      launchers = true;
      wine = true;
      gpuControl = false; # NVIDIA disabled for laptop
      minecraft = false; # Match desktop setting
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
    # AI Development
    claude-code

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

    # Development tools
    insomnia
    mongodb-compass
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
    ventoy-full # Bootable USB creation

    # Fun extension
    gnomeExtensions.runcat # Running cat shows CPU usage

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

  # Prevent NetworkManager from blocking boot
  systemd.services.NetworkManager-wait-online.enable = false;

  # ===== SECRETS MANAGEMENT =====
  # Disabled WiFi secret until sops-nix is properly configured
  # sops = {
  #   defaultSopsFile = ../../secrets/laptop.yaml;
  #   age.keyFile = "/var/lib/sops-nix/key.txt";
  #
  #   secrets = {
  #     wifi_live_tim_4122_psk = {
  #       mode = "0400";
  #     };
  #   };
  # };

  modules.networking.wifi = {
    enable = true;
    enablePowersave = true; # For laptop battery life
    networks = {
      # WiFi network configuration - using NetworkManager GUI for now
      # "LIVE TIM_4122" = {
      #   pskFile = config.sops.secrets.wifi_live_tim_4122_psk.path;
      #   priority = 100;
      #   autoConnect = true;
      # };
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
            styles = [ "google" "write-good" ];
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

    # Touchpad configuration - always enabled
    touchpad = {
      enable = true;
      naturalScrolling = true;
      tapToClick = true;
      disableWhileTyping = true;
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

    kernelParams = lib.mkMerge [
      [
        "quiet"
        "splash"
        "i915.enable_fbc=1" # Frame buffer compression
        "i915.enable_psr=2" # Panel self refresh
        "nvme.noacpi=1" # Better NVMe power management
        
        # ACPI fixes for SAC1 BufferField BIOS errors
        "acpi=strict" # Force strict ACPI compliance
        
        # Nouveau/NVIDIA fixes for hybrid graphics issues  
        "nouveau.modeset=0" # Disable nouveau kernel mode setting
        "nvidia-drm.modeset=0" # Disable NVIDIA DRM mode setting
        "nomodeset" # Fallback - disable kernel mode setting entirely
      ]
      (lib.mkAfter ["loglevel=3"]) # Ensure loglevel=3 overrides default loglevel=4
    ];

    # Fix iwlwifi warnings during boot
    extraModprobeConfig = ''
      # Intel Wi-Fi firmware configuration
      options iwlwifi bt_coex_active=0 swcrypto=1 11n_disable=0
      options iwlmvm power_scheme=1
      
      # Blacklist nouveau to prevent MMU faults and conflicts
      blacklist nouveau
      blacklist nvidia
      blacklist nvidia_drm
      blacklist nvidia_modeset
    '';

    # Blacklist kernel modules that cause issues
    blacklistedKernelModules = [
      "nouveau"        # Prevent nouveau MMU faults  
      "nvidia"         # Blacklist NVIDIA drivers (hybrid graphics disabled)
      "nvidia_drm" 
      "nvidia_modeset"
      "acpi_power_meter" # Fix for ACPI SAC1 BufferField errors
    ];

    # Plymouth disabled - incompatible with systemd initrd
    plymouth.enable = false;

    initrd.systemd.enable = true;
  };

  # ===== USER CONFIGURATION =====
  users.groups.plugdev = {};
  
  users.users.notroot = {
    isNormalUser = true;
    description = "Not Root";
    shell = pkgs.zsh; # Set ZSH as default shell
    extraGroups = [
      "networkmanager"
      "wheel"
      "video" # Brightness control
      "input" # Touchpad gestures
      "power" # Power management
      "dialout" # Like desktop
      "libvirtd" # Like desktop
      "plugdev" # Like desktop
    ];
  };

  # Enable ZSH system-wide and set as default
  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  # ===== TOUCHPAD PERMANENT ENABLE =====
  # Systemd service to ensure touchpad is always enabled and cannot be disabled
  systemd.user.services.touchpad-always-enabled = {
    description = "Force touchpad to always be enabled";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.glib}/bin/gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'";
      # Run on every dconf change to re-enable if disabled
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  # Also set it at system level as default
  programs.dconf.profiles.user.databases = [{
    settings = {
      "org/gnome/desktop/peripherals/touchpad" = {
        send-events = "enabled";
      };
    };
  }];

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

  # ===== SECURITY (like desktop) =====
  security = {
    pam.services = {
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };

    auditd.enable = true;
    audit = {
      enable = true;
      backlogLimit = 8192;
      failureMode = "printk";
      rules = [ "-a exit,always -F arch=b64 -S execve" ];
    };

    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
  };

  # ===== PROGRAMS (like desktop) =====
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  # ===== SYSTEM STATE VERSION =====
  # system.stateVersion is managed by modules.core
}
