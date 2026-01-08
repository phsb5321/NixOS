# ~/NixOS/modules/core/document-tools/markdown.nix
#
# Module: Markdown Support
# Purpose: Markdown LSP, linters, formatters, preview tools, and utilities
# Part of: 001-module-optimization (T040-T044 - document-tools.nix split)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.documentTools;
in {
  config = lib.mkIf (cfg.enable && cfg.markdown.enable) {
    environment.systemPackages =
      lib.optionals cfg.markdown.lsp [
        pkgs.marksman # Markdown language server
      ]
      # Linting tools
      ++ lib.optionals cfg.markdown.linting.enable (
        lib.optionals cfg.markdown.linting.markdownlint [
          pkgs.markdownlint-cli2 # Modern Markdown linter
        ]
        ++ lib.optionals cfg.markdown.linting.vale.enable (
          [
            pkgs.vale # Prose linter
          ]
          # Vale style guides
          ++ (map (style: pkgs.valeStyles.${style}) cfg.markdown.linting.vale.styles)
        )
        ++ lib.optionals cfg.markdown.linting.linkCheck [
          pkgs.markdown-link-check # Check for broken links
        ]
      )
      # Formatting tools
      ++ lib.optionals cfg.markdown.formatting.enable (
        lib.optionals cfg.markdown.formatting.mdformat [
          pkgs.mdformat # CommonMark formatter
        ]
        ++ lib.optionals cfg.markdown.formatting.prettier [
          pkgs.nodePackages.prettier # Alternative formatter
        ]
      )
      # Preview tools
      ++ lib.optionals cfg.markdown.preview.enable (
        lib.optionals cfg.markdown.preview.glow [
          pkgs.glow # Terminal markdown renderer
        ]
        ++ lib.optionals cfg.markdown.preview.grip [
          pkgs.go-grip # GitHub-flavored markdown preview
        ]
      )
      # Utilities
      ++ lib.optionals cfg.markdown.utilities.enable (
        lib.optionals cfg.markdown.utilities.doctoc [
          pkgs.doctoc # Table of contents generator
        ]
        ++ lib.optionals cfg.markdown.utilities.mdbook [
          pkgs.mdbook # Create books from Markdown
        ]
        ++ lib.optionals cfg.markdown.utilities.mermaid [
          pkgs.mermaid-cli # Diagram generation
        ]
      )
      ++ cfg.markdown.extraPackages;
  };
}
