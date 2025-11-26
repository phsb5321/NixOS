# modules/core/document-tools.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.documentTools;
in {
  options.modules.core.documentTools = {
    enable = mkEnableOption "Document preparation tools";

    latex = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable LaTeX support";
      };

      minimal = mkOption {
        type = types.bool;
        default = false;
        description = "Install only minimal LaTeX packages";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Additional LaTeX-related packages to install";
      };
    };

    typst = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Typst support";
      };

      lsp = mkOption {
        type = types.bool;
        default = true;
        description = "Install Typst LSP (tinymist)";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Additional Typst-related packages to install";
      };
    };

    markdown = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Markdown support";
      };

      lsp = mkOption {
        type = types.bool;
        default = true;
        description = "Install Markdown language server (marksman)";
      };

      linting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Markdown linting tools";
        };

        markdownlint = mkOption {
          type = types.bool;
          default = true;
          description = "Install markdownlint-cli2 for style checking";
        };

        vale = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Install Vale prose linter";
          };

          styles = mkOption {
            type = with types; listOf (enum ["google" "microsoft" "alex" "write-good" "proselint" "readability"]);
            default = ["google" "write-good"];
            description = "Vale style guides to install";
          };
        };

        linkCheck = mkOption {
          type = types.bool;
          default = true;
          description = "Install markdown-link-check for broken link detection";
        };
      };

      formatting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Markdown formatting tools";
        };

        mdformat = mkOption {
          type = types.bool;
          default = true;
          description = "Install mdformat for CommonMark formatting";
        };

        prettier = mkOption {
          type = types.bool;
          default = false;
          description = "Use prettier for Markdown formatting (alternative to mdformat)";
        };
      };

      preview = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Markdown preview tools";
        };

        glow = mkOption {
          type = types.bool;
          default = true;
          description = "Install glow for terminal markdown rendering";
        };

        grip = mkOption {
          type = types.bool;
          default = false;
          description = "Install grip for GitHub-flavored markdown preview";
        };
      };

      utilities = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable additional Markdown utilities";
        };

        doctoc = mkOption {
          type = types.bool;
          default = true;
          description = "Install doctoc for table of contents generation";
        };

        mdbook = mkOption {
          type = types.bool;
          default = false;
          description = "Install mdbook for creating books from Markdown";
        };

        mermaid = mkOption {
          type = types.bool;
          default = true;
          description = "Install mermaid-cli for diagram generation";
        };
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Additional Markdown-related packages to install";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install document tools
    environment.systemPackages =
      [
        # PDF tools
        pkgs.zathura
        pkgs.evince

        # Document conversion
        pkgs.pandoc
      ]
      # Add Typst packages if enabled
      ++ (
        if cfg.typst.enable
        then
          [
            # Typst compiler and CLI
            pkgs.typst
          ]
          ++ (
            if cfg.typst.lsp
            then [
              # Typst language server
              pkgs.tinymist
            ]
            else []
          )
        else []
      )
      # Add LaTeX packages if enabled
      ++ (
        if cfg.latex.enable
        then
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
              # pkgs.tectonic # Modern LaTeX engine - temporarily disabled due to compilation issues

              # LaTeX editors and IDEs
              pkgs.texstudio # Comprehensive LaTeX IDE
              # pkgs.texmaker # Cross-platform LaTeX editor - temporarily disabled due to Qt6 build issues
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
              pkgs.jabref # Bibliography reference manager

              # Math and science tools
              pkgs.gnuplot # Plotting utility

              # Spell checking
              pkgs.aspell # Spell checker
              pkgs.aspellDicts.en # English dictionary
              pkgs.hunspell # Spell checker
              pkgs.hunspellDicts.en_US # US English dictionary
            ]
        else []
      )
      # Add Markdown packages if enabled
      ++ (
        if cfg.markdown.enable
        then
          [
            # Core Markdown tools
          ]
          # Language server support
          ++ (
            if cfg.markdown.lsp
            then [
              pkgs.marksman # Markdown language server
            ]
            else []
          )
          # Linting tools
          ++ (
            if cfg.markdown.linting.enable
            then
              []
              ++ (
                if cfg.markdown.linting.markdownlint
                then [
                  pkgs.markdownlint-cli2 # Modern Markdown linter
                ]
                else []
              )
              ++ (
                if cfg.markdown.linting.vale.enable
                then
                  [
                    pkgs.vale # Prose linter
                  ]
                  # Vale style guides
                  ++ (map (style: pkgs.valeStyles.${style}) cfg.markdown.linting.vale.styles)
                else []
              )
              ++ (
                if cfg.markdown.linting.linkCheck
                then [
                  pkgs.markdown-link-check # Check for broken links
                ]
                else []
              )
            else []
          )
          # Formatting tools
          ++ (
            if cfg.markdown.formatting.enable
            then
              []
              ++ (
                if cfg.markdown.formatting.mdformat
                then [
                  pkgs.mdformat # CommonMark formatter
                ]
                else []
              )
              ++ (
                if cfg.markdown.formatting.prettier
                then [
                  pkgs.nodePackages.prettier # Alternative formatter
                ]
                else []
              )
            else []
          )
          # Preview tools
          ++ (
            if cfg.markdown.preview.enable
            then
              []
              ++ (
                if cfg.markdown.preview.glow
                then [
                  pkgs.glow # Terminal markdown renderer
                ]
                else []
              )
              ++ (
                if cfg.markdown.preview.grip
                then [
                  pkgs.go-grip # GitHub-flavored markdown preview
                ]
                else []
              )
            else []
          )
          # Utilities
          ++ (
            if cfg.markdown.utilities.enable
            then
              []
              ++ (
                if cfg.markdown.utilities.doctoc
                then [
                  pkgs.doctoc # Table of contents generator
                ]
                else []
              )
              ++ (
                if cfg.markdown.utilities.mdbook
                then [
                  pkgs.mdbook # Create books from Markdown
                ]
                else []
              )
              ++ (
                if cfg.markdown.utilities.mermaid
                then [
                  pkgs.mermaid-cli # Diagram generation
                ]
                else []
              )
            else []
          )
        else []
      )
      ++ cfg.latex.extraPackages
      ++ cfg.typst.extraPackages
      ++ cfg.markdown.extraPackages;
  };
}
