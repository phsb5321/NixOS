{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Go
    go

    # Go tools
    gopls # Go language server
    golangci-lint # Linter
    delve # Debugger
    go-tools # Additional Go tools
    gomodifytags # Tool for modifying struct field tags
    gotests # Tool for generating Go tests
    gore # Go REPL

    # Build tools
    gnumake

    # Version control
    git

    # Additional tools
    jq # JSON processor
    yq # YAML processor
  ];

  shellHook = ''
    # Set up GOPATH
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH

    # Create GOPATH directories if they don't exist
    mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg

    echo "Go development environment is ready!"
    echo "Go version: $(go version)"
    echo "GOPATH: $GOPATH"
  '';
}
