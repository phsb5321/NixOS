{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.nodejs_22
    pkgs.openssl
  ];


  shellHook = ''
    export PATH=$PATH:$(npm bin)
  '';
}
