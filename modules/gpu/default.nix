# ~/NixOS/modules/gpu/default.nix
# GPU abstraction modules
{
  imports = [
    ./amd.nix
    ./hybrid.nix
    ./intel.nix
    ./nvidia.nix
  ];
}
