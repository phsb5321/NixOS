# modules/core/gui-app-deps.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.guiAppDeps;
in {
  options.modules.core.guiAppDeps = {
    enable = mkEnableOption "GUI application dependencies and libraries";

    web = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable web testing and browser automation dependencies (Cypress, Playwright, etc.)";
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        description = "Additional web testing packages to install";
      };
    };

    electron = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable Electron application dependencies";
      };
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [];
      description = "Additional GUI application packages to install";
    };
  };

  config = mkIf cfg.enable {
    # Install base GUI application dependencies
    environment.systemPackages = with pkgs;
      [
        # Base GUI libraries
        glib
        gtk3
        gtk2
        gdk-pixbuf
        pango
        atk
        cairo

        # Display server libraries
        libdrm
        libxkbcommon
        libxcomposite
        libxdamage
        libxrandr
        libgbm
        libxss

        # Security and authentication
        libnss

        # Audio libraries
        alsa-lib

        # Accessibility
        at-spi2-core
        at-spi2-atk

        # X11 libraries
        libxtst
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libXScrnSaver
        xorg.libXi
        xorg.xauth

        # Virtual display for headless testing
        xvfb-run
      ]
      # Add web testing specific packages
      ++ (optionals cfg.web.enable [
        # Additional web testing dependencies can go here
      ])
      # Add Electron specific packages
      ++ (optionals cfg.electron.enable [
        # Additional Electron dependencies can go here
      ])
      # Add extra packages
      ++ cfg.extraPackages
      ++ cfg.web.extraPackages;

    # Set up environment variables for GUI applications
    environment.variables = {
      # Ensure GUI applications can find the libraries
      LD_LIBRARY_PATH = mkDefault (lib.makeLibraryPath (with pkgs; [
        glib
        gtk3
        gtk2
        gdk-pixbuf
        pango
        atk
        cairo
        libdrm
        libxkbcommon
        libxcomposite
        libxdamage
        libxrandr
        libgbm
        libxss
        libnss
        alsa-lib
        at-spi2-core
        at-spi2-atk
        libxtst
        xorg.libX11
        xorg.libXcomposite
        xorg.libXdamage
        xorg.libXext
        xorg.libXfixes
        xorg.libXrandr
        xorg.libXrender
        xorg.libXtst
        xorg.libXScrnSaver
        xorg.libXi
      ]));
    };
  };
}
