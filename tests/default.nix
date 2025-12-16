# ~/NixOS/tests/default.nix
# Testing infrastructure
<<<<<<< HEAD
{ pkgs, lib, ... }:

{
=======
{
  pkgs,
  lib,
  ...
}: {
>>>>>>> origin/host/server
  imports = [
    ./formatting.nix
    ./boot-test.nix
  ];
}
