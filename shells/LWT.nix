{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.bun
    pkgs.sqlite
    pkgs.corepack_22
  ];

  shellHook = ''
    export PNPM_HOME="$HOME/.local/share/pnpm"
    export PATH=$PNPM_HOME/bin:$PATH
    pnpm setup
    export PATH=$PATH:${pkgs.bun}/bin
  '';
}
