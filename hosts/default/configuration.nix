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
  system.stateVersion = "23.11";

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
    # Remove the conflicting DNS setting
    # networkmanager.dns = "none";
    useDHCP = lib.mkDefault false;
    nameservers = [
      "1.1.1.1"
      "1.0.0.1" # Cloudflare
      "8.8.8.8"
      "8.8.4.4" # Google
    ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 ];
      allowedUDPPorts = [ ];
    };
  };

  # Use systemd-resolved for DNS resolution
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    dnssec = "allow-downgrade";
    extraConfig = ''
      DNSOverTLS=opportunistic
    '';
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
  services.xserver = {
    enable = true;
    xkb.layout = "br";
    xkb.variant = "";
    displayManager = {
      sddm.enable = true;
      autoLogin = {
        enable = true;
        user = "notroot";
      };
    };
    desktopManager.plasma5.enable = true;
  };

  # User configuration
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "networkmanager" "wheel" "audio" "video" "disk" "input" "bluetooth" "docker" ];
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
    ];
  };

  # Enable hardware and system services
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
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

  users.defaultUserShell = pkgs.fish;

  nixpkgs.config = {
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];
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
    sudo.wheelNeedsPassword = false; # Allows members of group wheel to gain root privileges without password
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
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Enable automatic security updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = "https://nixos.org/channels/nixos-23.11";
  };

  # Enable fail2ban
  services.fail2ban = {
    enable = true;
    jails = {
      ssh-iptables = ''
        enabled = true
        filter = sshd
        action = iptables[name=SSH, port=ssh, protocol=tcp]
        logpath = /var/log/auth.log
        maxretry = 5
        bantime = 3600
      '';
    };
  };

  # Performance optimizations
  boot = {
    kernelParams = [ "mitigations=off" ]; # Disable Spectre and Meltdown mitigations for better performance
    tmp.useTmpfs = true; # Mount /tmp using tmpfs for improved performance
  };

  # Enable zram for better memory management
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # System management improvements
  services = {
    fstrim.enable = true; # Enable periodic TRIM for SSDs
    thermald.enable = true; # CPU temperature management
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
    fonts = with pkgs; [
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

  # Tailscale VPN (disabled by default)
  services.tailscale.enable = false;
}
