{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.gaming;
in {
  options.modules.core.gaming = {
    # Enable option to turn the gaming module on or off
    enable = mkEnableOption "Gaming configuration module";

    # Option to enable Steam specifically
    enableSteam = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Steam installation and configuration";
    };

    # Option to include additional gaming-related packages
    extraGamingPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional gaming-related packages to install";
    };
  };

  config = mkIf cfg.enable {
    # Append gaming-related packages to `environment.systemPackages`
    environment.systemPackages = with pkgs;
      [
        lutris
        mangohud
        vkBasalt
        gamemode
        libstrangle
        vulkan-loader # Replaces libvulkan
        vulkan-validation-layers
        mesa-demos # Replaces mesa-utils
        corectrl # GPU overclocking and monitoring
        gwe # Alternative GPU control for NVIDIA/Intel
        protontricks
        winetricks
        wine-staging
        bottles
        heroic
        legendary-gl
        goverlay # MangoHud configurator
        dxvk
        vkd3d
        steam-run
        protonup-qt
        steamtinkerlaunch
        protonup-ng
        gamescope
      ]
      ++ cfg.extraGamingPackages;

    # Set environment variables for gaming applications
    environment.variables = {
      STEAM_RUNTIME_HEAVY = lib.mkDefault "1"; # Use full runtime for compatibility
      ENABLE_VK_LAYER_MANGOHUD = lib.mkDefault "1"; # Enable MangoHud by default
      GAMEMODE_AUTO = lib.mkDefault "1"; # Enable GameMode automatically

      # Performance optimizations
      __GL_THREADED_OPTIMIZATIONS = lib.mkDefault "1";
      __GL_SHADER_DISK_CACHE = lib.mkDefault "1";
      __GL_SHADER_DISK_CACHE_PATH = lib.mkDefault "/tmp/gl_cache";

      # Steam/Proton optimizations
      STEAM_FRAME_FORCE_CLOSE = lib.mkDefault "1";
      DXVK_HUD = lib.mkDefault "fps";
      DXVK_ASYNC = lib.mkDefault "1";

      # Wine optimizations
      WINEPREFIX = lib.mkDefault "$HOME/.wine";
      WINEARCH = "win64";
      WINE_CPU_TOPOLOGY = "4:2";
    };

    # Start GameMode as a systemd service
    systemd.services.gamemoded = {
      enable = true;
      description = "GameMode Daemon";
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.gamemode}/bin/gamemoded";
        Restart = "always";
        RestartSec = "10";
      };
    };

    # Enable Steam with better integration
    programs.steam = mkIf cfg.enableSteam {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      package = pkgs.steam.override {
        extraPkgs = pkgs:
          with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
            mangohud
            gamemode
          ];
      };
    };

    # Gaming-specific kernel parameters and optimizations
    boot.kernel.sysctl = {
      "kernel.yama.ptrace_scope" = 0; # Allow ptrace for game debugging
      "vm.max_map_count" = 262144; # Required for some games
      "fs.file-max" = 2097152; # Increase file descriptor limit
      "kernel.pid_max" = 4194304; # Increase process limit
    };

    # Gaming-optimized user limits
    security.pam.loginLimits = [
      {
        domain = "@wheel";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "@wheel";
        type = "hard";
        item = "nofile";
        value = "1048576";
      }
    ];

    # Enable udev rules for gaming devices
    services.udev.packages = with pkgs; [
      game-devices-udev-rules
    ];

    # Hardware optimizations for gaming
    hardware.enableRedistributableFirmware = true;
    hardware.graphics.enable32Bit = true;
  };
}
