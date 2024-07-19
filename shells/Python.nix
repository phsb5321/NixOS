{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Python
    python3
    poetry

    # Virtual environment management
    python3Packages.virtualenv

    # Dependency management
    python3Packages.pip-tools

    # Linting and formatting
    python3Packages.flake8
    python3Packages.black
    python3Packages.isort

    # Type checking
    python3Packages.mypy

    # Testing
    python3Packages.pytest
    python3Packages.pytest-cov

    # Documentation
    python3Packages.sphinx

    # Build tools
    python3Packages.setuptools
    python3Packages.wheel
    python3Packages.twine

    # Debugging
    python3Packages.ipdb

    # Development tools
    pre-commit

    # Keep tkinter and related packages
    python3Packages.tkinter
    tcl
    tk
  ];

  shellHook = ''
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
