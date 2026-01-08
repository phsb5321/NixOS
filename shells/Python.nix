{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: let
  # Import shared testing toolchain
  testingToolchain = import ./testing-toolchain.nix {inherit pkgs;};

  # Create a custom OpenCV package with GTK support
  opencvGtk = pkgs.opencv4.override {
    enableGtk3 = true;
    enableFfmpeg = true;
  };

  # Core Python packages for development
  pythonEnv = pkgs.python3.withPackages (ps:
    with ps; [
      # Interactive development
      ipython
      ipykernel
      jupyter
      notebook
      ipdb

      # Code quality
      mypy
      black
      ruff
      pytest
      pytest-cov

      # Documentation and packaging
      sphinx
      setuptools
      wheel
      twine

      # GUI support
      tkinter
    ]);

  # Helper functions for shell environment
  shellUtils = ''
        # Optional function to initialize a Python project structure
        # Call this explicitly when needed with: setup_python_project "project_name"
        setup_python_project() {
          local project_name=''${1:-"python-project"}

          echo "Creating Python project: $project_name"

          # Create project directories
          mkdir -p "$project_name"/{src,tests,docs}

          # Create basic project files
          cat > "$project_name/pyproject.toml" << 'EOF'
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

          # Create gitignore file
          cat > "$project_name/.gitignore" << 'EOF'
    # Python
    __pycache__/
    *.py[cod]
    *$py.class
    *.so
    .Python
    .venv/
    env/
    venv/
    ENV/

    # Testing
    .pytest_cache/
    .coverage
    htmlcov/
    .ruff_cache/

    # Packaging
    dist/
    build/
    *.egg-info/

    # IDE
    .idea/
    .vscode/
    *.swp
    *.swo
    EOF

          echo "Project structure created at: $project_name/"
          echo "To start working with this project: cd $project_name"
        }

        # Function to set up a virtual environment in the current directory
        setup_venv() {
          if [ ! -d .venv ]; then
            echo "Creating virtual environment with UV..."
            uv venv
            echo "Virtual environment created at .venv/"
          else
            echo "Virtual environment already exists"
          fi

          echo "To activate: source .venv/bin/activate"
        }

        # Function to display help information
        python_shell_help() {
          echo "🐍 Python Development Environment Help"
          echo "======================================="
          echo
          echo "Available functions:"
          echo "  setup_python_project [name] : Create a new Python project structure"
          echo "  setup_venv                  : Create a virtual environment in current directory"
          echo "  python_shell_help           : Display this help message"
          echo
          echo "Available commands:"
          echo "  uv pip install <package>    : Install a package using UV"
          echo "  ruff check .                : Run the Ruff linter"
          echo "  ruff format .               : Format code using Ruff"
          echo "  pytest                      : Run tests with pytest"
          echo "  pre-commit run --all-files  : Run pre-commit hooks on all files"
          echo
          echo "Environment information:"
          echo "  Python: $(python --version 2>/dev/null || echo 'Not activated')"
          echo "  UV: $(uv --version 2>/dev/null || echo 'Not found')"
          echo "  Ruff: $(ruff --version 2>/dev/null || echo 'Not found')"
        }

        # Display initial message
        echo "🐍 Python development environment ready"
        echo "Run 'python_shell_help' for available commands and functions"
  '';
in
  pkgs.mkShell {
    buildInputs = with pkgs; [
      # Python environment
      pythonEnv

      # Package and environment management
      uv
      pre-commit

      # Development and debugging tools
      ruff
      gdb

      # GUI and system dependencies
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

      # Graphics and media libraries
      glib
      gtk3
      gdk-pixbuf
      cairo
      pango
      ffmpeg
      opencvGtk

      # Database
      postgresql
    ] ++ testingToolchain.packages;

    shellHook = ''
      # Testing toolchain configuration
      ${testingToolchain.shellHook}

      # Set up library paths for external dependencies
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:${pkgs.glib}/lib:${pkgs.gtk3}/lib:${opencvGtk}/lib:${pkgs.postgresql}/lib:$LD_LIBRARY_PATH
      export TCLLIBPATH=${pkgs.tcl}/lib
      export TK_LIBRARY=${pkgs.tk}/lib
      export GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.cairo}/lib/girepository-1.0
      export PYTHONPATH=${opencvGtk}/lib/python3.12/site-packages:$PYTHONPATH
      export PATH=${pkgs.postgresql}/bin:$PATH

      # Import utility functions
      ${shellUtils}
    '';

    # Configure environment variables for OpenCV
    LIBGL_PATH = "${pkgs.libGL}/lib";
    LIBX11_PATH = "${pkgs.xorg.libX11}/lib";

    # Add pkg-config to find system libraries
    nativeBuildInputs = [pkgs.pkg-config];
  }
