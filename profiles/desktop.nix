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
  };
}
