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
  name = "python-dev-env";
  buildInputs = with pkgs; [
    python3
    python3Packages.venvShellHook
    poetry
    pre-commit
    autoPatchelfHook
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

  propagatedBuildInputs = [ pkgs.stdenv.cc.cc.lib ];

  venvDir = "./.venv";

  postVenvCreation = ''
    unset SOURCE_DATE_EPOCH
    pip install -U pip setuptools wheel
    pip install flake8 black isort mypy pytest pytest-cov sphinx twine ipdb
    if [ -f "pyproject.toml" ]; then
      poetry install
    elif [ -f "requirements.txt" ]; then
      pip install -r requirements.txt
    fi
    autoPatchelf $venvDir
  '';

  shellHook = ''
    export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.zlib}/lib:${pkgs.libGL}/lib:${pkgs.glib}/lib:${pkgs.gtk3}/lib:${opencvGtk}/lib:${pkgs.postgresql}/lib:$LD_LIBRARY_PATH
    export TCLLIBPATH=${pkgs.tcl}/lib
    export TK_LIBRARY=${pkgs.tk}/lib
    export GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.glib}/lib/girepository-1.0:${pkgs.pango}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.cairo}/lib/girepository-1.0
    export PYTHONPATH=${opencvGtk}/lib/python3.12/site-packages:$PYTHONPATH
    export PATH=${pkgs.postgresql}/bin:$PATH

    # Set SOURCE_DATE_EPOCH so that we can use python wheels
    export SOURCE_DATE_EPOCH=315532800

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
