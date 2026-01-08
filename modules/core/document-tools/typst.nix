# ~/NixOS/modules/core/document-tools/typst.nix
#
# Module: Typst Support
# Purpose: Typst compiler and language server
# Part of: 001-module-optimization (T040-T044 - document-tools.nix split)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.documentTools;
in {
  config = lib.mkIf (cfg.enable && cfg.typst.enable) {
    environment.systemPackages =
      [
        pkgs.typst # Typst compiler and CLI
      ]
      ++ lib.optionals cfg.typst.lsp [
        pkgs.tinymist # Typst language server
      ]
      ++ cfg.typst.extraPackages;
  };
}
