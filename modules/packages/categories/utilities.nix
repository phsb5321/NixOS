# ~/NixOS/modules/packages/categories/utilities.nix
# System utilities and tools
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.packages.utilities;
in {
  options.modules.packages.utilities = {
    enable = lib.mkEnableOption "system utilities";

    diskManagement = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install disk management tools (GParted, Baobab)";
    };

    fileSync = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install file synchronization tools (Syncthing)";
    };

    compression = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install compression tools (pigz, unzip)";
    };

    security = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install security tools (Seahorse, BleachBit)";
    };

    pdfViewer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install PDF viewer (Okular)";
    };

    messaging = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install messaging apps (Ferdium)";
    };

    fonts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install essential fonts";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional utility packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Disk management
      (lib.optionals cfg.diskManagement [
        gparted
        baobab
        lsof
      ])

      # File sync
      ++ (lib.optionals cfg.fileSync [
        syncthing
      ])

      # Compression
      ++ (lib.optionals cfg.compression [
        pigz
        unzip
      ])

      # Security
      ++ (lib.optionals cfg.security [
        seahorse
        bleachbit
      ])

      # PDF viewer
      ++ (lib.optionals cfg.pdfViewer [
        kdePackages.okular
      ])

      # Messaging
      ++ (lib.optionals cfg.messaging [
        ferdium
      ])

      # Fonts
      ++ (lib.optionals cfg.fonts [
        cantarell-fonts
        liberation_ttf
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
      ])

      # Extra packages
      ++ cfg.extraPackages;
  };
}
