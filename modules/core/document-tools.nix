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
            ]
          else
            # Full LaTeX installation
            [
              pkgs.texlive.combined.scheme-full
              # Additional useful LaTeX tools
              pkgs.texlab # LaTeX language server
              pkgs.tectonic # Modern LaTeX engine
            ]
        else []
      )
      ++ cfg.latex.extraPackages
      ++ cfg.typst.extraPackages;
  };
}
