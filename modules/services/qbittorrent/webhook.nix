# qBittorrent Webhook Integration
# Handles webhook script generation for torrent completion notifications
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.services.qbittorrent;

  # Default webhook script
  defaultWebhookScript = pkgs.writeShellScript "qbittorrent-webhook" ''
    #!/usr/bin/env bash
    # Default webhook script for qBittorrent
    # Called on torrent completion with parameters from qBittorrent

    # qBittorrent parameters:
    # %N - Torrent name
    # %L - Category
    # %G - Tags (separated by comma)
    # %F - Content path (same as root path for multi-file torrent)
    # %R - Root path (first torrent subdirectory path)
    # %D - Save path
    # %C - Number of files
    # %Z - Torrent size (bytes)
    # %T - Current tracker
    # %I - Info hash v1
    # %J - Info hash v2
    # %K - Torrent ID

    TORRENT_NAME="$1"
    CATEGORY="$2"
    SAVE_PATH="$3"
    CONTENT_PATH="$4"
    TORRENT_SIZE="$5"
    INFO_HASH="$6"

    echo "[$(date)] Torrent completed: $TORRENT_NAME" >> /var/log/qbittorrent-webhook.log

    ${lib.optionalString (cfg.webhook.url != "") ''
      # Send webhook notification
      ${pkgs.curl}/bin/curl -X POST "${cfg.webhook.url}" \
        -H "Content-Type: application/json" \
        -d "{\"content\": \"✅ Torrent completed: **$TORRENT_NAME** ($TORRENT_SIZE bytes)\"}" \
        >> /var/log/qbittorrent-webhook.log 2>&1
    ''}
  '';
in {
  # Set default webhook script if not specified
  options.modules.services.qbittorrent.webhook.script = lib.mkDefault defaultWebhookScript;
}
