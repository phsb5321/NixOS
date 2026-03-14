# modules/core/memory-management.nix
#
# Module: Memory Management
# Purpose: 4-layer defense against RAM exhaustion freezes
#   Layer 1: ZRAM compressed swap (absorbs memory pressure)
#   Layer 2: KSM page deduplication (trades CPU cycles for RAM savings)
#   Layer 3: earlyoom daemon (kills runaway processes before kernel OOM)
#   Layer 4: systemd cgroup limits (caps heavy services)
#
# Part of: 012-memory-limit-freeze-fix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.core.memoryManagement;

  # Tiny shared library that calls prctl(PR_SET_MEMORY_MERGE, 1) at load time.
  # When LD_PRELOAD'd, every process automatically opts into KSM page deduplication.
  # The flag is inherited across fork+exec, so child processes get it too.
  ksmPreload = pkgs.stdenv.mkDerivation {
    pname = "ksm-preload";
    version = "1.0";
    dontUnpack = true;
    buildPhase = ''
      cat > ksm_preload.c << 'EOF'
      #include <sys/prctl.h>
      #ifndef PR_SET_MEMORY_MERGE
      #define PR_SET_MEMORY_MERGE 67
      #endif
      __attribute__((constructor))
      static void enable_ksm(void) {
          prctl(PR_SET_MEMORY_MERGE, 1, 0, 0, 0);
      }
      EOF
      $CC -shared -fPIC -O2 -o libksm_preload.so ksm_preload.c
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp libksm_preload.so $out/lib/
    '';
  };
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
        default = "lz4";
        description = "Compression algorithm for ZRAM. lz4 is fastest with lowest CPU overhead; zstd offers best ratio.";
      };

      swappiness = mkOption {
        type = types.int;
        default = 180;
        description = ''
          vm.swappiness value. Kernel docs recommend >100 for in-memory swap (ZRAM).
          180 strongly prefers ZRAM (decompressing from RAM is faster than SSD reads).
        '';
      };
    };

    # --- Layer 2: KSM (Kernel Same-page Merging) ---
    ksm = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable KSM to deduplicate identical memory pages across processes.
          Trades CPU scanning time for RAM savings — ideal for workloads with
          many similar processes (multiple browser tabs, Node.js instances, VMs).
          Uses LD_PRELOAD to call prctl(PR_SET_MEMORY_MERGE) in every process.
        '';
      };

      sleepMs = mkOption {
        type = types.int;
        default = 200;
        description = ''
          Milliseconds between KSM scan batches. Lower = faster dedup but more CPU.
          200ms balances dedup effectiveness with low CPU overhead on desktops.
          Kernel default is 20ms; upstream recommends 100-200ms for desktops.
        '';
      };

      pagesToScan = mkOption {
        type = types.int;
        default = 500;
        description = ''
          Pages to scan per sleep interval. Higher = faster convergence, more CPU.
          Default 500 pages/200ms = ~1 MB/s scan rate — gentle on interactive desktops.
          Kernel default is 100; 500 is a good balance for 28+ thread CPUs.
        '';
      };
    };

    # --- Layer 3: earlyoom ---
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

    # --- Layer 4: Cgroup limits ---
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
      kernel.sysctl = lib.mkMerge [
        (lib.mkIf cfg.zram.enable {
          # Override any existing swappiness with ZRAM-appropriate value
          "vm.swappiness" = lib.mkForce cfg.zram.swappiness;
          # Disable watermark boosting — causes latency spikes with ZRAM
          "vm.watermark_boost_factor" = 0;
          # Read single pages from ZRAM (sequential prefetch wastes effort on compressed swap)
          "vm.page-cluster" = lib.mkForce 0;
        })
        {
          # Reclaim VFS caches (dentries/inodes) more aggressively — frees slab memory
          # Default 100 = equal pressure; 75 = moderately prefer reclaiming VFS caches
          "vm.vfs_cache_pressure" = lib.mkForce 75;
          # Proactively compact memory in the background to reduce fragmentation
          # Default 20; 40 = more aggressive compaction using spare CPU cycles
          "vm.compaction_proactiveness" = 40;
        }
      ];

      # Disable zswap if ZRAM is active (they conflict)
      kernelParams = lib.mkIf (cfg.zram.enable && cfg.disableZswap) [
        "zswap.enabled=0"
      ];
    };

    # === Layer 2: KSM page deduplication ===
    # Configure KSM kernel parameters via tmpfiles (sysfs knobs)
    systemd.tmpfiles.rules = lib.mkIf cfg.ksm.enable [
      "w /sys/kernel/mm/ksm/run - - - - 1"
      "w /sys/kernel/mm/ksm/sleep_millisecs - - - - ${toString cfg.ksm.sleepMs}"
      "w /sys/kernel/mm/ksm/pages_to_scan - - - - ${toString cfg.ksm.pagesToScan}"
      # Deduplicate zero-filled pages without app cooperation (free win)
      "w /sys/kernel/mm/ksm/use_zero_pages - - - - 1"
    ];

    # LD_PRELOAD a tiny .so that calls prctl(PR_SET_MEMORY_MERGE, 1) at load time.
    # This makes every new process opt into KSM scanning automatically.
    # Without this, KSM sits idle because no apps call madvise(MADV_MERGEABLE).
    environment.variables.LD_PRELOAD = lib.mkIf cfg.ksm.enable "${ksmPreload}/lib/libksm_preload.so";

    # === Layer 3: earlyoom (kill before OOM) ===
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

    # === Layer 4: systemd cgroup limits ===
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
