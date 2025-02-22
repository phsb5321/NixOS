# ~/NixOS/shells/Rust.nix
{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    gobject-introspection
    cargo
    cargo-tauri
    nodejs
  ];

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

    at-spi2-atk
    atkmm
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    librsvg
    libsoup_3
    pango
    webkitgtk_4_1
    openssl
  ];

  shellHook = ''
    # Set up Rust-related environment variables
    export RUST_BACKTRACE=1

    echo "Minimal Rust development environment is ready!"
    echo "Rust version: $(rustc --version)"
    echo "Cargo version: $(cargo --version)"
  '';
}
