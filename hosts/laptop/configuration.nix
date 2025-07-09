# Laptop Configuration for NixOS
# Optimized for mobile workstation with GNOME desktop

{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Hardware configuration
    ./hardware-configuration.nix
    
    # Shared configuration modules
    ../shared/common.nix
    
    # Core system modules
    ../../modules/core
    ../../modules/desktop
    ../../modules/home
    ../../modules/networking
    ../../modules/packages
  ];

  # ============================================================================
  # LAPTOP-SPECIFIC SYSTEM CONFIGURATION
  # ============================================================================

  # Enable modular system components
  modules = {
    # Core system functionality
    core = {
      pipewire.enable = true;
      fonts.enable = true;
      flatpak.enable = true;
      documentTools.enable = true;
      # gaming.enable = false; # Disabled for laptop to save battery
      # dockerDns.enable = true; # Enable if needed for development
    };
    
    # Desktop environment
    desktop = {
      enable = true;
      environment = "gnome";
    };
    
    # Home manager configuration
    home = {
      enable = true;
      username = "notroot";
      hostName = "nixos-laptop";
    };
    
    # Package collections
    packages = {
      enable = true;
      # Add laptop-specific package preferences here
    };
  };

  # Bootloader - keep existing settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration - override hostname for laptop
  networking.hostName = lib.mkForce "nixos-laptop";
  networking.networkmanager.enable = true;

  # Time and locale - preserve Brazilian settings
  time.timeZone = "America/Recife";
  i18n.defaultLocale = "en_US.UTF-8";
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

  # Keyboard layout - preserve Brazilian layout
  services.xserver.xkb = {
    layout = "br";
    variant = "";
  };
  console.keyMap = "br-abnt2";

  # User configuration - preserve existing user setup
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Display manager - preserve auto-login setup
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";
  
  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Essential services
  services.printing.enable = true;
  services.openssh.enable = true;
  
  # Security and system programs
  security.rtkit.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Firefox - preserve existing setup
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Basic system packages - keep minimal for laptop
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
  ];

  # System version
  system.stateVersion = "25.05";
}
