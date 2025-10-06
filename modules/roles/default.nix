# ~/NixOS/modules/roles/default.nix
# Role-based configuration modules
{
  imports = [
    ./desktop.nix
    ./laptop.nix
    ./server.nix
    ./minimal.nix
  ];
}
