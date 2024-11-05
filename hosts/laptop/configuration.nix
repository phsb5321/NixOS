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
  boot.loader.efi.efiSysMountPoint = "/boot/efi";  # Ensure this matches the mount point configuration in hardware-configuration.nix

  # System settings
  networking.hostName = "nixos"; # Define your hostname
  time.timeZone = "America/Recife"; # Set your time zone
  i18n.defaultLocale = "en_US.UTF-8"; # Set default locale

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
    vim wget neovim gh git zed-editor
  ];

  # Security and utility programs
  programs.mtr.enable = true;
  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;

  # Enable OpenSSH daemon
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Enable Home Manager
  home-manager = {
    extraSpecialArgs = {inherit inputs;};
    users = {
      notroot = import ./home.nix;
    };
  };
}
