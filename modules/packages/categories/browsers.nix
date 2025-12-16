# ~/NixOS/modules/packages/categories/browsers.nix
# Browser packages module
<<<<<<< HEAD
{ config, lib, pkgs, inputs, ... }:

let
=======
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
>>>>>>> origin/host/server
  cfg = config.modules.packages.browsers;
in {
  options.modules.packages.browsers = {
    enable = lib.mkEnableOption "browser packages";

    chrome = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Google Chrome";
    };

    brave = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Brave browser";
    };

    librewolf = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install LibreWolf (privacy-focused Firefox)";
    };

    zen = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Zen browser";
    };

<<<<<<< HEAD
    firefoxNightly = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Firefox Nightly";
    };

=======
>>>>>>> origin/host/server
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional browser packages";
    };
  };

  config = lib.mkIf cfg.enable {
<<<<<<< HEAD
    environment.systemPackages = with pkgs; lib.optionals cfg.chrome [ google-chrome ]
      ++ lib.optionals cfg.brave [ brave ]
      ++ lib.optionals cfg.librewolf [ librewolf ]
      ++ lib.optionals cfg.zen [ inputs.zen-browser.packages.${pkgs.system}.default ]
      ++ lib.optionals cfg.firefoxNightly [ inputs.firefox-nightly.packages.${pkgs.system}.firefox-nightly-bin ]
=======
    environment.systemPackages = with pkgs;
      lib.optionals cfg.chrome [google-chrome]
      ++ lib.optionals cfg.brave [brave]
      ++ lib.optionals cfg.librewolf [librewolf]
      ++ lib.optionals cfg.zen [inputs.zen-browser.packages.${pkgs.system}.default]
>>>>>>> origin/host/server
      ++ cfg.extraPackages;
  };
}
