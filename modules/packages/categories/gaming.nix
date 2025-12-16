# ~/NixOS/modules/packages/categories/gaming.nix
# Gaming packages and tools
<<<<<<< HEAD
{ config, lib, pkgs, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  ...
}: let
>>>>>>> origin/host/server
  cfg = config.modules.packages.gaming;
in {
  options.modules.packages.gaming = {
    enable = lib.mkEnableOption "gaming packages";

    performance = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install performance tools (GameMode, GameScope, MangoHud)";
    };

    launchers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install game launchers (Heroic, Lutris)";
    };

    wine = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Wine and related tools";
    };

    gpuControl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install GPU control tools (CoreCtrl for AMD)";
    };

    minecraft = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install Minecraft launcher (Prism Launcher)";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional gaming packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
<<<<<<< HEAD
      # Performance tools
=======
    # Performance tools
>>>>>>> origin/host/server
      (lib.optionals cfg.performance [
        gamemode
        gamescope
        mangohud
        btop
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Game launchers
      ++ (lib.optionals cfg.launchers [
        heroic
        lutris
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Wine and compatibility
      ++ (lib.optionals cfg.wine [
        protontricks
        winetricks
        steam-run
        wine-staging
        dxvk
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # GPU control
      ++ (lib.optionals cfg.gpuControl [
        corectrl
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Minecraft
      ++ (lib.optionals cfg.minecraft [
        prismlauncher
      ])
<<<<<<< HEAD

=======
>>>>>>> origin/host/server
      # Extra packages
      ++ cfg.extraPackages;
  };
}
