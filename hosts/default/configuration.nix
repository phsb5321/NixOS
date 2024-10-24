{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../modules/virtualization # Import the virtualization module
  ];

  # Set system options
  networking.hostName = "nixos";
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
        # miopen          # MIOpen for machine learning
        rocsolver # ROCm linear algebra solver library
        rocalution # ROCm sparse linear algebra library
      ];
    };
  in [
    "L+    /opt/rocm   -    -    -     -    ${rocmEnv}"
  ];

  # Networking
  networking = {
    networkmanager.enable = true;
    nameservers = [
      "8.8.8.8" # Google's public DNS
      "8.8.4.4" # Google's public DNS
      "1.1.1.1" # Cloudflare's public DNS
      "1.0.0.1" # Cloudflare's public DNS
      "208.67.222.222" # OpenDNS
      "208.67.220.220" # OpenDNS
      "9.9.9.9" # Quad9 DNS
      "149.112.112.112" # Quad9 DNS
      "64.6.64.6" # Verisign Public DNS
      "64.6.65.6" # Verisign Public DNS
    ];
  };

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

  # Desktop Environment and Display Manager
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "br";
        variant = "";
      };
      # Updated GPU configuration
      videoDrivers = ["amdgpu"];
      deviceSection = ''
        Option "TearFree" "true"
        Option "DRI" "3"
      '';
      desktopManager.plasma5.enable = true;
    };

    displayManager = {
      sddm = {
        enable = true;
      };
      autoLogin = {
        enable = true;
        user = "notroot";
      };
    };
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
    ];
  };

  # Syncthing service configuration
  services.syncthing = {
    enable = true;
    user = "notroot";
    dataDir = "/home/notroot/Sync"; # Adjust this path as needed
    configDir = "/home/notroot/.config/syncthing";
    overrideDevices = true; # overrides any devices added or deleted through the WebUI
    overrideFolders = true; # overrides any folders added or deleted through the WebUI
  };

  # Updated AMD GPU configuration
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
    enableAllFirmware = true;
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

  # Ensure dconf is enabled for virt-manager
  programs.dconf.enable = true;

  # Gaming and applications
  programs = {
    fish.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    # Updated CoreCtrl configuration
    corectrl = {
      enable = true;
      gpuOverclock = {
        enable = true;
        ppfeaturemask = "0xffffffff";
      };
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "bkp";
    users = {"notroot" = import ./home.nix;};
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # System Utilities
    wget
    vim

    # Neovim Dependencies
    stow
    gcc
    xclip

    # System Information Tools
    neofetch
    cmatrix
    htop
    lact # Added LACT for AMD GPU control

    # Development Tools
    llvm
    clang
    rocmPackages.clr # HIP runtime
    rocmPackages.rocminfo # ROCm device information tool
    rocmPackages.rocm-smi # ROCm system management interface tool
    git
    seahorse

    # Nix Tools
    alejandra # NixOS formatting tool
    nixd

    # Terminal Enhancements
    gum # For pretty TUIs in the terminal
    libvirt-glib
    coreutils
    fd

    # Speech Services
    speechd # Speech Dispatcher for Firefox

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

    # Coopilot
    nodejs_22 # Node.js LTS for Copilot
  ];

  # LACT daemon service
  systemd.packages = with pkgs; [lact];
  systemd.services.lactd.wantedBy = ["multi-user.target"];

  # Security enhancements
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

  # Performance optimizations and GPU-related kernel parameters
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

  # System management improvements
  services = {
    fstrim.enable = true;
    thermald.enable = true;
  };

  # Fonts
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

  # Allow users in the "wheel" group to use CoreCtrl without password
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

  # ESP 32 Development
  services.udev.packages = [
    pkgs.platformio-core
    pkgs.openocd
  ];
}
