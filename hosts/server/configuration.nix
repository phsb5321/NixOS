{
  config,
  pkgs,
  pkgs-unstable,
  stablePkgs,
  inputs,
  systemVersion,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/core/default.nix
    ../../modules/packages
  ];

  # Server-specific configuration
  nixpkgs.config.allowUnfree = true;

  # Bootloader - GRUB for BIOS systems
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = true;
  };

  # Networking
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    
    # DNS configuration for servers
    nameservers = [ "8.8.8.8" "8.8.4.4" "1.1.1.1" ];
    networkmanager.dns = "none";
  };

  # Disable systemd-resolved to avoid conflicts
  services.resolved.enable = false;

  # Time zone
  time.timeZone = "America/Recife";

  # Internationalization
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
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
  };

  # Console configuration
  console.keyMap = "br-abnt2";

  # User account
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Enable Docker
  virtualisation.docker.enable = true;

  # Enable package management module
  modules.packages = {
    enable = true;
    
    # Core development tools
    development.enable = true;
    utilities.enable = true;
    terminal.enable = true;
    
    # Disable desktop-oriented packages
    browsers.enable = false;
    media.enable = false;
    gaming.enable = false;
    audioVideo.enable = false;

    # Server-specific packages
    extraPackages = with pkgs; [
      # Server monitoring and management
      iotop
      nethogs
      ncdu
      lsof
      strace
    ];
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
    # Add other ports as needed
  };

  # System state version
  system.stateVersion = systemVersion;
}