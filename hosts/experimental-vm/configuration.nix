# ~/NixOS/hosts/experimental-vm/configuration.nix
{
  pkgs,
  inputs,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules
  ];

  # ------------------------------------------------------
  # Core System Configuration
  # ------------------------------------------------------
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      # Development Tools
      llvm
      clang

      # System Utilities
      bleedPkgs.zed-editor

      # Additional Tools
      seahorse
      bleachbit
      speechd
    ];
  };

  # ------------------------------------------------------
  # Desktop Environment
  # ------------------------------------------------------
  modules.desktop = {
    enable = true;
    environment = "kde";
    kde.version = "plasma6"; # Changed from hyprland to Plasma 6
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    extraPackages = with pkgs; [
      # KDE-specific packages
      libsForQt5.kio-extras
      libsForQt5.qt5.qtwayland
      qt6.qtwayland
      kdePackages.plasma-nm
      kdePackages.plasma-pa
      kdePackages.powerdevil
      kdePackages.dolphin
      kdePackages.kate
      kdePackages.konsole
      kdePackages.spectacle

      # Additional applications
      kitty
      networkmanagerapplet
    ];
    fonts = {
      enable = true;
      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
      ];
      defaultFonts = {
        monospace = [
          "JetBrainsMono Nerd Font"
          "FiraCode Nerd Font Mono"
          "Fira Code"
        ];
      };
    };
  };

  # ------------------------------------------------------
  # Networking
  # ------------------------------------------------------
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
      trustedInterfaces = ["ens18" "virbr0"];
    };
  };

  # ------------------------------------------------------
  # Home Module (per-user config)
  # ------------------------------------------------------
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = "experimental-vm";
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
      unzip

      # Miscellaneous Tools
      lsof
      discord
      inputs.zen-browser.packages.${system}.default

      # Programming Languages
      python3

      gum
      lazygit
    ];
  };

  # ------------------------------------------------------
  # Home Server Module
  # ------------------------------------------------------
  homeServer.enable = true;

  # ------------------------------------------------------
  # Environment Configuration
  # ------------------------------------------------------
  environment = {
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland";
      CLUTTER_BACKEND = "wayland";
    };
    systemPackages = with pkgs; [
      wayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-kde
    ];
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

  # ------------------------------------------------------
  # User Shell
  # ------------------------------------------------------
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # ------------------------------------------------------
  # Locale Settings
  # ------------------------------------------------------
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

  # ------------------------------------------------------
  # Users Configuration
  # ------------------------------------------------------
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

  # ------------------------------------------------------
  # Hardware Configuration
  # ------------------------------------------------------
  hardware = {
    enableRedistributableFirmware = true;
    pulseaudio.enable = false;
  };

  # ------------------------------------------------------
  # Security Configuration
  # ------------------------------------------------------
  security = {
    sudo.wheelNeedsPassword = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    polkit.enable = true;
    rtkit.enable = true; # Required for PipeWire
  };

  # ------------------------------------------------------
  # System Services
  # ------------------------------------------------------
  services = {
    fstrim.enable = true;
    thermald.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    # DBus is required for KDE
    dbus = {
      enable = true;
      packages = [pkgs.dconf];
    };
  };

  # ------------------------------------------------------
  # XDG Portal Configuration
  # ------------------------------------------------------
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-kde
      pkgs.xdg-desktop-portal-gtk
    ];
  };
}
