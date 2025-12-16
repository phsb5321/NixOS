# ~/NixOS/modules/roles/laptop.nix
# Laptop role - power management, minimal features
<<<<<<< HEAD
{ config, lib, ... }:

{
=======
{
  config,
  lib,
  ...
}: {
>>>>>>> origin/host/server
  options.modules.roles.laptop = {
    enable = lib.mkEnableOption "laptop role";

    variant = lib.mkOption {
<<<<<<< HEAD
      type = lib.types.enum [ "standard" "ultrabook" "gaming" "workstation" ];
=======
      type = lib.types.enum ["standard" "ultrabook" "gaming" "workstation"];
>>>>>>> origin/host/server
      default = "standard";
      description = "Laptop variant type for optimizations";
    };
  };

  config = lib.mkIf config.modules.roles.laptop.enable {
    # Services - minimal set for laptop
    modules.services = {
      ssh.enable = true;
<<<<<<< HEAD
      printing.enable = lib.mkDefault false;  # Disable on laptop by default
=======
      printing.enable = lib.mkDefault false; # Disable on laptop by default
>>>>>>> origin/host/server
    };

    # Dotfiles
    modules.dotfiles.enable = true;

    # Hardware
    hardware = {
      enableRedistributableFirmware = true;
      bluetooth.enable = true;
      graphics = {
        enable = true;
<<<<<<< HEAD
        enable32Bit = false;  # Save space on laptop
=======
        enable32Bit = false; # Save space on laptop
>>>>>>> origin/host/server
      };
    };

    # User configuration
    users.users.notroot = {
      isNormalUser = true;
      description = "Pedro Balbino";
      extraGroups = [
<<<<<<< HEAD
        "networkmanager" "wheel" "audio" "video"
        "disk" "input" "bluetooth"
        "render" "kvm" "pipewire"
=======
        "networkmanager"
        "wheel"
        "audio"
        "video"
        "disk"
        "input"
        "bluetooth"
        "render"
        "kvm"
        "pipewire"
>>>>>>> origin/host/server
      ];
    };

    # Base programs
    programs = {
      zsh.enable = true;
      dconf.enable = true;
      nix-ld.enable = true;
    };

    # Optimize for battery
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 10;
      "vm.laptop_mode" = 5;
    };

    # Enable zram for memory optimization
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = 25;
    };
  };
}
