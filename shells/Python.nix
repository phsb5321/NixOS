{pkgs ? import <nixpkgs> {}}: let
  # Create a custom OpenCV package with GTK support
  opencvGtk = pkgs.opencv4.override {
    enableGtk3 = true;
    enableFfmpeg = true;
  };

  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      ipython
      ipykernel
      jupyter
      notebook
      mypy
      black
      ruff
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
      pythonEnv

      # Package Management
      uv

      # Development Tools
      ruff
      pre-commit

      # GUI and System Dependencies
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
            # Set up library paths
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:${pkgs.glib}/lib:${pkgs.gtk3}/lib:${opencvGtk}/lib:${pkgs.postgresql}/lib:$LD_LIBRARY_PATH
            export TCLLIBPATH=${pkgs.tcl}/lib
            export TK_LIBRARY=${pkgs.tk}/lib
            export GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.cairo}/lib/girepository-1.0
            export PYTHONPATH=${opencvGtk}/lib/python3.12/site-packages:$PYTHONPATH
            export PATH=${pkgs.postgresql}/bin:$PATH

            # Create and configure local environment
            if [ ! -f pyproject.toml ]; then
              echo "Initializing new Python project..."
              cat > pyproject.toml << EOF
      [project]
      name = "python-project"
      version = "0.1.0"
      description = "A Python project"
      requires-python = ">=3.12"

      [tool.ruff]
      line-length = 88
      target-version = "py312"
      select = [
          "E",   # pycodestyle
          "F",   # pyflakes
          "I",   # isort
          "N",   # pep8-naming
          "UP",  # pyupgrade
      ]

      [tool.ruff.format]
      quote-style = "double"
      indent-style = "space"
      skip-magic-trailing-comma = false
      line-ending = "auto"

      [tool.pytest.ini_options]
      minversion = "6.0"
      addopts = "-ra -q"
      testpaths = [
          "tests",
      ]
      EOF

              # Initialize git repository if it doesn't exist
              if [ ! -d .git ]; then
                git init
                echo "__pycache__/" >> .gitignore
                echo "*.pyc" >> .gitignore
                echo ".pytest_cache/" >> .gitignore
                echo ".ruff_cache/" >> .gitignore
                echo ".coverage" >> .gitignore
                echo "dist/" >> .gitignore
                echo "*.egg-info/" >> .gitignore
              fi

              # Create initial project structure
              mkdir -p src/python_project tests docs
            fi

            # Initialize UV environment
            if [ ! -d .venv ]; then
              echo "Creating virtual environment with UV..."
              uv venv
            fi

            # Activate virtual environment
            source .venv/bin/activate

            # Install development dependencies using UV
            if [ -f requirements.txt ]; then
              echo "Installing dependencies with UV..."
              uv pip install -r requirements.txt
            fi

            # Setup pre-commit hooks if not already configured
            if [ ! -f .pre-commit-config.yaml ]; then
              cat > .pre-commit-config.yaml << EOF
      repos:
      -   repo: https://github.com/astral-sh/ruff-pre-commit
          rev: v0.1.6
          hooks:
          -   id: ruff
              args: [ --fix ]
          -   id: ruff-format
      EOF
              pre-commit install
            fi

            # Display environment information
            echo "🐍 Python development environment activated!"
            echo "📦 Package management: UV $(uv --version)"
            echo "🔍 Linting: Ruff $(ruff --version)"
            echo "🧪 Testing: pytest $(pytest --version | cut -d' ' -f2)"
            echo "📝 Virtual environment: .venv"
            echo
            echo "Available commands:"
            echo "- uv pip install <package>  : Install a package"
            echo "- ruff check .              : Run linter"
            echo "- ruff format .             : Format code"
            echo "- pytest                    : Run tests"
            echo "- pre-commit run --all-files: Run all pre-commit hooks"
    '';

    # Configure environment variables for OpenCV
    LIBGL_PATH = "${pkgs.libGL}/lib";
    LIBX11_PATH = "${pkgs.xorg.libX11}/lib";

    # Add pkg-config to find system libraries
    nativeBuildInputs = [pkgs.pkg-config];
  }
