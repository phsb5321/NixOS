# ~/NixOS/modules/roles/laptop.nix
# Laptop role - power management, minimal features
{
  config,
  lib,
  ...
}: {
  options.modules.roles.laptop = {
    enable = lib.mkEnableOption "laptop role";

    variant = lib.mkOption {
      type = lib.types.enum ["standard" "ultrabook" "gaming" "workstation"];
      default = "standard";
      description = "Laptop variant type for optimizations";
    };
  };

  config = lib.mkIf config.modules.roles.laptop.enable {
    # Services - minimal set for laptop
    modules.services = {
      ssh.enable = true;
      printing.enable = lib.mkDefault false; # Disable on laptop by default
    };

    # Dotfiles
    modules.dotfiles.enable = true;

    # Hardware
    hardware = {
      enableRedistributableFirmware = true;
      bluetooth.enable = true;
      graphics = {
        enable = true;
        enable32Bit = false; # Save space on laptop
      };
    };

    # User configuration
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
        "render"
        "kvm"
        "pipewire"
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
