# ~/NixOS/hosts/experimental-vm/configuration.nix
{
  pkgs,
  lib,
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
    kde.version = "plasma6";
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
  # Hardware Configuration
  # ------------------------------------------------------
  hardware = {
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };
  };

  # ------------------------------------------------------
  # Audio Configuration
  # ------------------------------------------------------
  # Override desktop module's PulseAudio settings
  hardware.pulseaudio.enable = lib.mkForce false;
  services.pipewire.enable = lib.mkForce false;

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
      # Wayland Support
      wayland
      xdg-utils
      xdg-desktop-portal
      xdg-desktop-portal-kde

      # Media Support
      ffmpeg_6-full
      intel-media-driver
      libva
      libva-utils
      vaapiVdpau
      libvdpau-va-gl

      # Audio utilities
      pavucontrol
      pulseaudio-ctl
    ];
  };

  # ------------------------------------------------------
  # Virtualization
  # ------------------------------------------------------
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
  # User Shell and Groups
  # ------------------------------------------------------
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;
  programs.fish.enable = true;

  # ------------------------------------------------------
  # Users Configuration
  # ------------------------------------------------------
  users.groups.notroot = {};
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    group = "notroot";
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
      "users"
      "pulse"
      "pulse-access"
    ];
  };

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
    # Enable rtkit for better audio performance
    rtkit.enable = true;
  };

  # ------------------------------------------------------
  # System Services
  # ------------------------------------------------------
  services = {
    fstrim.enable = true;
    thermald.enable = true;
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
