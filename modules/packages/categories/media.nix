# ~/NixOS/modules/packages/categories/media.nix
# Media and entertainment packages
<<<<<<< HEAD
{ config, lib, pkgs, pkgs-unstable, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
>>>>>>> origin/host/server
  cfg = config.modules.packages.media;
in {
  options.modules.packages.media = {
    enable = lib.mkEnableOption "media packages";

    vlc = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install VLC media player";
    };

    spotify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Spotify and clients";
    };

    discord = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Discord (Vesktop)";
    };

    streaming = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install OBS Studio for streaming";
    };

    imageEditing = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install GIMP for image editing";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional media packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
<<<<<<< HEAD
      lib.optionals cfg.vlc [ vlc ]
=======
      lib.optionals cfg.vlc [vlc]
>>>>>>> origin/host/server
      ++ lib.optionals cfg.spotify [
        pkgs-unstable.spotify
        spot
        ncspot
      ]
<<<<<<< HEAD
      ++ lib.optionals cfg.discord [ vesktop ]
      ++ lib.optionals cfg.streaming [ obs-studio ]
      ++ lib.optionals cfg.imageEditing [ gimp ]
=======
      ++ lib.optionals cfg.discord [vesktop]
      ++ lib.optionals cfg.streaming [obs-studio]
      ++ lib.optionals cfg.imageEditing [gimp]
>>>>>>> origin/host/server
      ++ cfg.extraPackages;
  };
}
