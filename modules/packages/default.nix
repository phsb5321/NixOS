# ~/NixOS/modules/packages/default.nix
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.modules.packages;
in {
  options.modules.packages = {
    enable = mkEnableOption "shared packages module";

    # Browser packages
    browsers = {
      enable = mkEnableOption "browser packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          google-chrome
          brave
          librewolf
          inputs.zen-browser.packages.${pkgs.system}.default
        ];
        description = "List of browser packages to install";
      };
    };

    # Development tools
    development = {
      enable = mkEnableOption "development tools";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          vscode
          insomnia
          postman
          bruno
          android-tools
          llvm
          clang
          code-cursor
        ];
        description = "List of development packages to install";
      };
    };

    # Media and entertainment
    media = {
      enable = mkEnableOption "media packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          vlc
          spotify
          discord
          obs-studio
          gimp
        ];
        description = "List of media packages to install";
      };
    };

    # System utilities
    utilities = {
      enable = mkEnableOption "system utilities";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          gparted
          baobab
          syncthing
          pigz
          unzip
          lsof
          seahorse
          bleachbit
        ];
        description = "List of utility packages to install";
      };
    };

    # Gaming packages
    gaming = {
      enable = mkEnableOption "gaming packages";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          gamemode
          gamescope
          mangohud
          protontricks
          winetricks
          corectrl
          btop # System monitoring
          heroic # Epic Games launcher
          lutris # Gaming platform
          steam-run # Run non-Steam games with Steam runtime
          wine-staging # Latest Wine with staging patches
          dxvk # DirectX to Vulkan
        ];
        description = "List of gaming packages to install";
      };
    };

    # Audio/Video tools
    audioVideo = {
      enable = mkEnableOption "audio/video tools";
      packages = mkOption {
        type = types.listOf types.package;
        default = with pkgs; [
          pipewire
          wireplumber
          easyeffects
          pavucontrol
          helvum
          guvcview
        ];
        description = "List of audio/video packages to install";
      };
    };

    # Python with common packages
    python = {
      enable = mkEnableOption "Python with common packages";
      withGTK = mkEnableOption "Include GTK support for Python";
      package = mkOption {
        type = types.package;
        default =
          if cfg.python.withGTK
          then
            pkgs.python3.withPackages (ps:
              with ps; [
                pygobject3
                pycairo
                dbus-python
                python-dbusmock
              ])
          else pkgs.python3;
        description = "Python package with optional GTK support";
      };
    };

    # Additional packages that can be enabled per host
    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages specific to this host";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with cfg;
      (optionals browsers.enable browsers.packages)
      ++ (optionals development.enable development.packages)
      ++ (optionals media.enable media.packages)
      ++ (optionals utilities.enable utilities.packages)
      ++ (optionals gaming.enable gaming.packages)
      ++ (optionals audioVideo.enable audioVideo.packages)
      ++ (optionals python.enable [python.package])
      ++ extraPackages;
  };
}
