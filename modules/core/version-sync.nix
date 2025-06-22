# ~/NixOS/modules/core/version-sync.nix
# System version synchronization module for NixOS 25.05
{
  config,
  lib,
  pkgs,
  stablePkgs,
  bleedPkgs,
  systemVersion,
  ...
}:
with lib; let
  cfg = config.modules.core.versionSync;
in {
  options.modules.core.versionSync = {
    enable = mkEnableOption "Version synchronization system";

    systemChannel = mkOption {
      type = types.enum ["stable" "unstable"];
      default = "stable";
      description = "Which channel to use for system packages";
    };

    packageChannel = mkOption {
      type = types.enum ["stable" "unstable" "bleeding"];
      default = "bleeding";
      description = "Which channel to use for user packages";
    };

    forceSystemStable = mkOption {
      type = types.bool;
      default = true;
      description = "Force core system components to use stable channel";
    };

    allowedUnstableSystemPackages = mkOption {
      type = with types; listOf str;
      default = [
        "linux"
        "mesa"
        "vulkan-loader"
        "amdvlk"
        "nvidia"
      ];
      description = "System packages allowed to use unstable versions";
    };
  };

  config = mkIf cfg.enable {
    # Ensure system version matches NixOS 25.05
    system.stateVersion = systemVersion;

    # System info reporting
    environment.etc."nixos-version-info".text = ''
      NixOS System Version: ${systemVersion}
      System Channel: ${cfg.systemChannel}
      Package Channel: ${cfg.packageChannel}
      Force System Stable: ${boolToString cfg.forceSystemStable}
      Build Date: ${config.system.nixos.version}
    '';

    # Version check script
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "nixos-version-check" ''
        echo "=== NixOS Version Information ==="
        echo "System Version: ${systemVersion}"
        echo "Current NixOS: $(nixos-version)"
        echo "Kernel: $(uname -r)"
        echo ""
        echo "=== Channel Information ==="
        cat /etc/nixos-version-info
        echo ""
        echo "=== GPU Driver Information ==="
        ${libva-utils}/bin/vainfo 2>/dev/null | head -5 || echo "VAAPI not available"
        ${vulkan-tools}/bin/vulkaninfo | grep -E "(deviceName|driverInfo)" | head -2 || echo "Vulkan not available"
      '')

      (writeShellScriptBin "nixos-wayland-check" ''
        echo "=== Wayland Session Check ==="
        echo "Session Type: $XDG_SESSION_TYPE"
        echo "Wayland Display: $WAYLAND_DISPLAY"
        echo "GDK Backend: $GDK_BACKEND"
        echo "Qt Platform: $QT_QPA_PLATFORM"
        echo "Mozilla Wayland: $MOZ_ENABLE_WAYLAND"
        echo "Ozone Wayland: $NIXOS_OZONE_WL"
        echo ""
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
          echo "✓ Running Wayland session"
        else
          echo "✗ Not running Wayland session"
        fi
      '')
    ];

    # Assertion to ensure version consistency
    assertions = [
      {
        assertion = config.system.stateVersion == systemVersion;
        message = "System state version must match configured system version (${systemVersion})";
      }
      {
        assertion = cfg.forceSystemStable -> cfg.systemChannel == "stable";
        message = "When forceSystemStable is enabled, systemChannel must be 'stable'";
      }
    ];
  };
}
