# ~/NixOS/modules/packages/categories/audio-video.nix
# Audio and video tools
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.packages.audioVideo;
in {
  options.modules.packages.audioVideo = {
    enable = lib.mkEnableOption "audio/video tools";

    pipewire = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install PipeWire and WirePlumber";
    };

    audioEffects = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install EasyEffects for audio processing";
    };

    audioControl = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install audio control tools (PulseAudio Volume Control, Helvum)";
    };

    webcam = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install webcam viewer (guvcview)";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional audio/video packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      lib.optionals cfg.pipewire [
        pipewire
        wireplumber
      ]
      ++ lib.optionals cfg.audioEffects [ easyeffects ]
      ++ lib.optionals cfg.audioControl [
        pavucontrol
        helvum
      ]
      ++ lib.optionals cfg.webcam [ guvcview ]
      ++ cfg.extraPackages;
  };
}
