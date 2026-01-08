# ~/NixOS/profiles/desktop.nix
# Desktop profile - full features, gaming, development
# Consolidated from modules/roles/desktop.nix
{
  config,
  lib,
  ...
}: {
  imports = [
    ./common.nix
  ];

  options.modules.profiles.desktop = {
    enable = lib.mkEnableOption "desktop workstation profile";
  };

  config = lib.mkIf config.modules.profiles.desktop.enable {
    # Services
    modules.services = {
      syncthing.enable = true;
      printing.enable = true;
      ssh.enable = true;
    };

    # Dotfiles
    modules.dotfiles.enable = true;

    # Hardware
    hardware = {
      enableRedistributableFirmware = true;
      bluetooth.enable = true;
      graphics = {
        enable = true;
        enable32Bit = true;
      };
    };

    # Desktop-specific groups (extends common.nix base groups)
    users.users.notroot.extraGroups = lib.mkAfter [
      "audio"
      "video"
      "disk"
      "input"
      "bluetooth"
      "docker"
      "render"
      "kvm"
      "pipewire"
    ];

    # Base programs
    programs = {
      dconf.enable = true;
      nix-ld.enable = true;
    };

    # ===== DESKTOP-SPECIFIC PACKAGE OVERRIDES =====
    # Desktop workstation gets full features: gaming, streaming, all browsers
    modules.packages = {
      # Full browser suite including Zen
      browsers.zen = true;

      # Full media capabilities
      media.streaming = true;

      # Full gaming support
      gaming = {
        enable = true;
        performance = lib.mkDefault true;
        launchers = lib.mkDefault true;
        wine = lib.mkDefault true;
        gpuControl = lib.mkDefault true;
        minecraft = lib.mkDefault false;
      };
    };
  };
}
