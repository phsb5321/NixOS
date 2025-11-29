# ~/NixOS/modules/core/document-tools/latex.nix
#
# Module: LaTeX Support
# Purpose: LaTeX distribution, editors, bibliography tools, and dependencies
# Part of: 001-module-optimization (T040-T044 - document-tools.nix split)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.documentTools;
in {
  config = lib.mkIf (cfg.enable && cfg.latex.enable) {
    environment.systemPackages =
      if cfg.latex.minimal
      then
        # Minimal LaTeX installation
        [
          pkgs.texlive.combined.scheme-minimal
          # Essential Perl modules for LaTeX
          pkgs.perlPackages.YAMLTiny
          pkgs.perlPackages.FileHomeDir
        ]
      else
        # Full LaTeX installation with essential packages
        [
          # Complete TeXLive installation
          pkgs.texlive.combined.scheme-full

          # Essential Perl modules for LaTeX (including YAML::Tiny)
          pkgs.perlPackages.YAMLTiny
          pkgs.perlPackages.FileHomeDir
          pkgs.perlPackages.UnicodeLineBreak
          pkgs.perlPackages.LogLog4perl
          pkgs.perlPackages.ListAllUtils
          pkgs.perlPackages.BusinessISBN
          pkgs.perlPackages.BusinessISMN
          pkgs.perlPackages.BusinessISSN
          pkgs.perlPackages.ListMoreUtils
          pkgs.perlPackages.RegexpCommon
          pkgs.perlPackages.TextBibTeX
          pkgs.perlPackages.URI
          pkgs.perlPackages.XMLParser

          # LaTeX build tools and processors
          pkgs.biber # Modern bibliography processor
          pkgs.texlab # LaTeX language server
          # pkgs.tectonic # Modern LaTeX engine
          # TODO: Re-enable when Rust compilation issues are resolved in nixpkgs

          # LaTeX editors and IDEs
          pkgs.texstudio # Comprehensive LaTeX IDE
          # pkgs.texmaker # Cross-platform LaTeX editor - TEMPORARILY DISABLED (broken in nixpkgs)
          pkgs.kile # KDE LaTeX editor
          pkgs.lyx # WYSIWYM document processor

          # Graphics and drawing tools
          pkgs.inkscape # Vector graphics editor
          pkgs.asymptote # 3D graphics programming language
          pkgs.graphviz # Graph visualization software

          # Additional utilities
          pkgs.ghostscript # PostScript and PDF interpreter
          pkgs.imagemagick # Image manipulation suite
          pkgs.poppler-utils # PDF utilities (pdfinfo, pdftotext, etc.)
          pkgs.qpdf # PDF transformation library
          pkgs.python3Packages.pygments # Syntax highlighting

          # Bibliography and reference management
          # pkgs.jabref # Bibliography reference manager (temporarily disabled - OpenJDK 21.0.9 build issue)

          # Math and science tools
          pkgs.gnuplot # Plotting utility

          # Spell checking
          pkgs.aspell # Spell checker
          pkgs.aspellDicts.en # English dictionary
          pkgs.hunspell # Spell checker
          pkgs.hunspellDicts.en_US # US English dictionary
        ]
        ++ cfg.latex.extraPackages;
  };
}
