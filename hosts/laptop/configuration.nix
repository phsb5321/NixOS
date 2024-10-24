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
    ../modules
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
  system.stateVersion = "24.05"; # Use consistent NixOS release settings

  # Networking
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "none";
  networking.useDHCP = lib.mkDefault false;

  # Specify DNS servers
  networking.nameservers = [
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
      seahorse
      alejandra

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

      # Gaming
      lutris-unwrapped

      # Nvim Dependencies
      stow
      gcc
      xclip

      corectrl
      hwinfo
    ];
  };

  modules.virtualization = {
    enable = true;
    enableLibvirtd = true;
    enableVirtManager = true;
  };

  # Enable hardware and system services
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.printing.enable = true;

  # Remove deprecated sound option
  # sound.enable = true;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Gaming and applications
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-run"
    ];
  nixpkgs.config.allowUnfree = true;

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {"notroot" = import ./home.nix;};
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    wget
    vim
    neofetch
    cmatrix
    htop
  ];

  # SSH and security
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # nvidia configuration
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  nix.settings.trusted-substituters = ["https://ai.cachix.org"];
  nix.settings.trusted-public-keys = ["ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="];
}
