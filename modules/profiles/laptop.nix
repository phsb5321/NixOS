# Laptop profile module - combines all laptop-specific configurations
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.profiles.laptop;
in {
  options.modules.profiles.laptop = {
    enable = lib.mkEnableOption "laptop profile with optimized settings";

    variant = lib.mkOption {
      type = lib.types.enum ["ultrabook" "gaming" "workstation" "standard"];
      default = "standard";
      description = ''
        Laptop variant:
        - ultrabook: Maximum battery life, minimal features
        - gaming: Performance-oriented with discrete GPU support
        - workstation: Balanced for development work
        - standard: General purpose laptop
      '';
    };

    gnomeExtensions = {
      minimal = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use minimal set of GNOME extensions for better battery life";
      };

      productivity = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable productivity-focused GNOME extensions";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable laptop hardware module
    modules.hardware.laptop = {
      enable = true;

      batteryManagement = {
        enable = true;
        chargeThreshold = lib.mkDefault (
          if cfg.variant == "ultrabook"
          then 80
          else if cfg.variant == "gaming"
          then null # Full charge for gaming
          else 85
        );
      };

      powerManagement = {
        enable = true;
        profile = lib.mkDefault (
          if cfg.variant == "gaming"
          then "performance"
          else if cfg.variant == "ultrabook"
          then "powersave"
          else "balanced"
        );
        autoSuspend = cfg.variant != "gaming";
        suspendTimeout =
          if cfg.variant == "ultrabook"
          then 600
          else 900;
      };

      display = {
        autoRotate = cfg.variant != "gaming"; # Disabled for gaming laptops
        brightnessControl = true;
        nightLight = true;
      };

      touchpad = {
        enable = true;
        naturalScrolling = true;
        tapToClick = true;
        disableWhileTyping = true;
      };
    };

    # Enable GNOME desktop with laptop optimizations
    modules.desktop.gnome = {
      enable = true;
      wayland.enable = true;

      variant = lib.mkDefault (
        if cfg.variant == "gaming"
        then "hardware"
        else if cfg.variant == "ultrabook"
        then "conservative"
        else "hardware"
      );

      # Laptop-specific extensions
      extensions = {
        enable = true;
        list = lib.mkDefault (
          (lib.optionals (!cfg.gnomeExtensions.minimal) [
            # Core functionality
            "dash-to-dock@micxgx.gmail.com"
            "user-theme@gnome-shell-extensions.gcampax.github.com"
            "just-perfection-desktop@just-perfection"
            "appindicatorsupport@rgcjonas.gmail.com"

            # System monitoring
            "Vitals@CoreCoding.com"

            # Power management
            "caffeine@patapon.info"
            "battery-health-charging@maniacx.github.com"
            "battery-time@alexlebens.github.io"
          ])
          ++ (lib.optionals cfg.gnomeExtensions.productivity [
            # Productivity
            "forge@jmmaranan.com" # Tiling
            "clipboard-indicator@tudmotu.com"
            "fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com"
            "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
            "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
          ])
          ++ (lib.optionals (cfg.variant == "ultrabook" && cfg.gnomeExtensions.minimal) [
            # Ultra-minimal for battery life
            "battery-indicator@jgotti.org"
          ])
        );
      };
    };

    # Package selection based on variant
    modules.packages = {
      enable = true;

      # Disable heavy features for ultrabooks
      gaming.enable = lib.mkDefault (cfg.variant == "gaming");

      extraPackages = with pkgs;
        [
          # Laptop essentials
          powertop
          tlp
          acpi
          brightnessctl

          # Variant-specific packages
        ]
        ++ lib.optionals (cfg.variant == "gaming") [
          nvtop
          mangohud
          gamemode
        ]
        ++ lib.optionals (cfg.variant == "workstation") [
          docker-compose
          kubectl
          terraform
        ]
        ++ lib.optionals (cfg.variant == "ultrabook") [
          # Minimal extra packages for ultrabooks
        ]
        ++ lib.optionals cfg.gnomeExtensions.productivity [
          gnomeExtensions.forge
          gnomeExtensions.arc-menu
          gnomeExtensions.paperwm
          gnomeExtensions.pop-shell
        ];
    };

    # Core module optimizations for laptops
    modules.core = {
      documentTools = {
        enable = true;
        latex.enable = lib.mkDefault (cfg.variant != "ultrabook");
        markdown = {
          enable = true;
          utilities = {
            enable = lib.mkDefault (cfg.variant == "workstation");
          };
        };
      };
    };

    # Networking optimizations for laptops
    modules.networking.firewall = {
      enable = true;
      developmentPorts = lib.mkDefault (
        if cfg.variant == "workstation"
        then [3000 8080]
        else []
      );
      allowedServices = lib.mkDefault (
        if cfg.variant == "workstation" || cfg.variant == "standard"
        then ["ssh"]
        else []
      );
    };

    # System-level optimizations
    boot.kernelParams = lib.mkDefault (
      ["quiet" "splash"]
      ++ lib.optionals (cfg.variant == "ultrabook") [
        "i915.enable_fbc=1"
        "i915.enable_psr=2"
      ]
      ++ lib.optionals (cfg.variant == "gaming") [
        "mitigations=off" # Better performance, less secure
      ]
    );

    # Swappiness for laptops (prefer RAM over swap)
    boot.kernel.sysctl = {
      "vm.swappiness" = lib.mkForce 10;
      "vm.laptop_mode" = lib.mkDefault 5;
    };

    # Enable zram for better memory management
    zramSwap = {
      enable = true;
      algorithm = "zstd";
      memoryPercent = lib.mkDefault (
        if cfg.variant == "ultrabook"
        then 50
        else 25
      );
    };

    # I/O scheduler optimized for SSDs (common in laptops)
    services.udev.extraRules = ''
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    '';
  };
}
