{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    ../modules/desktop
    ../modules/virtualization
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
    environment = "hyprland";
    extraPackages = with pkgs; [
      firefox
      kitty
      neofetch
      font-awesome
    ];
    autoLogin = {
      enable = true;
      user = "notroot";
    };
  };

  # Virtualization module
  modules.virtualization = {
    enable = true;
    enableLibvirtd = true;
    enableVirtManager = true;
    username = "notroot";
  };

  console.keyMap = "br-abnt2";

  # Define user account
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [
      git
      gh
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  # Enable some programs
  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    fish.enable = true;
  };

  # Set default shell to fish
  users.defaultUserShell = pkgs.fish;

  # Enable OpenSSH daemon
  services.openssh.enable = true;

  # Home Manager configuration
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.notroot = import ./home.nix;
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      download-buffer-size = 100 * 1024 * 1024; # Set to 100 MiB
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # System-wide environment variables
  environment.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  system.stateVersion = "24.05";
}
