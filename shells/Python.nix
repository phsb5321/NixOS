{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.python3Packages.tkinter
    pkgs.python3Packages.pandas
    pkgs.python3Packages.openpyxl
    pkgs.tcl
    pkgs.tk
  ];

  shellHook = ''
    export TCLLIBPATH=${pkgs.tcl}/lib
    export TK_LIBRARY=${pkgs.tk}/lib
  '';
}
