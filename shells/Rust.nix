{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core Rust tools
    rustc
    cargo
    rustfmt
    rust-analyzer
    rustfmt

    # Build essentials
    gcc

    # Version control
    git
  ];

  shellHook = ''
    # Set up Rust-related environment variables
    export RUST_BACKTRACE=1

    echo "Minimal Rust development environment is ready!"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
  '';
}
