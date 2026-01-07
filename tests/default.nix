# ~/NixOS/tests/default.nix
# Testing infrastructure
{...}: {
  imports = [
    ./formatting.nix
    ./boot-test.nix
  ];
}
