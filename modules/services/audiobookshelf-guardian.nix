# Audiobookshelf Guardian Module
# Ensures Audiobookshelf stays healthy and accessible
# - Verifies correct URL path configuration
# - Monitors container health
# - Checks data persistence
# - Validates Cloudflare Tunnel access
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.audiobookshelfGuardian;

  # Health check script that runs on startup and periodically
  healthCheckScript = pkgs.writeShellScript "audiobookshelf-health-check" ''
    #!/usr/bin/env bash
    set -euo pipefail

    LOG_FILE="/var/log/audiobookshelf-guardian.log"
    MAX_RETRIES=3
    RETRY_DELAY=10

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    }

    error() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE"
    }

    # Retry wrapper for curl commands
    retry_curl() {
      local url="$1"
      local attempt=1
      while [ $attempt -le $MAX_RETRIES ]; do
        if timeout 10 ${pkgs.curl}/bin/curl -f -s "$url" >/dev/null 2>&1; then
          return 0
        fi
        if [ $attempt -lt $MAX_RETRIES ]; then
          log "Attempt $attempt failed for $url, retrying in ''${RETRY_DELAY}s..."
          sleep $RETRY_DELAY
        fi
        attempt=$((attempt + 1))
      done
      return 1
    }

    log "=== Audiobookshelf Health Check Starting ==="

    # 1. Check if Docker container exists and is running
    if ! ${pkgs.docker}/bin/docker ps --filter "name=audiobookshelf" --filter "status=running" --format "{{.Names}}" | grep -q "audiobookshelf"; then
      error "Audiobookshelf container is not running!"
      exit 1
    fi
    log "✓ Docker container is running"

    # 2. Check if service responds on localhost (with retries)
    if ! retry_curl "http://localhost:13378/audiobookshelf/"; then
      error "Audiobookshelf not responding on http://localhost:13378/audiobookshelf/ after $MAX_RETRIES attempts"
      exit 1
    fi
    log "✓ Local access working: http://localhost:13378/audiobookshelf/"

    # 3. Check if JavaScript assets are accessible (dynamically find any _nuxt/*.js file)
    JS_FILE=$(timeout 5 ${pkgs.curl}/bin/curl -s http://localhost:13378/audiobookshelf/ | ${pkgs.gnugrep}/bin/grep -oE '_nuxt/[a-zA-Z0-9]+\.js' | head -1)
    if [ -z "$JS_FILE" ]; then
      error "No JavaScript assets found in page!"
      exit 1
    fi
    if ! timeout 5 ${pkgs.curl}/bin/curl -f -s "http://localhost:13378/audiobookshelf/$JS_FILE" >/dev/null 2>&1; then
      error "JavaScript assets not accessible: $JS_FILE"
      exit 1
    fi
    log "✓ JavaScript assets accessible: $JS_FILE"

    # 4. Check data directory exists and has content
    if [ ! -d "/var/lib/audiobookshelf/config" ]; then
      error "Config directory missing!"
      exit 1
    fi
    log "✓ Config directory exists"

    # 5. Check AudioBooks mount
    if [ ! -d "/mnt/torrents/plex/AudioBooks" ]; then
      error "AudioBooks directory not accessible!"
      exit 1
    fi
    log "✓ AudioBooks directory accessible"

    # 6. Check Cloudflare Tunnel (if enabled)
    if systemctl is-enabled cloudflared-tunnel >/dev/null 2>&1; then
      if ! systemctl is-active --quiet cloudflared-tunnel; then
        error "Cloudflare Tunnel is not running!"
        exit 1
      fi
      log "✓ Cloudflare Tunnel is active"
    fi

    # 7. Verify container environment
    ROUTER_BASE_PATH=$(${pkgs.docker}/bin/docker exec audiobookshelf env 2>/dev/null | grep "ROUTER_BASE_PATH" | cut -d= -f2 || echo "")
    log "✓ Container ROUTER_BASE_PATH: '$ROUTER_BASE_PATH' (empty = default /audiobookshelf/)"

    log "=== Audiobookshelf Health Check PASSED ==="
    exit 0
  '';

  # Data backup script
  backupScript = pkgs.writeShellScript "audiobookshelf-backup" ''
    #!/usr/bin/env bash
    set -euo pipefail

    BACKUP_DIR="/var/lib/audiobookshelf/backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="/var/log/audiobookshelf-guardian.log"

    log() {
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] BACKUP: $1" | tee -a "$LOG_FILE"
    }

    mkdir -p "$BACKUP_DIR"

    # Backup database
    if [ -f "/var/lib/audiobookshelf/config/absdatabase.sqlite" ]; then
      cp "/var/lib/audiobookshelf/config/absdatabase.sqlite" "$BACKUP_DIR/absdatabase_$TIMESTAMP.sqlite"
      log "Database backed up to $BACKUP_DIR/absdatabase_$TIMESTAMP.sqlite"

      # Keep only last 7 backups
      cd "$BACKUP_DIR" && ls -t absdatabase_*.sqlite | tail -n +8 | xargs -r rm
      log "Old backups cleaned up (keeping last 7)"
    fi
  '';
in {
  options.modules.services.audiobookshelfGuardian = {
    enable = lib.mkEnableOption "Audiobookshelf Guardian monitoring and protection";

    healthCheckInterval = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Health check interval in seconds (default: 5 minutes)";
    };

    enableAutoBackup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable automatic daily database backups";
    };
  };

  config = lib.mkIf cfg.enable {
    # Health check service that runs on startup
    # Note: Initial boot check is triggered by timer after 2min delay to avoid race condition
    systemd.services.audiobookshelf-health-check = {
      description = "Audiobookshelf Health Check";
      after = ["audiobookshelf.service" "cloudflared-tunnel.service" "docker.service"];
      wants = ["audiobookshelf.service"];
      # Removed from multi-user.target - timer handles startup check with delay

      serviceConfig = {
        Type = "oneshot";
        ExecStart = healthCheckScript;
        RemainAfterExit = false;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Periodic health check timer
    systemd.timers.audiobookshelf-health-check = {
      description = "Periodic Audiobookshelf Health Check";
      wantedBy = ["timers.target"];

      timerConfig = {
        # Wait 2 minutes after boot for container to fully start
        OnBootSec = "2min";
        OnUnitActiveSec = "${toString cfg.healthCheckInterval}s";
        Unit = "audiobookshelf-health-check.service";
      };
    };

    # Daily backup service
    systemd.services.audiobookshelf-backup = lib.mkIf cfg.enableAutoBackup {
      description = "Audiobookshelf Database Backup";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = backupScript;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    # Daily backup timer
    systemd.timers.audiobookshelf-backup = lib.mkIf cfg.enableAutoBackup {
      description = "Daily Audiobookshelf Backup";
      wantedBy = ["timers.target"];

      timerConfig = {
        OnCalendar = "daily";
        OnBootSec = "30min";
        Unit = "audiobookshelf-backup.service";
      };
    };

    # Create log file and backup directory
    systemd.tmpfiles.rules = [
      "f /var/log/audiobookshelf-guardian.log 0644 root root -"
      "d /var/lib/audiobookshelf/backups 0755 root root -"
    ];

    # Install required packages
    environment.systemPackages = with pkgs; [
      curl
      docker
    ];
  };
}
