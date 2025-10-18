# ~/NixOS/modules/services/default.nix
# Modular service configurations
{
  imports = [
    ./syncthing.nix
    ./ssh.nix
    ./printing.nix
    ./docker.nix
  ];
}
