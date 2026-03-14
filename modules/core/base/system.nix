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
        # Disk safety: trigger GC when free space drops below 1 GiB during builds
        min-free = 1073741824;
        # Disk safety: stop GC when 5 GiB free space is recovered
        max-free = 5368709120;
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
      # Distributed builds disabled (no remote builders configured)
      distributedBuilds = false;
    };

    # Security configuration
    security = {
      sudo.wheelNeedsPassword = true;
      # Disable auditd by default — generated 162GB+ logs on desktop (twice)
      # Hosts that need audit (e.g. laptop) can override with lib.mkForce
      auditd.enable = lib.mkDefault false;
      audit.enable = lib.mkDefault false;
      apparmor = {
        enable = true;
        killUnconfinedConfinables = true;
      };
      polkit.enable = true;
      rtkit.enable = true;
    };

    # Disable kernel audit subsystem to prevent ghost log accumulation
    boot.kernel.sysctl."kernel.audit_enabled" = 0;

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
        "vm.dirty_ratio" = lib.mkDefault 15;
        "vm.dirty_background_ratio" = lib.mkDefault 5;
        "vm.vfs_cache_pressure" = lib.mkDefault 50;
        # Security hardening — pointer/memory protections
        "kernel.dmesg_restrict" = 1; # Restrict dmesg to root
        "kernel.kptr_restrict" = 2; # Hide kernel pointers from unprivileged users
        # Security hardening — BPF
        "kernel.unprivileged_bpf_disabled" = 1; # Disable unprivileged BPF
        "net.core.bpf_jit_harden" = 2; # Harden BPF JIT compiler
        # Security hardening — filesystem protections
        "fs.protected_fifos" = 2; # Protect FIFOs in world-writable dirs
        "fs.protected_regular" = 2; # Protect regular files in world-writable dirs
        # Security hardening — network
        "net.ipv4.conf.all.log_martians" = 1; # Log suspicious packets
        "net.ipv4.conf.default.log_martians" = 1;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1; # Ignore broadcast pings
        "net.ipv4.conf.all.send_redirects" = 0; # Don't send ICMP redirects
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.conf.all.accept_redirects" = 0; # Don't accept ICMP redirects
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.all.secure_redirects" = 0; # Don't accept secure redirects
        "net.ipv4.conf.default.secure_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0; # Block source-routed packets
        "net.ipv6.conf.all.accept_source_route" = 0;
        # Security hardening — SYN flood protection
        "net.ipv4.tcp_syncookies" = 1; # Enable SYN cookies
        "net.ipv4.tcp_rfc1337" = 1; # RFC 1337 TIME-WAIT fix
      };
      # ZRAM swap is now managed by modules.core.memoryManagement
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

    # Basic systemd-resolved (full DNS config in host-specific files or modules/networking/dns.nix)
    services.resolved.enable = lib.mkDefault true;

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
