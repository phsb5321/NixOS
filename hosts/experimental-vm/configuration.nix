# ~/NixOS/hosts/experimental-vm/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    # Hardware config for this VM
    ./hardware-configuration.nix

    # Home Manager integration
    inputs.home-manager.nixosModules.default

    # Main modules directory (includes home-server/default.nix)
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
    environment = "hyprland";
    autoLogin = {
      enable = true;
      user = "notroot";
    };
    extraPackages = with pkgs; [
      firefox
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
  # Toggle this to "true" to enable services like
  # LanguageTool, Home Page, qBittorrent, Plex, etc.
  homeServer.enable = true;

  disabledModules = ["services/misc/plex.nix"];

  # Example overrides if needed:
  # services.languagetool.server.port = 8082;
  # services.nginx.virtualHosts."my-homepage".listen = [ { addr = "0.0.0.0"; port = 8080; } ];

  # ------------------------------------------------------
  # User Shell
  # ------------------------------------------------------
  users.defaultUserShell = pkgs.fish;

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
  };

  # ------------------------------------------------------
  # System Services
  # ------------------------------------------------------
  services = {
    fstrim.enable = true;
    thermald.enable = true;
  };
}
