# modules/laptop/unstable-allowlist.nix
#
# Explicit allowlist of packages from nixpkgs-unstable
# Part of: Laptop Stability Guardrails (D1.1 - Stable base, unstable opt-in)
#
# This module provides a controlled way to use bleeding-edge packages
# while keeping the system base stable.
#
# Usage in configuration:
#   modules.laptop.unstablePackages.enable = true;
#   modules.laptop.unstablePackages.packages = [ "ghostty" "zed-editor" ];
#
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.modules.laptop.unstablePackages;

  # Package registry: maps package names to their unstable derivations
  # Each entry documents why it needs to be from unstable
  packageRegistry = {
    # Terminal emulator - requires latest features
    ghostty = {
      package = pkgs-unstable.ghostty;
      reason = "Latest terminal emulator with GPU acceleration";
      added = "2025-01";
    };

    # Code editor - frequent updates with new features
    zed-editor = {
      package = pkgs-unstable.zed-editor;
      reason = "Rapidly evolving editor, needs latest features";
      added = "2025-01";
    };

    # Claude Code - AI tool updates frequently
    claude-code = {
      package = pkgs-unstable.claude-code;
      reason = "AI tool with frequent capability updates";
      added = "2025-01";
    };

    # Neovim - plugin ecosystem needs recent version
    neovim = {
      package = pkgs-unstable.neovim;
      reason = "Plugin ecosystem requires recent Neovim";
      added = "2025-01";
    };
  };

  # Get packages from the allowlist
  getPackages = allowlist:
    lib.filter (p: p != null) (
      map (
        name:
          if builtins.hasAttr name packageRegistry
          then packageRegistry.${name}.package
          else
            (
              # Fallback: try to get from pkgs-unstable directly
              if builtins.hasAttr name pkgs-unstable
              then pkgs-unstable.${name}
              else null
            )
      )
      allowlist
    );
in {
  options.modules.laptop.unstablePackages = {
    enable = lib.mkEnableOption "unstable packages allowlist for laptop";

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        List of package names to install from nixpkgs-unstable.
        Only packages in the registry or available in pkgs-unstable can be listed.

        Available registered packages:
        ${lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: info: "  - ${name}: ${info.reason} (added ${info.added})"
          )
          packageRegistry
        )}
      '';
      example = ["ghostty" "zed-editor"];
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = ''
        Additional packages from unstable (direct package references).
        Use this for packages not in the registry.
      '';
      example = lib.literalExpression "[ pkgs-unstable.some-package ]";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (getPackages cfg.packages)
      ++ cfg.extraPackages;

    # Add a warning if using unregistered packages
    warnings =
      lib.optional
      (
        builtins.any
        (name: !builtins.hasAttr name packageRegistry && !builtins.hasAttr name pkgs-unstable)
        cfg.packages
      )
      ''
        Some packages in modules.laptop.unstablePackages.packages are not in the registry
        or not available in pkgs-unstable. They will be skipped.
      '';
  };
}
