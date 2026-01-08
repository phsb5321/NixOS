# ~/NixOS/shells/JavaScript.nix
# Use NixOS unstable for latest packages
{
  pkgs ?
    import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
      config.allowUnfree = true;
    },
}: let
  centralizedStore = "$HOME/.nix-js-environments";

  # Import shared testing toolchain with the same pkgs
  testingToolchain = import ./testing-toolchain.nix {inherit pkgs;};

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
    (mkPackageGroup "Testing Tools" [
      # Playwright browsers now provided by testing-toolchain
      pkgs.cypress
    ])
    (mkPackageGroup "Code Quality Tools" [
      pkgs.nodePackages.eslint
      pkgs.nodePackages.prettier
      pkgs.biome # Alternative to ESLint/Prettier - configure to avoid conflicts
      pkgs.nodePackages.typescript
      pkgs.nodePackages.typescript-language-server
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
      # jq now provided by testing-toolchain
      pkgs.yq
      pkgs.openssl
      pkgs.nodePackages.nodemon
    ])
    # Browser Tools now provided by testing-toolchain
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
  packageManagers = ["pnpm" "npm" "yarn" "bun"];
in
  pkgs.mkShell {
    # Include testing toolchain packages alongside JavaScript-specific packages
    buildInputs = allPackages ++ testingToolchain.packages;

    shellHook = ''
      # Clean up NIX_PATH to suppress warnings
      export NIX_PATH=$(echo "$NIX_PATH" | sed 's|/nix/var/nix/profiles/per-user/root/channels[^:]*:||g')

      # ============================================================
      # Testing Toolchain Configuration (from testing-toolchain.nix)
      # ============================================================
      ${testingToolchain.shellHook}

      # ============================================================
      # JavaScript-Specific Configuration
      # ============================================================

      # Set up centralized store for package managers
      ${builtins.concatStringsSep "\n" (map setupPackageManager packageManagers)}

      # Configure pnpm for Cypress compatibility
      pnpm config set store-dir "${centralizedStore}/pnpm/store" &>/dev/null
      pnpm config set side-effects-cache false &>/dev/null
      pnpm config set auto-install-peers true &>/dev/null
      pnpm config set node-linker hoisted &>/dev/null

      # Update package managers
      pnpm self-update &>/dev/null || true
      if command -v bun &> /dev/null; then
        bun upgrade &>/dev/null || true
      fi

      # Set up Prisma environment variables
      export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
      export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
      export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"

      # Cypress configuration
      export CYPRESS_CACHE_FOLDER="${centralizedStore}/cypress/cache"
      export CYPRESS_VERIFY_TIMEOUT=100000
      mkdir -p "${centralizedStore}/cypress/cache"

      # TypeScript configuration
      export TSC_NONPOLLING_WATCHER=1
      export TSC_WATCHFILE=UseFsEvents

      echo ""
      echo "JavaScript/TypeScript Development Environment"
      echo ""
      echo "Node.js - pnpm - yarn - bun - deno"
      echo "TypeScript - ESLint - Prettier - Biome.js - Nodemon"
      echo "Playwright - Cypress - Testing Ready"
      echo "Prisma - PostgreSQL - Database Tools"
      echo "NestJS CLI - Vercel CLI - Build Tools"
      echo "Chromium - Browser Tools Ready"
      echo ""
      echo "Run 'test-toolchain-diagnose' to verify testing setup"
      echo ""
    '';
  }
