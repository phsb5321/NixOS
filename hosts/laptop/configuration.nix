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
  ];

  # Enable experimental features
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi"; # Ensure this matches the mount point configuration in hardware-configuration.nix

  # System settings
  networking.hostName = "nixos"; # Define your hostname
  time.timeZone = "America/Recife"; # Set your time zone
  i18n.defaultLocale = "en_US.UTF-8"; # Set default locale
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # Extra locale settings
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

  console.keyMap = "br-abnt2"; # Configure console keymap
  system.stateVersion = "24.05"; # Define system state version

  # Networking settings
  networking.networkmanager.enable = true; # Enable network manager

  # DNS settings (Add only if needed)
  networking.nameservers = [
    "8.8.8.8"
    "8.8.4.4"
    "1.1.1.1"
    "1.0.0.1"
    "208.67.222.222"
    "208.67.220.220"
    "9.9.9.9"
    "149.112.112.112"
    "64.6.64.6"
    "64.6.65.6"
  ];

  # X11 and Plasma 6 settings
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  services.xserver.xkb.layout = "br";
  services.xserver.xkb.variant = "";

  # Printing support
  services.printing.enable = true;

  # PipeWire configuration for sound
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire.enable = true;
  services.pipewire.alsa.enable = true;
  services.pipewire.alsa.support32Bit = true;
  services.pipewire.pulse.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # User settings
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
      kdePackages.kate # Add more packages as needed

      # Editors and IDEs
      vscode

      # Web Browsers
      floorp
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
      mangohud
      unzip

      # Music Streaming
      spotify

      # Miscellaneous Tools
      bruno
      lsof
      discord
      corectrl
      inputs.zen-browser.packages."${system}".default

      # Programming Languages
      python3
    ];
  };

  # Auto login
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "notroot";

  # Enable Firefox browser
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System-wide packages
  environment.systemPackages = with pkgs; [
    # System Utilities
    wget
    vim
    zed-editor

    # Neovim Dependencies
    stow
    gcc
    xclip

    # System Information Tools
    neofetch
    cmatrix
    htop
    lact # Added LACT for AMD GPU control

    # Development Tools
    llvm
    clang
    rocmPackages.clr # HIP runtime
    rocmPackages.rocminfo # ROCm device information tool
    rocmPackages.rocm-smi # ROCm system management interface tool
    git
    seahorse

    # Nix Tools
    alejandra # NixOS formatting tool
    nixd

    # Terminal Enhancements
    gum # For pretty TUIs in the terminal
    libvirt-glib
    coreutils
    fd

    # Speech Services
    speechd # Speech Dispatcher for Firefox

    # File and Directory Tools
    tree
    eza
    zoxide
    ripgrep

    # Terminals and Shells
    kitty
    fish
    zellij
    sshfs

    # Coopilot
    nodejs_22 # Node.js LTS for Copilot
  ];

  # Security and utility programs
  programs.mtr.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # SSH configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
    };
  };

  # Home Manager integration
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "bkp";
    users = {"notroot" = import ./home.nix;};
  };

  # Fonts
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      jetbrains-mono
      (nerdfonts.override {fonts = ["JetBrainsMono"];})
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["Noto Serif" "Liberation Serif"];
        sansSerif = ["Noto Sans" "Liberation Sans"];
        monospace = ["JetBrains Mono" "Fira Code" "Liberation Mono"];
      };
    };
  };
}
