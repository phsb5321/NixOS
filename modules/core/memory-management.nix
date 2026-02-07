# modules/core/memory-management.nix
#
# Module: Memory Management
# Purpose: 3-layer defense against RAM exhaustion freezes
#   Layer 1: ZRAM compressed swap (absorbs memory pressure)
#   Layer 2: earlyoom daemon (kills runaway processes before kernel OOM)
#   Layer 3: systemd cgroup limits (caps heavy services)
#
# Part of: 012-memory-limit-freeze-fix
{
  config,
  lib,
  ...
}: let
  cfg = config.modules.core.memoryManagement;
in {
  options.modules.core.memoryManagement = with lib; {
    enable = mkEnableOption "Memory management with ZRAM, earlyoom, and cgroup limits";

    # --- Layer 1: ZRAM ---
    zram = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable ZRAM compressed swap device";
      };

      memoryPercent = mkOption {
        type = types.int;
        default = 50;
        description = "Percentage of RAM to use for ZRAM (uncompressed capacity)";
      };

      algorithm = mkOption {
        type = types.enum ["zstd" "lz4" "lzo" "lzo-rle"];
        default = "zstd";
        description = "Compression algorithm for ZRAM. zstd offers best ratio; lz4 is fastest.";
      };

      swappiness = mkOption {
        type = types.int;
        default = 180;
        description = ''
          vm.swappiness value. Kernel docs recommend >100 for in-memory swap (ZRAM).
          180 aggressively moves cold pages to ZRAM, freeing real RAM for active use.
        '';
      };
    };

    # --- Layer 2: earlyoom ---
    earlyoom = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable earlyoom daemon to kill processes before kernel OOM freezes the system";
      };

      freeMemThresholdPercent = mkOption {
        type = types.int;
        default = 5;
        description = "Start killing when free memory drops below this percentage";
      };

      freeSwapThresholdPercent = mkOption {
        type = types.int;
        default = 10;
        description = "Start killing when free swap drops below this percentage";
      };

      enableNotifications = mkOption {
        type = types.bool;
        default = true;
        description = "Send desktop notifications when earlyoom kills a process";
      };

      preferRegex = mkOption {
        type = types.str;
        default = "(Web Content|Isolated Web|chrome|chromium)";
        description = "Regex matching processes to prefer killing (browser tabs, etc.)";
      };

      avoidRegex = mkOption {
        type = types.str;
        default = "(sshd|systemd|gnome-shell|gdm|Xwayland)";
        description = "Regex matching processes to avoid killing (critical system processes)";
      };
    };

    # --- Layer 3: Cgroup limits ---
    nixDaemon = {
      memoryHigh = mkOption {
        type = types.str;
        default = "48G";
        description = ''
          MemoryHigh (soft limit) for nix-daemon. Throttles allocation above this.
          Set generously to allow large builds while preventing runaway consumption.
        '';
      };

      memoryMax = mkOption {
        type = types.str;
        default = "56G";
        description = "MemoryMax (hard limit) for nix-daemon. OOM-killed if exceeded.";
      };
    };

    docker = {
      memoryMax = mkOption {
        type = types.str;
        default = "40G";
        description = "MemoryMax (hard limit) for Docker service. Prevents container workloads from consuming all RAM.";
      };
    };

    # --- Kernel tuning ---
    disableZswap = mkOption {
      type = types.bool;
      default = true;
      description = "Disable kernel zswap (conflicts with ZRAM; zswap wastes RAM when ZRAM is active)";
    };
  };

  config = lib.mkIf cfg.enable {
    # === Layer 1: ZRAM compressed swap ===
    zramSwap = lib.mkIf cfg.zram.enable {
      enable = true;
      memoryPercent = cfg.zram.memoryPercent;
      algorithm = cfg.zram.algorithm;
    };

    boot = {
      kernel.sysctl = lib.mkIf cfg.zram.enable {
        # Override any existing swappiness with ZRAM-appropriate value
        "vm.swappiness" = lib.mkForce cfg.zram.swappiness;
        # Disable watermark boosting — causes latency spikes with ZRAM
        "vm.watermark_boost_factor" = 0;
        # Read single pages from ZRAM (sequential prefetch wastes effort on compressed swap)
        "vm.page-cluster" = lib.mkForce 0;
      };

      # Disable zswap if ZRAM is active (they conflict)
      kernelParams = lib.mkIf (cfg.zram.enable && cfg.disableZswap) [
        "zswap.enabled=0"
      ];
    };

    # === Layer 2: earlyoom ===
    services.earlyoom = lib.mkIf cfg.earlyoom.enable {
      enable = true;
      freeMemThreshold = cfg.earlyoom.freeMemThresholdPercent;
      freeSwapThreshold = cfg.earlyoom.freeSwapThresholdPercent;
      enableNotifications = cfg.earlyoom.enableNotifications;
      extraArgs = let
        args =
          []
          ++ lib.optionals (cfg.earlyoom.preferRegex != "") [
            "--prefer"
            "'${cfg.earlyoom.preferRegex}'"
          ]
          ++ lib.optionals (cfg.earlyoom.avoidRegex != "") [
            "--avoid"
            "'${cfg.earlyoom.avoidRegex}'"
          ];
      in
        args;
    };

    # Disable systemd-oomd when earlyoom is active — prevents OOM daemon race conditions
    systemd.oomd.enable = lib.mkIf cfg.earlyoom.enable (lib.mkForce false);

    # === Layer 3: systemd cgroup limits ===
    systemd.services.nix-daemon.serviceConfig = {
      MemoryHigh = cfg.nixDaemon.memoryHigh;
      MemoryMax = cfg.nixDaemon.memoryMax;
    };

    systemd.services.docker = lib.mkIf config.virtualisation.docker.enable {
      serviceConfig = {
        MemoryMax = cfg.docker.memoryMax;
      };
    };
  };
}
