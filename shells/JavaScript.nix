{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Node.js and related tools
    nodejs_22
    nodePackages_latest.pnpm
    nodePackages_latest.vercel
    nodePackages_latest.prisma

    # Core build tools
    gcc
    gnumake

    # Additional tools
    jq # JSON processor
    yq # YAML processor

    # Prisma dependencies
    openssl
    postgresql_16

    # Add Chromium instead of Google Chrome
    chromium

    # Prisma engines
    prisma-engines
  ];

  shellHook = ''
    # Create a temporary directory for pnpm global installations
    export PNPM_HOME="$PWD/.pnpm-store"
    mkdir -p $PNPM_HOME

    # Add pnpm to PATH
    export PATH="$PNPM_HOME:$PATH"

    echo "JavaScript/TypeScript development environment is ready!"
    echo "Node.js version: $(node --version)"
    echo "pnpm version: $(pnpm --version)"
    echo "Chromium version: $(chromium --product-version)"

    # Set the Chromium executable path for Puppeteer
    export PUPPETEER_EXECUTABLE_PATH="$(which chromium)"

    # Prisma-specific environment variables
    export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
    export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
    export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
  '';
}
