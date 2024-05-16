{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {

  buildInputs = [
    pkgs.bun
    pkgs.sqlite
  ];

  shellHook = ''
    export PATH=$PATH:${pkgs.bun}/bin
  '';
}
