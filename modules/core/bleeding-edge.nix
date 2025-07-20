# ~/NixOS/modules/core/bleeding-edge.nix
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  pkgs-master,
  ...
}:
with lib; let
  cfg = config.modules.core.bleedingEdge;
in {
  options.modules.core.bleedingEdge = {
    enable = mkEnableOption "bleeding edge packages globally";

    level = mkOption {
      type = types.enum ["unstable" "master"];
      default = "unstable";
      description = "Which bleeding edge level to use: unstable (tested) or master (absolute latest)";
    };

    packages = mkOption {
      type = types.listOf types.str;
      default = ["vscode" "firefox" "nodejs" "git"];
      description = "List of package names to use bleeding edge versions for";
    };
  };

  config = mkIf cfg.enable {
    # Override specific packages with bleeding edge versions
    nixpkgs.overlays = [
      (final: prev: let
        bleedPkgs =
          if cfg.level == "master"
          then pkgs-master
          else pkgs-unstable;
        makeBleedingEdge = pkgName:
          if builtins.hasAttr pkgName bleedPkgs
          then bleedPkgs.${pkgName}
          else prev.${pkgName};
      in
        builtins.listToAttrs (map (pkgName: {
            name = pkgName;
            value = makeBleedingEdge pkgName;
          })
          cfg.packages))
    ];

    # Set environment variable to indicate bleeding edge is enabled
    environment.variables.NIXOS_BLEEDING_EDGE =
      if cfg.level == "master"
      then "master"
      else "unstable";

    # Add bleeding edge information to motd
    environment.etc."motd".text = mkAfter ''

      🚀 Bleeding Edge Mode: ${cfg.level}
      📦 Bleeding Edge Packages: ${builtins.concatStringsSep ", " cfg.packages}
    '';
  };
}
