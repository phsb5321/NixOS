{ pkgs ? import <nixpkgs> { } }:

let
  pythonPackages = pkgs.python3Packages;

  # Create a custom OpenCV package with GTK support
  opencvGtk = pkgs.opencv4.override {
    enableGtk3 = true;
    enableFfmpeg = true;
  };

  commonPythonEnv = pkgs.python3.withPackages (ps: with ps; [
    jupyter
    notebook
    ipykernel
    virtualenv
    pip-tools
    flake8
    black
    isort
    mypy
    pytest
    pytest-cov
    sphinx
    setuptools
    wheel
    twine
    ipdb
    tkinter
  ]);

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    commonPythonEnv
    poetry
    pre-commit
    tcl
    tk
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
    postgresql
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:${pkgs.glib}/lib:${pkgs.gtk3}/lib:${opencvGtk}/lib:${pkgs.postgresql}/lib:$LD_LIBRARY_PATH
    export TCLLIBPATH=${pkgs.tcl}/lib
    export TK_LIBRARY=${pkgs.tk}/lib
    export GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.cairo}/lib/girepository-1.0
    export PYTHONPATH=${opencvGtk}/lib/python3.12/site-packages:$PYTHONPATH
    export PATH=${pkgs.postgresql}/bin:$PATH

    # Create a virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "Creating virtual environment..."
      ${commonPythonEnv}/bin/python -m venv .venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate

    # Upgrade pip, setuptools, and wheel
    pip install --upgrade pip setuptools wheel

    # Set up Poetry configuration
    export POETRY_CONFIG_DIR="$PWD/.poetry"
    export POETRY_CACHE_DIR="$PWD/.poetry/cache"
    export POETRY_VIRTUALENVS_IN_PROJECT=true
    export POETRY_VIRTUALENVS_PATH="$PWD/.venv"

    # Install or update project dependencies using Poetry
    if [ -f "pyproject.toml" ]; then
      echo "Installing project dependencies with Poetry..."
      poetry install
    else
      echo "No pyproject.toml found. Skipping dependency installation."
    fi

    echo "Python development environment is ready!"
    echo "Activated virtual environment: $VIRTUAL_ENV"
    echo "Poetry root: $PWD"
  '';

  # Set environment variables for OpenCV
  LIBGL_PATH = "${pkgs.libGL}/lib";
  LIBX11_PATH = "${pkgs.xorg.libX11}/lib";

  # Add pkg-config to find system libraries
  nativeBuildInputs = [ pkgs.pkg-config ];
}
