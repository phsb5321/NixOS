# ~/NixOS/modules/packages/categories/gaming.nix
# Gaming packages and tools
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.packages.gaming;
in {
  options.modules.packages.gaming = {
    enable = lib.mkEnableOption "gaming packages";

    performance = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install performance tools (GameMode, GameScope, MangoHud, Goverlay)";
    };

    launchers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install game launchers (Heroic, Lutris)";
    };

    wine = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Wine, Proton tools, and compatibility layers";
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
    # Performance tools (btop already in dev utilities)
      (lib.optionals cfg.performance [
        gamemode
        gamescope
        mangohud
        goverlay
      ])
      # Game launchers
      ++ (lib.optionals cfg.launchers [
        heroic
        lutris
      ])
      # Wine, Proton, and compatibility
      ++ (lib.optionals cfg.wine [
        protontricks
        winetricks
        steam-run
        wine-staging
        dxvk
        protonup-qt
      ])
      # GPU control
      ++ (lib.optionals cfg.gpuControl [
        corectrl
      ])
      # Minecraft
      ++ (lib.optionals cfg.minecraft [
        prismlauncher
      ])
      # Extra packages
      ++ cfg.extraPackages;
  };
}
