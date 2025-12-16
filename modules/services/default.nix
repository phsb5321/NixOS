# ~/NixOS/modules/services/default.nix
# Modular service configurations
{
  imports = [
    ./syncthing.nix
    ./ssh.nix
    ./printing.nix
    ./docker.nix
<<<<<<< HEAD
=======
    # Server-specific services
    ./qbittorrent.nix
    ./plex.nix
    ./audiobookshelf.nix
    ./disk-guardian.nix
    ./cloudflare-tunnel.nix
    ./audiobookshelf-guardian.nix
>>>>>>> origin/host/server
  ];
}
