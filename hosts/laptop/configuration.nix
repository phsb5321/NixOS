# ~/NixOS/hosts/laptop/configuration.nix
{
  config,
  pkgs,
  systemVersion,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules
    ../shared/common.nix
  ];

  # Core system configuration using modules
  modules.core = {
    enable = true;
    stateVersion = systemVersion;
    timeZone = "America/Recife";
    defaultLocale = "en_US.UTF-8";
  };

  # Networking configuration with Tailscale
  modules.networking = {
    enable = true;
    hostName = "nixos-laptop";
    enableNetworkManager = true;
    firewall = {
      enable = true;
      allowPing = lib.mkForce false; # More secure on public WiFi
      openPorts = [22]; # SSH only for laptop
    };

    # Tailscale for secure mobile connectivity
    tailscale = {
      enable = true;
      useRoutingFeatures = "client"; # Can use exit nodes and subnet routes
      extraUpFlags = [
        "--accept-routes"
        "--accept-dns"
      ];
    };
  };

  # Package configuration - disable gaming to save battery
  modules.packages = {
    enable = true;
    browsers.enable = true;
    development.enable = true;
    utilities.enable = true;
    terminal.enable = true;
    media.enable = true;
    audioVideo.enable = true;
    gaming.enable = false; # Disabled for laptop to save battery
  };

  # Enable GNOME desktop
  modules.desktop.gnome.enable = true;

  # Bootloader configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # System state version
  system.stateVersion = systemVersion;
}