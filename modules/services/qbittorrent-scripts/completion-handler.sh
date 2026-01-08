#!/usr/bin/env bash
# qBittorrent Advanced Completion Handler
# This script is called when a torrent completes downloading
#
# Place this in your qBittorrent settings:
# Tools → Options → Downloads → Run external program on torrent completion
# Command: /path/to/completion-handler.sh "%N" "%L" "%D" "%F" "%Z" "%I"
#
# Parameters from qBittorrent:
# $1 (%N) - Torrent name
# $2 (%L) - Category
# $3 (%D) - Save path
# $4 (%F) - Content path (root path for multi-file torrents)
# $5 (%Z) - Torrent size (bytes)
# $6 (%I) - Info hash v1

set -euo pipefail

# Configuration
WEBHOOK_URL="${QBITTORRENT_WEBHOOK_URL:-}"
LOG_FILE="/var/log/qbittorrent-completion.log"
ORGANIZED_DIR="/mnt/torrents/organized"
ENABLE_HARDLINKS="${QBITTORRENT_HARDLINKS:-true}"
ENABLE_NOTIFICATIONS="${QBITTORRENT_NOTIFICATIONS:-true}"

# Extract parameters
TORRENT_NAME="$1"
CATEGORY="${2:-uncategorized}"
SAVE_PATH="$3"
CONTENT_PATH="$4"
SIZE_BYTES="$5"
INFO_HASH="$6"

# Convert size to human-readable format
human_size() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes}B"
    elif ((bytes < 1048576)); then
        echo "$((bytes / 1024))KB"
    elif ((bytes < 1073741824)); then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

SIZE_HUMAN=$(human_size "$SIZE_BYTES")

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Send Discord/Slack webhook notification
send_webhook() {
    local title="$1"
    local description="$2"
    local color="$3"

    if [[ -z "$WEBHOOK_URL" ]]; then
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
        "name": "Size",
        "value": "${SIZE_HUMAN}",
        "inline": true
      },
      {
        "name": "Category",
        "value": "${CATEGORY}",
        "inline": true
      },
      {
        "name": "Path",
        "value": "\`${CONTENT_PATH}\`",
        "inline": false
      }
    ],
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  }]
}
EOF
)

    curl -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        >> "$LOG_FILE" 2>&1 || log "Failed to send webhook notification"
}

# Organize files by category
organize_files() {
    local category="$1"
    local source="$2"

    # Skip if organization is disabled
    if [[ "${ENABLE_HARDLINKS}" != "true" ]]; then
        return 0
    fi

    # Create category directory
    local target_dir="${ORGANIZED_DIR}/${category}"
    mkdir -p "$target_dir"

    # Create hard links instead of moving (preserves seeding)
    if [[ -d "$source" ]]; then
        # Multi-file torrent
        log "Creating hard links for directory: $source"
        cp -al "$source" "$target_dir/" 2>&1 | tee -a "$LOG_FILE" || {
            log "Failed to create hard links, trying copy..."
            cp -r "$source" "$target_dir/" 2>&1 | tee -a "$LOG_FILE"
        }
    else
        # Single file torrent
        log "Creating hard link for file: $source"
        cp -al "$source" "$target_dir/" 2>&1 | tee -a "$LOG_FILE" || {
            log "Failed to create hard link, trying copy..."
            cp "$source" "$target_dir/" 2>&1 | tee -a "$LOG_FILE"
        }
    fi
}

# Extract media info for movies/TV shows
extract_media_info() {
    local path="$1"

    # Check if it looks like a movie or TV show
    if [[ "$path" =~ \.(mkv|mp4|avi|mov|wmv)$ ]]; then
        log "Media file detected: $path"

        # You can integrate with tools like:
        # - FileBot for automatic renaming and organization
        # - MediaInfo for technical details
        # - Plex/Jellyfin API for library updates

        # Example: Update Plex library
        # curl -X POST "http://plex-server:32400/library/sections/1/refresh?X-Plex-Token=YOUR_TOKEN"
    fi
}

# Main execution
main() {
    log "=========================================="
    log "Torrent completed: $TORRENT_NAME"
    log "Category: $CATEGORY"
    log "Size: $SIZE_HUMAN ($SIZE_BYTES bytes)"
    log "Save path: $SAVE_PATH"
    log "Content path: $CONTENT_PATH"
    log "Info hash: $INFO_HASH"
    log "=========================================="

    # Send completion notification
    if [[ "${ENABLE_NOTIFICATIONS}" == "true" ]]; then
        send_webhook \
            "✅ Download Complete" \
            "**${TORRENT_NAME}**" \
            "3066993" # Green color
    fi

    # Organize files by category
    if [[ -n "$CATEGORY" && "$CATEGORY" != "uncategorized" ]]; then
        log "Organizing files into category: $CATEGORY"
        organize_files "$CATEGORY" "$CONTENT_PATH"
    fi

    # Extract media information if applicable
    extract_media_info "$CONTENT_PATH"

    # Custom post-processing based on category
    case "$CATEGORY" in
        "movies")
            log "Processing movie: $TORRENT_NAME"
            # Add movie-specific processing here
            ;;
        "tv"|"tvshows")
            log "Processing TV show: $TORRENT_NAME"
            # Add TV show-specific processing here
            ;;
        "music")
            log "Processing music: $TORRENT_NAME"
            # Add music-specific processing here
            ;;
        "books"|"ebooks")
            log "Processing book: $TORRENT_NAME"
            # Add book-specific processing here
            ;;
        *)
            log "No specific processing for category: $CATEGORY"
            ;;
    esac

    log "Completion handling finished successfully"
}

# Run main function
main

# Exit successfully
exit 0
