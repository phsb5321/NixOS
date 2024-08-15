{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Set system options
  networking.hostName = "nixos";
  time.timeZone = "America/Recife";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";
  system.stateVersion = "23.11"; # Use the same version as Home Manager
  users.defaultUserShell = pkgs.fish;

  # Nix settings
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
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
      desktopManager.plasma5.enable = true;
      # Add AMDGPU driver
      videoDrivers = [ "amdgpu" ];
      # Add TearFree option
      deviceSection = ''
        Option "TearFree" "true"
      '';
    };

    displayManager = {
      sddm.enable = true;
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
    ];
    packages = with pkgs; [
      # Terminals and Shells
      kitty
      fish
      zellij
      sshfs

      # Terminal Tools
      tree
      eza
      zoxide
      ripgrep

      # Editors and IDEs
      vscode
      neovim

      # Web Browsers
      floorp
      google-chrome

      # Development Tools
      git
      seahorse
      nixpkgs-fmt

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

      # Note-taking and Knowledge Management
      obsidian

      # Music Streaming
      spotify

      # Nvim Dependencies
      stow
      gcc
      xclip

      # Virtualisation
      virt-manager

      bruno
      lsof
      discord
      corectrl
    ];
  };

  # AMD GPU configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };

  # Enable redistributable firmware
  hardware.enableRedistributableFirmware = true;

  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    rocmOverrideGfx = "10.1.0";
  };

  # Enable hardware and system services
  hardware = {
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
    libvirtd.enable = true;
  };

  # Gaming and applications
  programs = {
    fish.enable = true;
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
  };

  nixpkgs.config = {
    # Allow all unfree packages
    allowUnfree = true;
  };

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "bkp";
    users = { "notroot" = import ./home.nix; };
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    wget
    vim
    neofetch
    cmatrix
    htop
  ];

  # Security enhancements
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
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

  # Performance optimizations
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "mitigations=off"
      "amdgpu.ppfeaturemask=0xffffffff"
    ];
    tmp.useTmpfs = true;
  };

  # System management improvements
  services = {
    fstrim.enable = true;
    thermald.enable = true;
    syncthing = {
      enable = true;
      user = "notroot";
      dataDir = "/home/notroot/.config/syncthing";
      configDir = "/home/notroot/.config/syncthing";
    };
  };

  # Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    ];
    fontconfig = {
      defaultFonts = {
        serif = [ "Noto Serif" "Liberation Serif" ];
        sansSerif = [ "Noto Sans" "Liberation Sans" ];
        monospace = [ "Fira Code" "Liberation Mono" ];
      };
    };
  };
}
