# ~/NixOS/modules/default.nix
{
  imports = [
    ./desktop
    ./virtualization
    ./networking
    ./home
    ./core
    ./home-server
  ];
}
