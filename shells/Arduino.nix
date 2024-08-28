{ pkgs ? import <nixpkgs> { } }:

with pkgs;

mkShell {
  buildInputs = [
    arduino
    #gnumake # upload with Makefile
    #screen # serial console
  ];
}
