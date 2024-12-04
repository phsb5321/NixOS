{
  config,
  pkgs,
  lib,
  inputs,
  systemVersion,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
    ../modules/desktop
    ../modules/virtualization
  ];

  # 👇🏻 System Version for NixOS
  system.stateVersion = systemVersion;

  # Bootloader configuration for UEFI
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
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

  # Home module configuration
  modules.home = {
    enable = true;
    username = "notroot";
    hostName = "experimental-vm";
    extraPackages = with pkgs; [
      git
      gh
      zed-editor
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
      noto-fonts-emoji
      noto-fonts
      noto-fonts-cjk-sans
      fish
      kitty
      grc
      eza
      ffmpeg
      gh
      brave
      yazi-unwrapped
      texlive.combined.scheme-full
      dbeaver-bin
      amberol
      awscli2
      remmina
      obsidian
      inputs.nixvim
      zoxide
    ];
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
    extraGroups = ["wheel" "networkmanager"];
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
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
  };

  # Nix settings
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
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

  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22];
  };
}
