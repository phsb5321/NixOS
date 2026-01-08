# ~/NixOS/modules/core/document-tools/options.nix
#
# Module: Document Tools Options
# Purpose: Declares all document preparation configuration options
# Part of: 001-module-optimization (T040-T044 - document-tools.nix split)
{lib, ...}:
with lib; {
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
}
