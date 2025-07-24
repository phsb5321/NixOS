# ~/NixOS/modules/hardware/default.nix
{
  imports = [
    ./nvidia.nix
    ./amd.nix
  ];
}
