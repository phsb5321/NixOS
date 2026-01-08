# ~/NixOS/modules/core/document-tools/default.nix
#
# Module: Document Tools (Orchestrator)
# Purpose: Main orchestrator for document preparation tools
# Part of: 001-module-optimization (T040-T044 - split from monolithic document-tools.nix)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.documentTools;
in {
  imports = [
    ./options.nix
    ./latex.nix
    ./typst.nix
    ./markdown.nix
  ];

  config = lib.mkIf cfg.enable {
    # Core PDF and document viewing tools
    environment.systemPackages = [
      pkgs.zathura # Lightweight PDF viewer
      pkgs.evince # GNOME document viewer
      pkgs.pandoc # Universal document converter
    ];
  };
}
