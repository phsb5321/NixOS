# ~/NixOS/profiles/server.nix
# Server profile - headless, services-focused
# Consolidated from modules/roles/server.nix
{
  config,
  lib,
  ...
}: {
  imports = [
    ./common.nix
  ];

  options.modules.profiles.server = {
    enable = lib.mkEnableOption "server profile";
  };

  config = lib.mkIf config.modules.profiles.server.enable {
    # Server services
    modules.services = {
      ssh.enable = true;
    };

    # Hardware - minimal base (mkDefault allows host overrides)
    # Note: bluetooth and graphics settings are left to host configs
    # since servers vary (some headless, some with GNOME like Proxmox VMs)
    hardware.enableRedistributableFirmware = true;

    # Server uses only base groups from common.nix (networkmanager, wheel)
    # No additional groups needed for headless server
  };
}
