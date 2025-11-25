# ~/NixOS/tests/default.nix
# Testing infrastructure
{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./formatting.nix
    ./boot-test.nix
  ];
}
