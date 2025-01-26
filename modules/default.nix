# ~/NixOS/modules/default.nix
{
  imports = [
    ./desktop
    ./networking
    ./home
    ./core
    ./home-server
  ];
}
