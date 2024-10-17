{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    ../modules/desktop
  ];

  # Bootloader configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
    useOSProber = true;
  };

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

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

  # Desktop environment configuration
  modules.desktop = {
    enable = true;
    environment = "hyprland"; # Choose "hyprland" to enable Hyprland
    extraPackages = with pkgs; [ firefox ];
    autoLogin = {
      enable = true;
      user = "notroot";
    };
  };

  console.keyMap = "br-abnt2";

  # Enable CUPS to print documents
  services.printing.enable = true;

  # Enable sound with pipewire
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define user account
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "wheel" "networkmanager" "video" "input" "seatd" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    gh
  ];

  # Enable some programs
  programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Disable Steam
  programs.steam.enable = false;

  # Enable OpenSSH daemon
  services.openssh.enable = true;

  # Home Manager configuration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.notroot = import ./home.nix;
  };

  system.stateVersion = "24.05";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Disable AMD-specific configurations
  hardware.opengl.extraPackages = lib.mkForce [ ];
  hardware.opengl.driSupport32Bit = false;
}
