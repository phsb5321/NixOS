# Protontricks Helper Module
# Provides helper scripts for common Proton prefix management tasks
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.gaming.protontricks;
in {
  options.modules.gaming.protontricks = with lib; {
    enable = mkEnableOption "protontricks with helper scripts";

    helperScripts = mkOption {
      type = types.bool;
      default = true;
      description = "Install helper scripts for vcrun, dotnet installation";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install protontricks package and helper scripts
    environment.systemPackages =
      [pkgs.protontricks]
      ++ lib.optionals cfg.helperScripts [
      (pkgs.writeScriptBin "install-vcrun2019" ''
        #!${pkgs.bash}/bin/bash
        # Helper script to install Visual C++ 2019 runtime into Proton prefix
        # Usage: install-vcrun2019 <steam-app-id>

        if [ -z "$1" ]; then
          echo "Usage: install-vcrun2019 <steam-app-id>"
          echo "Example: install-vcrun2019 323190  # For Frostpunk"
          echo ""
          echo "Find your game's App ID with: protontricks -l | grep -i <game-name>"
          exit 1
        fi

        echo "Installing Visual C++ 2019 runtime for App ID: $1"
        ${pkgs.protontricks}/bin/protontricks "$1" vcrun2019
      '')

      (pkgs.writeScriptBin "install-vcrun2022" ''
        #!${pkgs.bash}/bin/bash
        # Helper script to install Visual C++ 2022 runtime into Proton prefix
        # Usage: install-vcrun2022 <steam-app-id>

        if [ -z "$1" ]; then
          echo "Usage: install-vcrun2022 <steam-app-id>"
          echo "Example: install-vcrun2022 323190"
          echo ""
          echo "Find your game's App ID with: protontricks -l | grep -i <game-name>"
          exit 1
        fi

        echo "Installing Visual C++ 2022 runtime for App ID: $1"
        ${pkgs.protontricks}/bin/protontricks "$1" vcrun2022
      '')

      (pkgs.writeScriptBin "list-steam-games" ''
        #!${pkgs.bash}/bin/bash
        # Helper script to list all Steam games with their App IDs
        # Usage: list-steam-games [search-term]

        if [ -z "$1" ]; then
          echo "Listing all Steam games with App IDs:"
          ${pkgs.protontricks}/bin/protontricks -l
        else
          echo "Searching for games matching: $1"
          ${pkgs.protontricks}/bin/protontricks -l | grep -i "$1"
        fi
      '')

      (pkgs.writeScriptBin "fix-frostpunk" ''
        #!${pkgs.bash}/bin/bash
        # Quick-fix script for Frostpunk MSVC Runtime error
        # Automatically installs vcrun2019 for Frostpunk (App ID: 323190)

        echo "=== Frostpunk MSVC Runtime Fix ==="
        echo ""
        echo "This script will install Visual C++ 2019 runtime for Frostpunk"
        echo "App ID: 323190"
        echo ""
        echo "Make sure you have:"
        echo "1. Launched Frostpunk at least once (to create Proton prefix)"
        echo "2. Closed Steam completely"
        echo ""
        read -p "Press Enter to continue or Ctrl+C to cancel..."

        echo ""
        echo "Installing vcrun2019 for Frostpunk..."
        ${pkgs.protontricks}/bin/protontricks 323190 vcrun2019

        echo ""
        echo "=== Installation Complete ==="
        echo "Now launch Frostpunk from Steam. It should start without errors."
      '')
    ];
  };
}
