# ~/NixOS/modules/packages/categories/browsers.nix
# Browser packages module
{ config, lib, pkgs, inputs, ... }:

let
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

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional browser packages";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; lib.optionals cfg.chrome [ google-chrome ]
      ++ lib.optionals cfg.brave [ brave ]
      ++ lib.optionals cfg.librewolf [ librewolf ]
      ++ lib.optionals cfg.zen [ inputs.zen-browser.packages.${pkgs.system}.default ]
      ++ cfg.extraPackages;
  };
}
