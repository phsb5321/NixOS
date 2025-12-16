# ~/NixOS/modules/packages/categories/audio-video.nix
# Audio and video tools
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
<<<<<<< HEAD
      ++ lib.optionals cfg.audioEffects [ easyeffects ]
=======
      ++ lib.optionals cfg.audioEffects [easyeffects]
>>>>>>> origin/host/server
      ++ lib.optionals cfg.audioControl [
        pavucontrol
        helvum
      ]
<<<<<<< HEAD
      ++ lib.optionals cfg.webcam [ guvcview ]
=======
      ++ lib.optionals cfg.webcam [guvcview]
>>>>>>> origin/host/server
      ++ cfg.extraPackages;
  };
}
