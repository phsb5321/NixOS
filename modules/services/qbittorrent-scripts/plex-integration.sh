#!/usr/bin/env bash
# qBittorrent + Plex Integration Script
# Automatically organizes media and updates Plex library
#
# Configure in qBittorrent Web UI:
# Tools → Options → Downloads → Run external program on torrent completion
# Command: /usr/local/bin/plex-integration.sh "%N" "%L" "%D" "%F" "%Z" "%I"
#
# Environment variables (set in systemd service or shell):
# PLEX_URL - Plex server URL (default: http://localhost:32400)
# PLEX_TOKEN - Plex authentication token (get from /etc/plex/token)
# PLEX_MOVIES_SECTION - Movies library section ID (default: 1)
# PLEX_TV_SECTION - TV Shows library section ID (default: 2)

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================

# Plex configuration
PLEX_URL="${PLEX_URL:-http://localhost:32400}"
PLEX_TOKEN="${PLEX_TOKEN:-}"
PLEX_MOVIES_SECTION="${PLEX_MOVIES_SECTION:-1}"
PLEX_TV_SECTION="${PLEX_TV_SECTION:-2}"

# Paths - Plex media directory on same filesystem as torrents (for hardlinks)
PLEX_MEDIA_ROOT="/mnt/torrents/plex"
MOVIES_DIR="${PLEX_MEDIA_ROOT}/Movies"
TV_DIR="${PLEX_MEDIA_ROOT}/TV Shows"
LOG_FILE="/var/log/plex-qbittorrent-integration.log"

# Webhook configuration
WEBHOOK_URL="${QBITTORRENT_WEBHOOK_URL:-}"
ENABLE_WEBHOOKS="${QBITTORRENT_NOTIFICATIONS:-true}"

# ============================================================================
# PARAMETERS FROM QBITTORRENT
# ============================================================================

TORRENT_NAME="$1"
CATEGORY="${2:-uncategorized}"
SAVE_PATH="$3"
CONTENT_PATH="$4"
SIZE_BYTES="$5"
INFO_HASH="$6"

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

# Convert bytes to human-readable format
human_size() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        printf "%.1fKB" "$(echo "scale=1; $bytes / 1024" | bc)"
    elif ((bytes < 1073741824)); then
        printf "%.1fMB" "$(echo "scale=1; $bytes / 1048576" | bc)"
    else
        printf "%.2fGB" "$(echo "scale=2; $bytes / 1073741824" | bc)"
    fi
}

SIZE_HUMAN=$(human_size "$SIZE_BYTES")

# Log function with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# ============================================================================
# MEDIA TYPE DETECTION
# ============================================================================

# Detect if content is a movie
is_movie() {
    local path="$1"
    local name="$2"

    # Check file extension
    if [[ "$path" =~ \.(mkv|mp4|avi|mov|wmv|m4v|mpg|mpeg)$ ]]; then
        # Check for year pattern indicating a movie (e.g., "Movie.Name.2007")
        if [[ "$name" =~ [.\-\ ](19[0-9]{2}|20[0-9]{2})[.\-\ ] ]]; then
            return 0
        fi

        # Check category
        if [[ "$CATEGORY" =~ ^(movie|movies|film|films)$ ]]; then
            return 0
        fi

        # If it's a single video file over 500MB, likely a movie
        if [[ -f "$path" ]]; then
            local size_mb=$((SIZE_BYTES / 1048576))
            if ((size_mb > 500)); then
                return 0
            fi
        fi
    fi

    return 1
}

# Detect if content is a TV show
is_tv_show() {
    local name="$1"

    # Check for season/episode patterns
    if [[ "$name" =~ [Ss][0-9]{2}[Ee][0-9]{2} ]] || \
       [[ "$name" =~ [0-9]{1,2}x[0-9]{2} ]] || \
       [[ "$CATEGORY" =~ ^(tv|tvshows|series|shows)$ ]]; then
        return 0
    fi

    return 1
}

# ============================================================================
# PLEX INTEGRATION FUNCTIONS
# ============================================================================

# Load Plex token from file
load_plex_token() {
    if [[ -z "$PLEX_TOKEN" ]] && [[ -f "/etc/plex/token" ]]; then
        PLEX_TOKEN=$(cat /etc/plex/token | tr -d '\n\r ')
    fi
}

# Scan Plex library section
scan_plex_library() {
    local section_id="$1"
    local section_name="$2"

    if [[ -z "$PLEX_TOKEN" ]]; then
        log "⚠️  Plex token not configured, skipping library scan"
        log "Run: /etc/plex/get-token.sh for instructions"
        return 0
    fi

    log "📺 Triggering Plex scan for section $section_id ($section_name)..."

    local response
    response=$(curl -s -w "\n%{http_code}" \
        -X GET "${PLEX_URL}/library/sections/${section_id}/refresh?X-Plex-Token=${PLEX_TOKEN}" 2>&1)

    local http_code=$(echo "$response" | tail -1)

    if [[ "$http_code" == "200" ]]; then
        log "✅ Plex library scan triggered successfully"
    else
        log "❌ Failed to trigger Plex scan (HTTP $http_code)"
    fi
}

# ============================================================================
# FILE ORGANIZATION FUNCTIONS
# ============================================================================

