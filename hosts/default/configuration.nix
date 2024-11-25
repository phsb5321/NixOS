{
  config,
  pkgs,
  lib,
  inputs,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../modules/virtualization
    ../modules/desktop
    ../modules
  ];

  # Enable and configure desktop module
  modules.desktop = {
    enable = true;
    environment = "kde";
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    extraPackages = with pkgs; [
      kdePackages.plasma-nm # KDE Network Management applet
      kdePackages.plasma-pa # Audio volume applet
      networkmanagerapplet # Backup network manager applet
    ];
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
      openPorts = [22];
      trustedInterfaces = [];
    };
  };

  # Additional networking overrides if needed
  networking.networkmanager.dns = lib.mkForce "default";

  # Set system options
  time.timeZone = "America/Recife";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";
  system.stateVersion = "24.05"; # Use the same version as Home Manager
  users.defaultUserShell = pkgs.fish;

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      timeout = 14400; # for example, set to 4 hours
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

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
    packages = with pkgs; [
      # Editors and IDEs
      vscode

      # Web Browsers
      floorp
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
      inputs.zen-browser.packages."${system}".default

      # Programming Languages
      python3

      # ROCm and ML tools
      ollama-rocm
      alpaca

      # Android
      android-tools
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
    printing.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };

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

  security.rtkit.enable = true;

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

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "bkp";
    users = {"notroot" = import ./home.nix;};
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # Gaming Tools
    gamemode
    gamescope
    mangohud
    protontricks
    winetricks

    # System Utilities
    wget
    vim
    bleedPkgs.zed-editor
    inputs.firefox-nightly.packages.${system}.firefox-nightly-bin

    # Neovim Dependencies
    stow
    gcc
    xclip

    # System Information Tools
    neofetch
    cmatrix
    htop
    lact

    # Development Tools
    llvm
    clang
    rocmPackages.clr
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
    git
    gh
    seahorse
    # bleedPkgs.gitbutler
    bleachbit

    # Nix Tools
    alejandra
    nixd

    # Terminal Enhancements
    gum
    libvirt-glib
    coreutils
    fd
    speechd
    parallel

    # File and Directory Tools
    tree
    eza
    zoxide
    ripgrep

    # Terminals and Shells
    kitty
    fish
    zellij
    sshfs

    # Development
    nodejs_22
    go
  ];

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

  # Font configuration
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif" "Liberation Serif"];
        sansSerif = ["Noto Sans" "Liberation Sans"];
        monospace = ["JetBrains Mono" "Fira Code" "Liberation Mono"];
      };
    };
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
}
