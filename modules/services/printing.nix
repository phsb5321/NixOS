# ~/NixOS/modules/services/printing.nix
# Printing service (CUPS) configuration
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.services.printing;
in {
  options.modules.services.printing = {
    enable = mkEnableOption "printing service (CUPS)";

    drivers = mkOption {
      type = types.listOf types.package;
      default = with pkgs; [
        gutenprint
        hplip
        epson-escpr
      ];
      description = "List of printer drivers to install";
    };

    avahi = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Avahi for printer discovery";
      };

      nssmdns4 = mkOption {
        type = types.bool;
        default = true;
        description = "Enable multicast DNS in NSS";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall for Avahi";
      };
    };
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      drivers = cfg.drivers;
    };

    services.avahi = mkIf cfg.avahi.enable {
      enable = true;
      nssmdns4 = cfg.avahi.nssmdns4;
      openFirewall = cfg.avahi.openFirewall;
    };
  };
}
