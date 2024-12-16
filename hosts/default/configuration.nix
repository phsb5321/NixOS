# ~/NixOS/hosts/default/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  bleedPkgs,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../modules/virtualization
    ../modules/desktop
    ../modules
  ];

  # Enable core module with basic system configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      # Gaming Tools
      gamemode
      gamescope
      mangohud
      protontricks
      winetricks

      # System Utilities
      bleedPkgs.zed-editor
      guvcview
      obs-studio

      # Development Tools
      llvm
      clang
      rocmPackages.clr
      rocmPackages.rocminfo
      rocmPackages.rocm-smi

      # Additional Tools
      seahorse
      bleachbit
      lact
      speechd
    ];
  };

  # Set system options
  console.keyMap = "br-abnt2";
  users.defaultUserShell = pkgs.fish;

  # Enable and configure desktop module
  modules.desktop = {
    enable = true;
    environment = "kde";
    kde.version = "plasma5"; # Use Plasma 5
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    extraPackages = with pkgs; [
      plasma5Packages.plasma-nm # KDE Network Management applet
      plasma5Packages.plasma-pa # Audio volume applet
      networkmanagerapplet # Backup network manager applet
    ];
    fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
      defaultFonts = {
        monospace = ["JetBrainsMono Nerd Font" "FiraCode Nerd Font Mono" "Fira Code"];
      };
    };
  };

  # Enable and configure networking module
  modules.networking = {
    enable = true;
    hostName = "nixos";
    optimizeTCP = true;
    enableNetworkManager = true;
    dns = {
      enableSystemdResolved = true;
      enableDNSOverTLS = true;
      primaryProvider = "cloudflare";
    };
    firewall = {
      enable = true;
      allowPing = true;
      openPorts = [22 3000];
      trustedInterfaces = [];
    };
  };

  # Enable the home module
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = "default";
    extraPackages = with pkgs; [
      # Editors and IDEs
      vscode

      # Web Browsers
      google-chrome

      # API Testing
      insomnia
      postman

      # File Management
      gparted
      baobab
      syncthing
      vlc

      # System Utilities
      pigz
      mangohud
      unzip

      # Music Streaming
      spotify

      # Miscellaneous Tools
      bruno
      lsof
      discord
      corectrl
      inputs.zen-browser.packages.${system}.default

      # Programming Languages
      python3

      # ROCm and ML tools
      ollama-rocm
      alpaca

      # Android
      android-tools
    ];
  };

  # Additional networking overrides if needed
  networking.networkmanager.dns = lib.mkForce "default";

  systemd.tmpfiles.rules = let
    rocmEnv = pkgs.symlinkJoin {
      name = "rocm-combined";
      paths = with pkgs.rocmPackages; [
        rocblas # Required for miopen
        clr # HIP runtime
        rocminfo # ROCm device info tool
        rocsolver # ROCm linear algebra solver library
        rocalution # ROCm sparse linear algebra library
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  ];

  # Locale settings
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # User configuration
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "disk"
      "input"
      "bluetooth"
      "docker"
      "dialout"
      "libvirtd"
      "kvm"
    ];
  };

  # Hardware configuration
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    pulseaudio.enable = false;
    cpu.amd.updateMicrocode = true;
  };

  services = {
    # Syncthing service configuration
    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/Sync";
      configDir = "/home/notroot/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
    };

    # Ollama service configuration
    ollama = {
      enable = true;
      acceleration = "rocm";
    };
  };

  # Virtualization
  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };

  modules.virtualization = {
    enable = true;
    enableLibvirtd = true;
    enableVirtManager = true;
    username = "notroot";
  };

  # Gaming configuration
  programs = {
    fish.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };
    dconf.enable = true;
    thunderbird.enable = true;
  };

  # LACT daemon service
  systemd.packages = with pkgs; [lact];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # Security configuration
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    polkit.enable = true;
  };

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # Boot configuration
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "mitigations=off"
      "amdgpu.ppfeaturemask=0xffffffff"
      "radeon.si_support=0"
      "amdgpu.si_support=1"
      "radeon.cik_support=0"
      "amdgpu.cik_support=1"
    ];
    tmp.useTmpfs = true;
  };

  # System services
  services = {
    fstrim.enable = true;
    thermald.enable = true;
  };

  # CoreCtrl sudo configuration
  security.sudo.extraRules = [
    {
      groups = ["wheel"];
      commands = [
        {
          command = "${pkgs.corectrl}/bin/corectrl";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # ESP32 Development
  services.udev.packages = [
    pkgs.platformio-core
    pkgs.openocd
  ];

  # Increase Nix download buffer size
  nix.settings = {
    "download-buffer-size" = 209715200; # 200 MiB in bytes
  };
}
