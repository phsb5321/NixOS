{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Bootloader configuration for EFI
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";


  # Set system options
  networking.hostName = "nixos"; # Define your hostname
  time.timeZone = "America/Recife";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";
  nix.settings.experimental-features = "nix-command flakes";
  system.stateVersion = "23.11"; # Use consistent NixOS release settings

  # Networking
  networking.networkmanager.enable = true;
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Locale settings for different aspects
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
  services.xserver.enable = true;
  services.xserver.xkb.layout = "br";
  services.xserver.xkb.variant = "";
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

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
      gnome.seahorse
      nixpkgs-fmt

      # API Testing
      insomnia

      # File Management
      gparted
      baobab
      syncthing

      # System Utilities
      pigz
      mangohud

      # Note-taking and Knowledge Management
      obsidian

      # Music Streaming
      spotify

      # Programming Languages
      # Go
      go

      # Python
      python3
      poetry

      # Game Development
      godot_4

      # Nvim Dependencies
      stow
      gcc
      xclip

      # Learning
      anki

    ];
  };

  # # Ollama
  # services.ollama = {
  #   #package = pkgs.unstable.ollama; # Uncomment if you want to use the unstable channel, see https://fictionbecomesfact.com/nixos-unstable-channel
  #   enable = true;
  #   acceleration = "cuda"; # Or "rocm"
  #   #environmentVariables = { # I haven't been able to get this to work myself yet, but I'm sharing it for the sake of completeness
  #   # HOME = "/home/ollama";
  #   # OLLAMA_MODELS = "/home/ollama/models";
  #   # OLLAMA_HOST = "0.0.0.0:11434"; # Make Ollama accesible outside of localhost
  #   # OLLAMA_ORIGINS = "http://localhost:8080,http://192.168.0.10:*"; # Allow access, otherwise Ollama returns 403 forbidden due to CORS
  #   #};
  # };


  # Enable hardware and system services
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.printing.enable = true;
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Gaming and applications
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "steam" "steam-original" "steam-run" ];
  nixpkgs.config.allowUnfree = true;

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = { "notroot" = import ./home.nix; };
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [ wget vim neofetch ];

  # SSH and security
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";
}
