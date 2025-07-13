# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  lib,
  inputs,
  hostname,
  systemVersion,
  bleedPkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Host-specific metadata
  networking.hostName = hostname;

  # Override shared configuration as needed
  modules.networking.hostName = hostname;
  # Note: Home Manager removed - packages are now managed at system level

  # Enable auto-login for laptop convenience
  modules.desktop.autoLogin = {
    enable = lib.mkForce true;
    user = "notroot";
  };

  # GNOME autologin workaround
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Laptop-specific core module additions
  modules.core.documentTools = {
    enable = true;
    latex = {
      enable = lib.mkForce false; # Disabled for laptop to save space
    };
  };

  # Laptop-specific package preferences (disabled gaming to save battery)
  modules.packages.gaming.enable = false;

  # Laptop-specific extra packages
  modules.packages.extraPackages = with pkgs; [
    # Laptop-specific utilities
    powertop
    tlp

    # Development tools for mobile work
    git
    vim
    curl
    wget
  ];

  # Laptop-specific power management
  services.power-profiles-daemon.enable = lib.mkForce false; # Disable to use TLP instead
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Laptop-specific networking - no special ports needed
  modules.networking.firewall.openPorts = [22]; # SSH only

  # Enable explicit keyboard configuration for laptop (ABNT2)
  modules.core.keyboard.enable = true;

  # Laptop-specific keyboard configuration - use ABNT2 variant
  services.xserver.xkb = {
    layout = "br";
    variant = lib.mkForce "abnt2"; # Laptop uses Brazilian ABNT2 variant
  };
  
  # Console keymap for laptop
  console.keyMap = lib.mkForce "br-abnt2";

  # Laptop-specific bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
