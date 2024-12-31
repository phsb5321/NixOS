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
    ../../modules/desktop
    ../../modules/virtualization
    ../../modules/networking
    ../../modules/home
    ../../modules/core
  ];

  # Enable core module with basic system configuration
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
    extraSystemPackages = with pkgs; [
      vim
      wget
    ];
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
      nerd-fonts.jetbrains-mono
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
      remmina
      obsidian
      inputs.nixvim
      zoxide
    ];
  };

  # Enable and configure networking module
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
      trustedInterfaces = [];
    };
  };

  # Virtualization module configuration
  modules.virtualization = {
    enable = true;
    enableLibvirtd = true;
    enableVirtManager = true;
    username = "notroot";
  };

  # System configuration
  console.keyMap = "br-abnt2";
  users.defaultUserShell = pkgs.fish;

  # Locale settings
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

  # Define user account
  users.users.notroot = {
    isNormalUser = true;
    description = "Pedro Balbino";
    extraGroups = ["wheel" "networkmanager"];
  };

  # Enable SSH
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
      # download-buffer-size = 100 * 1024 * 1024; # Set to 100 MiB
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # GPG and SSH agent
  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  # Environment configuration
  environment = {
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };
}
