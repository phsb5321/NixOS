# Disk Guardian Module
# Comprehensive disk monitoring and verification to prevent mount failures
# - Verifies UUIDs match expected devices on boot
# - Monitors mount health continuously
# - Sends alerts on failures
# - Prevents services from starting with wrong disk configuration

{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.diskGuardian;

  # Expected UUID for the 2TB torrents disk
  torrentsUUID = "b51ce311-3e53-4541-b793-96a2615ae16e";

  # Verification script that runs on boot
  verifyDisksScript = pkgs.writeShellScript "verify-disks" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LOG_FILE="/var/log/disk-guardian.log"
    ALERT_FILE="/var/run/disk-guardian-alert"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    }

    alert() {
      echo "$1" > "$ALERT_FILE"
      log "ALERT: $1"
    }

    log "=== Disk Guardian: Starting disk verification ==="

    # Verify torrents disk UUID
    TORRENTS_UUID="${torrentsUUID}"
    TORRENTS_DEVICE=$(${pkgs.util-linux}/bin/blkid -U "$TORRENTS_UUID" 2>/dev/null || echo "")

    if [ -z "$TORRENTS_DEVICE" ]; then
      alert "CRITICAL: Torrents disk with UUID $TORRENTS_UUID not found!"
      log "ERROR: Cannot find disk with UUID $TORRENTS_UUID"
      log "Available disks:"
      ${pkgs.util-linux}/bin/blkid | tee -a "$LOG_FILE"
      exit 1
    fi

    log "SUCCESS: Torrents disk found at $TORRENTS_DEVICE (UUID: $TORRENTS_UUID)"

    # Check if disk is mounted
    if ${pkgs.util-linux}/bin/mountpoint -q /mnt/torrents; then
      MOUNTED_UUID=$(${pkgs.util-linux}/bin/findmnt -n -o UUID /mnt/torrents)
      if [ "$MOUNTED_UUID" = "$TORRENTS_UUID" ]; then
        log "SUCCESS: /mnt/torrents is correctly mounted with UUID $TORRENTS_UUID"
      else
        alert "CRITICAL: /mnt/torrents is mounted with WRONG UUID: $MOUNTED_UUID (expected: $TORRENTS_UUID)"
        exit 1
      fi
    else
      log "WARNING: /mnt/torrents is not yet mounted (will be mounted by systemd)"
    fi

    # Verify disk sizes match expectations
    TORRENTS_SIZE=$(${pkgs.util-linux}/bin/lsblk -dn -o SIZE "$TORRENTS_DEVICE" 2>/dev/null || echo "unknown")
    log "Torrents disk size: $TORRENTS_SIZE"

    if [[ "$TORRENTS_SIZE" != *"T"* ]] && [[ "$TORRENTS_SIZE" != *"1.8T"* ]] && [[ "$TORRENTS_SIZE" != *"2T"* ]]; then
      alert "WARNING: Torrents disk size ($TORRENTS_SIZE) does not match expected ~2TB"
    fi

    # Check filesystem health
    log "Checking filesystem health..."
    FSCK_STATUS=$(${pkgs.e2fsprogs}/bin/dumpe2fs -h "$TORRENTS_DEVICE" 2>&1 | grep "Filesystem state" || echo "unknown")
    log "Filesystem state: $FSCK_STATUS"

    log "=== Disk Guardian: Verification complete ==="
    rm -f "$ALERT_FILE"
    exit 0
  '';

  # Monitoring script that checks mount health
  monitorMountsScript = pkgs.writeShellScript "monitor-mounts" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LOG_FILE="/var/log/disk-guardian.log"
    CHECK_INTERVAL=''${CHECK_INTERVAL:-60}

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] MONITOR: $1" | tee -a "$LOG_FILE"
    }

    log "Starting mount health monitoring (interval: ''${CHECK_INTERVAL}s)"

    while true; do
      # Check torrents mount
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/torrents; then
        log "ERROR: /mnt/torrents is not mounted!"
        # Try to remount
        log "Attempting to remount /mnt/torrents..."
        if systemctl restart mnt-torrents.mount 2>/dev/null; then
          log "SUCCESS: /mnt/torrents remounted"
        else
          log "FAILED: Could not remount /mnt/torrents"
        fi
      fi

      # Check if torrents disk is readable
      if ${pkgs.util-linux}/bin/mountpoint -q /mnt/torrents; then
        if ! timeout 5 ls /mnt/torrents/completed >/dev/null 2>&1; then
          log "ERROR: /mnt/torrents is mounted but not readable!"
        fi
      fi

      # Check AudioBooks SSHFS mount
      if ! ${pkgs.util-linux}/bin/mountpoint -q /mnt/torrents/plex/AudioBooks; then
        log "WARNING: AudioBooks SSHFS mount is not mounted"
      fi

      # Check Audiobookshelf Docker container
      if command -v docker >/dev/null 2>&1; then
        if ! docker ps --filter "name=audiobookshelf" --filter "status=running" --format "{{.Names}}" | grep -q "audiobookshelf"; then
          log "ERROR: Audiobookshelf container is not running!"
          # Try to restart the service
          if systemctl restart audiobookshelf 2>/dev/null; then
            log "SUCCESS: Audiobookshelf service restarted"
          else
            log "FAILED: Could not restart Audiobookshelf"
          fi
        else
          # Container is running, check if it's responding
          if ! timeout 3 curl -s http://localhost:13378/audiobookshelf/ >/dev/null 2>&1; then
            log "WARNING: Audiobookshelf container running but not responding on port 13378"
          fi
        fi
      fi

      # Check Cloudflare Tunnel
      if ! systemctl is-active --quiet cloudflared-tunnel; then
        log "ERROR: Cloudflare Tunnel is not running!"
        if systemctl restart cloudflared-tunnel 2>/dev/null; then
          log "SUCCESS: Cloudflare Tunnel restarted"
        else
          log "FAILED: Could not restart Cloudflare Tunnel"
        fi
      fi

      sleep "$CHECK_INTERVAL"
    done
  '';
in {
  options.modules.services.diskGuardian = {
    enable = lib.mkEnableOption "Disk Guardian monitoring and verification";

    enableBootVerification = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Verify disks on boot before starting critical services";
    };

    enableContinuousMonitoring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Continuously monitor mount health";
    };

    monitorInterval = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Mount monitoring interval in seconds";
    };
  };

  config = lib.mkIf cfg.enable {
    # Boot-time disk verification service
    systemd.services.disk-guardian-verify = lib.mkIf cfg.enableBootVerification {
      description = "Disk Guardian: Verify disk configuration on boot";
      wantedBy = ["multi-user.target"];
      before = ["qbittorrent.service" "plex.service" "audiobookshelf.service"];
      after = ["local-fs.target"];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = verifyDisksScript;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Continuous mount monitoring service
    systemd.services.disk-guardian-monitor = lib.mkIf cfg.enableContinuousMonitoring {
      description = "Disk Guardian: Monitor mount health";
      wantedBy = ["multi-user.target"];
      after = ["mnt-torrents.mount"];

      environment = {
        CHECK_INTERVAL = toString cfg.monitorInterval;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = monitorMountsScript;
        Restart = "always";
        RestartSec = "10s";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Create log file
    systemd.tmpfiles.rules = [
      "f /var/log/disk-guardian.log 0644 root root -"
    ];

    # Add utilities for monitoring
    environment.systemPackages = with pkgs; [
      util-linux
      e2fsprogs
    ];
  };
}
