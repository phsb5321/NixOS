{ pkgs ? import <nixpkgs> { } }:

let
  # Create a custom nodejs package with corepack enabled
  nodejs-with-corepack = pkgs.nodejs_20.override {
    enableCorepack = true;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Use the custom Node.js with corepack enabled
    nodejs_22
    corepack_22

    # Core build tools
    gcc
    gnumake

    # Additional tools
    jq # JSON processor
    yq # YAML processor

    # Add Chromium instead of Google Chrome
    chromium

    nodePackages_latest.prisma
  ];

  shellHook = ''
     # Create a temporary directory for pnpm global installations
     export PNPM_HOME="$PWD/.pnpm-store"
     mkdir -p $PNPM_HOME

     # Add pnpm to PATH
     export PATH="$PNPM_HOME:$PATH"

    # Initialize pnpm in the current directory (with --force to override existing configuration)
     pnpm setup --force

     echo "JavaScript/TypeScript development environment is ready!"
     echo "Node.js version: $(node --version)"
     echo "pnpm version: $(pnpm --version)"
     echo "Chromium version: $(chromium --product-version)"

     # Set the Chromium executable path for Puppeteer
     export PUPPETEER_EXECUTABLE_PATH="$(which chromium)"

     # Optionally, you can add more environment setup here
     # For example, setting up environment variables, etc.
     #
     # Prisma:
     environment.variables.PRISMA_QUERY_ENGINE_LIBRARY = "${pkgs.prisma-engines}/lib/libquery_engine.node";
     environment.variables.PRISMA_QUERY_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/query-engine";
     environment.variables.PRISMA_SCHEMA_ENGINE_BINARY = "${pkgs.prisma-engines}/bin/schema-engine";
  '';
}
