# ~/NixOS/modules/core/flatpak.nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.core.flatpak;
in {
  options.modules.core.flatpak = {
    enable = mkEnableOption "Flatpak support";

    remotes = mkOption {
      type = with types;
        listOf (submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Name of the Flatpak remote";
            };
            location = mkOption {
              type = types.str;
              description = "URL of the Flatpak remote";
            };
          };
        });
      default = [
        {
          name = "flathub";
          location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
        }
      ];
      description = "List of Flatpak remotes to add";
    };

    packages = mkOption {
      type = with types; listOf str;
      default = [];
      description = "List of Flatpak packages to install";
      example = [
        "com.spotify.Client"
        "org.mozilla.firefox"
        "com.discordapp.Discord"
      ];
    };

    enablePortals = mkOption {
      type = types.bool;
      default = true;
      description = "Enable XDG desktop portals for Flatpak integration";
    };

    enableFontconfig = mkOption {
      type = types.bool;
      default = true;
      description = "Enable fontconfig integration for Flatpak apps";
    };

    enableThemes = mkOption {
      type = types.bool;
      default = true;
      description = "Enable theme integration for Flatpak apps";
    };
  };

  config = mkIf (config.modules.core.enable && cfg.enable) {
    # Enable Flatpak service
    services.flatpak.enable = true;

    # Enable XDG desktop portals for proper integration
    xdg.portal = mkIf cfg.enablePortals {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config = {
        common = {
          default = mkDefault [
            "gtk"
          ];
        };
        gnome = {
          default = mkDefault [
            "gnome"
            "gtk"
          ];
        };
      };
    };

    # System packages for Flatpak management
    environment.systemPackages = with pkgs; [
      flatpak
      gnome-software # GUI for managing Flatpaks
    ];

    # Font integration for Flatpak apps
    fonts.fontDir.enable = mkIf cfg.enableFontconfig true;

    # Theme integration - make system themes available to Flatpak apps
    environment.pathsToLink = mkIf cfg.enableThemes [
      "/share/icons"
      "/share/themes"
      "/share/mime"
    ];

    # Automatic setup of Flatpak remotes and packages
    system.activationScripts.flatpak = mkIf (cfg.remotes != [] || cfg.packages != []) {
      text = ''
        echo "Setting up Flatpak..."

        # Wait for Flatpak service to be ready
        while ! ${pkgs.flatpak}/bin/flatpak --version >/dev/null 2>&1; do
          echo "Waiting for Flatpak service..."
          sleep 1
        done

        # Add remotes
        ${concatMapStringsSep "\n" (remote: ''
            if ! ${pkgs.flatpak}/bin/flatpak remote-list | grep -q "^${remote.name}"; then
              echo "Adding Flatpak remote: ${remote.name}"
              ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system ${remote.name} ${remote.location} || true
            fi
          '')
          cfg.remotes}

        # Install packages
        ${concatMapStringsSep "\n" (pkg: ''
            if ! ${pkgs.flatpak}/bin/flatpak list --system | grep -q "${pkg}"; then
              echo "Installing Flatpak package: ${pkg}"
              ${pkgs.flatpak}/bin/flatpak install --system --noninteractive --assumeyes ${pkg} || true
            fi
          '')
          cfg.packages}

        echo "Flatpak setup complete"
      '';
      deps = ["users"];
    };

    # User-level Flatpak setup (requires users to run manually)
    environment.etc."flatpak-user-setup.sh" = mkIf (cfg.remotes != [] || cfg.packages != []) {
      text = ''
        #!/bin/bash
        # User Flatpak Setup Script
        echo "Setting up user-level Flatpak..."

        # Add remotes for user
        ${concatMapStringsSep "\n" (remote: ''
            if ! flatpak remote-list --user | grep -q "^${remote.name}"; then
              echo "Adding user Flatpak remote: ${remote.name}"
              flatpak remote-add --if-not-exists --user ${remote.name} ${remote.location}
            fi
          '')
          cfg.remotes}

        echo "User Flatpak setup complete"
        echo "To install packages for your user, run:"
        echo "  flatpak install --user <package-name>"
      '';
      mode = "0755";
    };

    # Polkit rules for Flatpak management
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if ((action.id == "org.freedesktop.Flatpak.app-install" ||
               action.id == "org.freedesktop.Flatpak.runtime-install" ||
               action.id == "org.freedesktop.Flatpak.app-uninstall" ||
               action.id == "org.freedesktop.Flatpak.runtime-uninstall" ||
               action.id == "org.freedesktop.Flatpak.modify-repo") &&
              subject.isInGroup("wheel")) {
              return polkit.Result.YES;
          }
      });
    '';
  };
}