# Create hardlink in Plex directory
create_plex_hardlink() {
    local source="$1"
    local target_dir="$2"
    local media_type="$3"

    log "🔗 Creating hardlinks in Plex $media_type library..."

    # Ensure target directory exists
    mkdir -p "$target_dir"

    if [[ -d "$source" ]]; then
        # Multi-file torrent (movie folder or TV season)
        local folder_name=$(basename "$source")
        local target="$target_dir/$folder_name"

        log "   Source: $source"
        log "   Target: $target"

        # Use cp -al to create hardlinks recursively
        if cp -aln "$source" "$target" 2>&1 | tee -a "$LOG_FILE"; then
            log "✅ Hardlinks created successfully"
            return 0
        else
            log "⚠️  Hardlink failed, trying regular copy..."
            if cp -r "$source" "$target" 2>&1 | tee -a "$LOG_FILE"; then
                log "✅ Files copied (seeding will be affected)"
                return 0
            else
                log "❌ Failed to copy files"
                return 1
            fi
        fi
    elif [[ -f "$source" ]]; then
        # Single file torrent
        local filename=$(basename "$source")
        local target="$target_dir/$filename"

        log "   Source: $source"
        log "   Target: $target"

        # Create hardlink for single file
        if ln "$source" "$target" 2>&1 | tee -a "$LOG_FILE"; then
            log "✅ Hardlink created successfully"
            return 0
        else
            log "⚠️  Hardlink failed, trying copy..."
            if cp "$source" "$target" 2>&1 | tee -a "$LOG_FILE"; then
                log "✅ File copied (seeding will be affected)"
                return 0
            else
                log "❌ Failed to copy file"
                return 1
            fi
        fi
    else
        log "❌ Source path doesn't exist: $source"
        return 1
    fi
}

# ============================================================================
# WEBHOOK NOTIFICATION
# ============================================================================

send_webhook() {
    local title="$1"
    local description="$2"
    local color="$3"
    local extra_fields="${4:-}"

    if [[ -z "$WEBHOOK_URL" ]] || [[ "$ENABLE_WEBHOOKS" != "true" ]]; then
        return 0
    fi

    local payload
    payload=$(cat <<EOF
{
  "embeds": [{
    "title": "${title}",
    "description": "${description}",
    "color": ${color},
    "fields": [
      {
        "name": "📦 Size",
        "value": "${SIZE_HUMAN}",
        "inline": true
      },
      {
        "name": "📁 Category",
        "value": "${CATEGORY}",
        "inline": true
      },
      {
        "name": "💾 Path",
        "value": "\`${CONTENT_PATH}\`",
        "inline": false
      }
      ${extra_fields}
    ],
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  }]
}
EOF
)

    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        >> "$LOG_FILE" 2>&1 || log "Failed to send webhook"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

main() {
    log "=========================================="
    log "🎬 Torrent completed: $TORRENT_NAME"
    log "📁 Category: $CATEGORY"
    log "📦 Size: $SIZE_HUMAN ($SIZE_BYTES bytes)"
    log "💾 Save path: $SAVE_PATH"
    log "📂 Content path: $CONTENT_PATH"
    log "🔑 Info hash: $INFO_HASH"
    log "=========================================="

    # Load Plex token if available
    load_plex_token

    # Detect media type and organize
    local media_type=""
    local plex_section=""
    local organized=false

    if is_movie "$CONTENT_PATH" "$TORRENT_NAME"; then
        media_type="Movie"
        plex_section="$PLEX_MOVIES_SECTION"

        log "🎬 Detected: Movie"

        if create_plex_hardlink "$CONTENT_PATH" "$MOVIES_DIR" "Movies"; then
            organized=true
            log "✅ Movie added to Plex library"

            # Trigger Plex scan
            scan_plex_library "$plex_section" "Movies"

            # Send success notification
            send_webhook \
                "🎬 Movie Added to Plex" \
                "**${TORRENT_NAME}**" \
                "3447003" \
                ',{"name": "📺 Plex", "value": "Added to Movies library", "inline": false}'
        fi

    elif is_tv_show "$TORRENT_NAME"; then
        media_type="TV Show"
        plex_section="$PLEX_TV_SECTION"

        log "📺 Detected: TV Show"

        if create_plex_hardlink "$CONTENT_PATH" "$TV_DIR" "TV Shows"; then
            organized=true
            log "✅ TV show added to Plex library"

            # Trigger Plex scan
            scan_plex_library "$plex_section" "TV Shows"

            # Send success notification
            send_webhook \
                "📺 TV Show Added to Plex" \
                "**${TORRENT_NAME}**" \
                "3447003" \
                ',{"name": "📺 Plex", "value": "Added to TV Shows library", "inline": false}'
        fi

    else
        log "ℹ️  Media type not detected or not supported"

        # Send generic completion notification
        if [[ "$ENABLE_WEBHOOKS" == "true" ]]; then
            send_webhook \
                "✅ Download Complete" \
                "**${TORRENT_NAME}**" \
                "3066993"
        fi
    fi

    # Log final status
    if [[ "$organized" == true ]]; then
        log "=========================================="
        log "✅ SUCCESS: $media_type organized and Plex updated"
        log "=========================================="
    else
        log "=========================================="
        log "ℹ️  Torrent completed but not organized for Plex"
        log "=========================================="
    fi
}

# Run main function
main

# Exit successfully
exit 0
