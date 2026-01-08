# qBittorrent Service Module
# Headless torrent client with web UI, automation, and webhook support
#
# This module has been split into sub-modules for maintainability:
# - options.nix: All option declarations
# - config.nix: Configuration file generation
# - service.nix: Systemd service, user/group, filesystem, firewall
# - webhook.nix: Webhook script for torrent completion
# - integration.nix: Plex monitor daemon integration
{...}: {
  imports = [
    ./options.nix
    ./config.nix
    ./service.nix
    ./webhook.nix
    ./integration.nix
  ];
}
