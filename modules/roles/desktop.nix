# ~/NixOS/modules/roles/desktop.nix
# Desktop role - full features, gaming, development
{
  config,
  lib,
  ...
}: {
  imports = [
    ../../profiles/common.nix
  ];

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
