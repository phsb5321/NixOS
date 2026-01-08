# ~/NixOS/modules/core/base/system.nix
#
# Module: Core System Configuration
# Purpose: System-level configuration (Nix, security, SSH, boot, services)
# Part of: 001-module-optimization (T030-T034 - core/default.nix split)
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.core;
in {
  config = lib.mkIf cfg.enable {
    # Nix configuration with performance optimizations
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        timeout = 14400; # 4 hours
        # Performance optimizations
        cores = 0; # Use all available cores
        max-jobs = "auto"; # Auto-detect optimal parallel jobs
        # Reliability improvements
        require-sigs = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
        # Optimize builds
        builders-use-substitutes = true;
        # Cache configuration
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
      # Enable distributed builds for better performance
      distributedBuilds = true;
    };

    # Security configuration
    security = {
      sudo.wheelNeedsPassword = true;
      # Disable auditd to prevent massive log files (162GB issue)
      # auditd.enable = true;
      apparmor = {
        enable = true;
        killUnconfinedConfinables = true;
      };
      polkit.enable = true;
      rtkit.enable = true;
    };

    # SSH configuration
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = lib.mkDefault "no";
        PasswordAuthentication = lib.mkDefault true;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };

    # Boot configuration with performance optimizations
    boot = {
      tmp.useTmpfs = lib.mkDefault true;
      # Performance kernel parameters
      kernel.sysctl = {
        # VM optimizations (can be overridden by host-specific configs)
        "vm.swappiness" = lib.mkDefault 10;
        "vm.dirty_ratio" = 15;
        "vm.dirty_background_ratio" = 5;
        "vm.vfs_cache_pressure" = 50;
        # Network performance (can be overridden by networking module)
        "net.core.rmem_max" = lib.mkDefault 268435456;
        "net.core.wmem_max" = lib.mkDefault 268435456;
        "net.core.netdev_max_backlog" = lib.mkDefault 5000;
        # Security hardening
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.default.log_martians" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
      };
      # ZRAM removed - causing application compatibility issues
      # kernelModules = ["zram"];  # Disabled
    };

    # Core system services
    services = {
      fstrim.enable = true;
      thermald.enable = true;
      printing.enable = true;
      # Limit journal size to prevent disk bloat
      journald.extraConfig = ''
        SystemMaxUse=500M
        MaxRetentionSec=7day
      '';
    };

    # 🎯 KEYBOARD LAYOUT: Console keymap will be automatically derived from xserver.xkb configuration
    # Configure X11 keyboard layout if X11 is available and keyboard config is enabled
    services.xserver = lib.mkIf (config.services.xserver.enable && cfg.keyboard.enable) {
      xkb = {
        inherit (cfg.keyboard) layout;
        inherit (cfg.keyboard) variant;
        inherit (cfg.keyboard) options;
      };
    };

    # Basic systemd-resolved configuration (detailed DNS config in host-specific files)
    services.resolved = {
      enable = true;
      fallbackDns = ["8.8.8.8" "8.8.4.4" "1.1.1.1"];
    };

    # Virtualization configuration
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        defaultNetwork.settings.dns_enabled = true;
      };
      oci-containers = {
        backend = "podman";
        containers = {};
      };
      # Default to false, desktop host enables with plain true
      waydroid.enable = lib.mkDefault false;
    };
  };
}
