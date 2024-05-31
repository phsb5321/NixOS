{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python312Packages.pyttsx3
  ];

}
