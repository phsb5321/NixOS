{ pkgs ? import <nixpkgs> { } }:

let
  pythonPackages = pkgs.python3Packages;

  # Create a custom OpenCV package with GTK support
  opencvGtk = pkgs.opencv4.override {
    enableGtk3 = true;
    enableFfmpeg = true;
  };

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python
    python3
    poetry

    # Virtual environment management
    pythonPackages.virtualenv

    # Dependency management
    pythonPackages.pip-tools

    # Linting and formatting
    pythonPackages.flake8
    pythonPackages.black
    pythonPackages.isort

    # Type checking
    pythonPackages.mypy

    # Testing
    pythonPackages.pytest
    pythonPackages.pytest-cov

    # Documentation
    pythonPackages.sphinx

    # Build tools
    pythonPackages.setuptools
    pythonPackages.wheel
    pythonPackages.twine

    # Debugging
    pythonPackages.ipdb

    # Development tools
    pre-commit

    # Keep tkinter and related packages
    pythonPackages.tkinter
    tcl
    tk

    # Add system libraries required by numpy, opencv, and other dependencies
    stdenv.cc.cc.lib
    zlib
    openssl
    libGL
    libGLU
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libICE
    xorg.libSM
    glib
    gtk3
    gdk-pixbuf
    cairo
    pango
    ffmpeg
    opencvGtk
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:${pkgs.glib}/lib:${pkgs.gtk3}/lib:${opencvGtk}/lib:$LD_LIBRARY_PATH
    export TCLLIBPATH=${pkgs.tcl}/lib
    export TK_LIBRARY=${pkgs.tk}/lib
    export GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.cairo}/lib/girepository-1.0
    export PYTHONPATH=${opencvGtk}/lib/python3.12/site-packages:$PYTHONPATH

    # Create a virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "Creating virtual environment..."
      python3 -m venv .venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate

    # Upgrade pip, setuptools, and wheel
    pip install --upgrade pip setuptools wheel

    # Install or update project dependencies using Poetry
    if [ -f "pyproject.toml" ]; then
      echo "Installing project dependencies with Poetry..."
      poetry install
    else
      echo "No pyproject.toml found. Skipping dependency installation."
    fi

    echo "Python development environment is ready!"
    echo "Activated virtual environment: $VIRTUAL_ENV"
  '';

  # Set environment variables for OpenCV
  LIBGL_PATH = "${pkgs.libGL}/lib";
  LIBX11_PATH = "${pkgs.xorg.libX11}/lib";

  # Add pkg-config to find system libraries
  nativeBuildInputs = [ pkgs.pkg-config ];
}
