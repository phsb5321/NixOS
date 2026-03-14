# ~/NixOS/modules/packages/categories/audio-video.nix
# Audio and video tools
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.packages.audioVideo;
in {
  options.modules.packages.audioVideo = {
    enable = lib.mkEnableOption "audio/video tools";

    audioControl = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install audio patchbay (crosspipe)";
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
    # pipewire, wireplumber, easyeffects, pavucontrol already provided by modules.core.pipewire
      lib.optionals cfg.audioControl [
        crosspipe # Patchbay for PipeWire (not in pipewire.nix)
      ]
      ++ lib.optionals cfg.webcam [guvcview]
      ++ cfg.extraPackages;
  };
}
