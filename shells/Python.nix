{ pkgs ? import <nixpkgs> { } }:

let
  pythonPackages = pkgs.python3Packages;
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

    # Add system libraries required by pandas
    stdenv.cc.cc.lib
    zlib
    openssl
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
    export TCLLIBPATH=${pkgs.tcl}/lib
    export TK_LIBRARY=${pkgs.tk}/lib

    # Create a virtual environment if it doesn't exist
    if [ ! -d ".venv" ]; then
      echo "Creating virtual environment..."
      python3 -m venv .venv
    fi

    # Activate the virtual environment
    source .venv/bin/activate

    # Upgrade pip, setuptools, and wheel
    pip install --upgrade pip setuptools wheel

    echo "Python development environment is ready!"
    echo "Activated virtual environment: $VIRTUAL_ENV"
  '';
}
