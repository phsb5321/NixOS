{pkgs ? import <nixpkgs> {config.allowUnfree = true;}}: let
  # Import shared testing toolchain
  testingToolchain = import ./testing-toolchain.nix {inherit pkgs;};
in
  pkgs.mkShell {
    buildInputs = with pkgs;
      [
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

        # Additional tools (jq now from testing-toolchain)
        yq # YAML processor
      ]
      ++ testingToolchain.packages;

    shellHook = ''
      # Testing toolchain configuration
      ${testingToolchain.shellHook}

      # Set up GOPATH
      export GOPATH=$HOME/go
      export PATH=$GOPATH/bin:$PATH

      # Create GOPATH directories if they don't exist
      mkdir -p $GOPATH/src $GOPATH/bin $GOPATH/pkg

      echo "Go development environment is ready!"
      echo "Go version: $(go version)"
      echo "GOPATH: $GOPATH"
      echo ""
      echo "Run 'test-toolchain-diagnose' to verify testing setup"
    '';
  }
