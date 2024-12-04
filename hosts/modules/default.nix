# ~/NixOS/hosts/modules/default.nix
{
  imports = [
    ./desktop
    ./virtualization
    ./networking
    ./home
  ];
}
