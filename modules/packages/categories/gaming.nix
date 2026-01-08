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

    # New gaming tools section
    performanceTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install performance monitoring tools (MangoHud, Goverlay)";
    };

    protonTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Proton management tools (protontricks, protonup-qt)";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional gaming packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
    # Performance tools
      (lib.optionals cfg.performance [
        gamemode
        gamescope
        mangohud
        btop
      ])
      # Game launchers
      ++ (lib.optionals cfg.launchers [
        heroic
        lutris
      ])
      # Wine and compatibility
      ++ (lib.optionals cfg.wine [
        protontricks
        winetricks
        steam-run
        wine-staging
        dxvk
      ])
      # GPU control
      ++ (lib.optionals cfg.gpuControl [
        corectrl
      ])
      # Minecraft
      ++ (lib.optionals cfg.minecraft [
        prismlauncher
      ])
      # New gaming tools section
      ++ (lib.optionals cfg.performanceTools [
        mangohud # FPS/GPU overlay
        goverlay # MangoHud GUI configurator
        gamemode # Process optimizer
      ])
      ++ (lib.optionals cfg.protonTools [
        protontricks # Prefix manager
        protonup-qt # GE-Proton installer
        winetricks # Wine configuration
      ])
      # Extra packages
      ++ cfg.extraPackages;
  };
}
