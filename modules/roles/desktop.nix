# ~/NixOS/modules/roles/desktop.nix
# Desktop role - full features, gaming, development
{ config, lib, pkgs, ... }:

{
  options.modules.roles.desktop = {
    enable = lib.mkEnableOption "desktop workstation role";
  };

  config = lib.mkIf config.modules.roles.desktop.enable {
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

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
        "networkmanager" "wheel" "audio" "video"
        "disk" "input" "bluetooth" "docker"
        "render" "kvm" "pipewire"
      ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
      dconf.enable = true;
      nix-ld.enable = true;
    };
  };
}
