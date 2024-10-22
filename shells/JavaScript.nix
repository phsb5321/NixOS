{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-24.05.tar.gz") { } }: # Uses Nixpkgs 24.05
# { pkgs ? import <nixpkgs> { } }: # Uses the latest Nixpkgs

let
  centralizedStore = "$HOME/.nix-js-environments";

  # Helper function to create a tagged package group
  mkPackageGroup = name: packages: {
    inherit name packages;
  };

  # Define package groups
  packageGroups = [
    (mkPackageGroup "Core JavaScript Tools" [
      pkgs.nodejs_22
      pkgs.nodePackages.pnpm
      pkgs.bun
      pkgs.nodePackages.yarn
      pkgs.nodePackages.npm
      pkgs.deno
    ])
    (mkPackageGroup "Development Frameworks and CLIs" [
      pkgs.nodePackages.vercel
      pkgs.nodePackages."@nestjs/cli"
    ])
    (mkPackageGroup "Database Tools" [
      pkgs.nodePackages.prisma
      pkgs.postgresql_16
      pkgs.prisma-engines
    ])
    (mkPackageGroup "Build Tools" [
      pkgs.gcc
      pkgs.gnumake
    ])
    (mkPackageGroup "Utility Tools" [
      pkgs.jq
      pkgs.yq
      pkgs.openssl
    ])
    (mkPackageGroup "Browser Tools" [
      pkgs.chromium
    ])
  ];

  # Flatten package groups into a single list
  allPackages = builtins.concatLists (map (group: group.packages) packageGroups);

  # Function to generate environment setup for a package manager
  setupPackageManager = name: ''
    mkdir -p "${centralizedStore}/${name}"
    export ${name}_HOME="${centralizedStore}/${name}"
    export PATH="$${name}_HOME/bin:$PATH"
  '';

  # List of package managers to set up
  packageManagers = [ "pnpm" "npm" "yarn" "bun" ];

in
pkgs.mkShell {
  buildInputs = allPackages;

  shellHook = ''
    # Set up centralized store for package managers
    ${builtins.concatStringsSep "\n" (map setupPackageManager packageManagers)}

    # Configure pnpm to use the centralized store
    pnpm config set store-dir "${centralizedStore}/pnpm/store" &>/dev/null

    # Set up Prisma environment variables
    export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
    export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
    export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"

    # Set up Puppeteer
    export PUPPETEER_EXECUTABLE_PATH="$(which chromium)"

    # Function to run commands only in project directories
    run_in_project() {
      if [ -f "package.json" ]; then
        "$@"
      else
        echo "Error: No package.json found. Please run this command in a JavaScript project directory."
      fi
    }

    # Set up aliases for package managers
    ${builtins.concatStringsSep "\n" (map (pm: "alias ${pm}='run_in_project ${pm}'") packageManagers)}

    # Print environment information
    echo "🚀 JavaScript/TypeScript development environment (NixOS 24.05) is ready!"
    echo "📦 Installed package groups:"
    ${builtins.concatStringsSep "\n" (map (group: "echo \"  - ${group.name}\"") packageGroups)}
    echo "🔧 Use 'pnpm', 'npm', 'yarn', or 'bun' to manage your project dependencies."
    echo "🦕 Deno is now available in your environment."
    echo "🏗️  NestJS CLI is available. Use 'nest' to create and manage NestJS projects."
  '';
}
