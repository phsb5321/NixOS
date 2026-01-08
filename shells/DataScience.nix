{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: let
  # Import shared testing toolchain
  testingToolchain = import ./testing-toolchain.nix {inherit pkgs;};

  # Python environment with comprehensive data science stack
  dataScienceEnv = pkgs.python3.withPackages (ps:
    with ps; [
      # Jupyter environment
      ipython
      ipykernel
      jupyterlab
      notebook

      # Core data science libraries
      numpy
      pandas
      scipy

      # Visualization
      matplotlib
      seaborn
      plotly

      # Machine learning
      scikit-learn

      # Data manipulation and analysis
      polars
      pyarrow

      # Statistics
      statsmodels

      # Development tools
      ipdb
      black
      ruff
      pytest

      # Utilities
      requests
      python-dotenv
      tqdm
    ]);

  # Helper functions for data science workflows
  shellUtils = ''
    # Function to start Jupyter Lab
    start_jupyter() {
      echo "🚀 Starting Jupyter Lab..."
      echo "Access at: http://localhost:8888"
      jupyter lab --no-browser
    }

    # Function to start Jupyter Notebook
    start_notebook() {
      echo "📓 Starting Jupyter Notebook..."
      echo "Access at: http://localhost:8888"
      jupyter notebook --no-browser
    }

    # Function to display available packages
    show_packages() {
      echo "📦 Available Data Science Packages"
      echo "===================================="
      echo
      echo "Core Libraries:"
      echo "  • NumPy:        $(python -c 'import numpy; print(numpy.__version__)' 2>/dev/null || echo 'Not found')"
      echo "  • Pandas:       $(python -c 'import pandas; print(pandas.__version__)' 2>/dev/null || echo 'Not found')"
      echo "  • SciPy:        $(python -c 'import scipy; print(scipy.__version__)' 2>/dev/null || echo 'Not found')"
      echo
      echo "Visualization:"
      echo "  • Matplotlib:   $(python -c 'import matplotlib; print(matplotlib.__version__)' 2>/dev/null || echo 'Not found')"
      echo "  • Seaborn:      $(python -c 'import seaborn; print(seaborn.__version__)' 2>/dev/null || echo 'Not found')"
      echo "  • Plotly:       $(python -c 'import plotly; print(plotly.__version__)' 2>/dev/null || echo 'Not found')"
      echo
      echo "Machine Learning:"
      echo "  • Scikit-learn: $(python -c 'import sklearn; print(sklearn.__version__)' 2>/dev/null || echo 'Not found')"
      echo
      echo "Data Formats:"
      echo "  • Polars:       $(python -c 'import polars; print(polars.__version__)' 2>/dev/null || echo 'Not found')"
      echo "  • PyArrow:      $(python -c 'import pyarrow; print(pyarrow.__version__)' 2>/dev/null || echo 'Not found')"
    }

    # Function to display help
    ds_help() {
      echo "🔬 Data Science Environment Help"
      echo "================================="
      echo
      echo "Quick Start Commands:"
      echo "  start_jupyter        : Launch Jupyter Lab (recommended)"
      echo "  start_notebook       : Launch Jupyter Notebook (classic)"
      echo "  show_packages        : Display installed package versions"
      echo "  ds_help              : Display this help message"
      echo
      echo "Jupyter Commands:"
      echo "  jupyter lab          : Start Jupyter Lab manually"
      echo "  jupyter notebook     : Start Jupyter Notebook manually"
      echo "  jupyter --version    : Check Jupyter version"
      echo
      echo "Python REPL:"
      echo "  ipython              : Start IPython interactive shell"
      echo "  python               : Start standard Python REPL"
      echo
      echo "VS Code Integration:"
      echo "  • Open VS Code in this directory: code ."
      echo "  • VS Code will detect this Python environment"
      echo "  • Data Wrangler extension will work automatically"
      echo "  • Jupyter notebooks (.ipynb) will use this kernel"
      echo
      echo "Environment Info:"
      echo "  Python: $(python --version)"
      echo "  Jupyter: $(jupyter --version 2>&1 | head -n1)"
    }

    # Display welcome message
    echo "🔬 Data Science environment ready"
    echo "Run 'ds_help' for available commands"
    echo
  '';
in
  pkgs.mkShell {
    buildInputs = with pkgs;
      [
        # Python environment with data science packages
        dataScienceEnv

        # Additional system tools
        pkg-config

        # Graphics libraries (for matplotlib, etc.)
        libGL
        libGLU
        xorg.libX11
        xorg.libXext

        # For rendering
        cairo
        pango
        gdk-pixbuf

        # Compression libraries (for pandas)
        zlib
        bzip2
        xz
      ]
      ++ testingToolchain.packages;

    shellHook = ''
      # Testing toolchain configuration
      ${testingToolchain.shellHook}

      # Set up library paths
      export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:$LD_LIBRARY_PATH

      # Improve matplotlib backend support
      export MPLBACKEND=TkAgg

      # Import utility functions
      ${shellUtils}
    '';

    # Environment variables
    JUPYTER_CONFIG_DIR = "./.jupyter";
    JUPYTER_DATA_DIR = "./.jupyter/data";

    # Ensure pkg-config can find dependencies
    nativeBuildInputs = [pkgs.pkg-config];
  }
