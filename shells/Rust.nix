# ~/NixOS/shells/Rust.nix
#
# Rust development shell with Tauri 2.x support for NixOS
#
# Features:
# - Full Rust toolchain (rustc, cargo, rustfmt, rust-analyzer)
# - Tauri 2.x dependencies (WebKitGTK 4.1, libsoup 3.0, GTK3)
# - NixOS-specific environment variables for runtime library discovery
# - Testing toolchain (Playwright, browsers) via testing-toolchain.nix
#
# Usage: nix-shell shells/Rust.nix
#
# Key environment variables set:
# - LD_LIBRARY_PATH: Runtime library paths for WebKit/GTK
# - XDG_DATA_DIRS: GSettings schemas for GTK dialogs
# - OPENSSL_DIR: OpenSSL detection for Rust builds
# - LIBCLANG_PATH: For bindgen (native-tts feature)
#
{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: let
  # Import shared testing toolchain
  testingToolchain = import ./testing-toolchain.nix {inherit pkgs;};

  # Libraries needed at runtime for Tauri 2.x / WebKit
  # These are used for LD_LIBRARY_PATH to ensure runtime library discovery on NixOS
  tauriLibraries = with pkgs; [
    webkitgtk_4_1
    libsoup_3
    gtk3
    glib
    gdk-pixbuf
    cairo
    pango
    harfbuzz
    librsvg
    at-spi2-atk
    dbus
    openssl
    alsa-lib  # Audio playback (rodio)
  ];
in
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

      # Build essentials
      gcc

      # Version control
      git

      # Tauri 2.x WebKit dependencies
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

      # Tauri 2.x system integration
      dbus
      gsettings-desktop-schemas
      glib-networking

      # For native-tts feature (speech-dispatcher bindgen)
      llvmPackages.libclang
      clang

      # Audio playback (rodio/ALSA)
      alsa-lib
    ] ++ testingToolchain.packages;

    shellHook = ''
      # Testing toolchain configuration
      ${testingToolchain.shellHook}

      # Set up Rust-related environment variables
      export RUST_BACKTRACE=1

      # Tauri 2.x / WebKit runtime library discovery (NixOS-specific)
      # Required because NixOS doesn't use standard library paths
      export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath tauriLibraries}:$LD_LIBRARY_PATH

      # OpenSSL detection for Rust builds (openssl-sys crate)
      export OPENSSL_DIR=${pkgs.openssl.dev}

      # GSettings schemas for GTK dialogs (file open/save dialogs)
      # Required for Tauri's dialog.open() API to work without XDG errors
      export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS

      # For bindgen (speech-dispatcher-sys, native-tts feature)
      export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"

      echo "Rust + Tauri 2.x development environment is ready!"
      echo "Rust version: $(rustc --version)"
      echo "Cargo version: $(cargo --version)"
      echo "Tauri CLI: $(cargo tauri --version 2>/dev/null || echo 'available via cargo-tauri')"
      echo ""
      echo "Run 'test-toolchain-diagnose' to verify testing setup"
    '';
  }
