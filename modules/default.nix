# ~/NixOS/modules/default.nix
{
  imports = [
    ./core
    ./packages
    ./networking
    ./desktop
  ];
}
