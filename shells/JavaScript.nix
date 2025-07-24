# ~/NixOS/shells/JavaScript.nix
# Use NixOS 25 stable for all packages
{pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.05.tar.gz") {}}: let
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
    (mkPackageGroup "Testing Tools" [
      pkgs.playwright-driver.browsers
      pkgs.cypress
    ])
    (mkPackageGroup "Code Quality Tools" [
      pkgs.nodePackages.eslint
      pkgs.nodePackages.prettier
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
      pkgs.nodePackages.webpack
    ])
    (mkPackageGroup "Utility Tools" [
      pkgs.jq
      pkgs.yq
      pkgs.openssl
      pkgs.nodePackages.nodemon
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
  packageManagers = ["pnpm" "npm" "yarn" "bun"];
in
  pkgs.mkShell {
    buildInputs = allPackages;

    shellHook = ''
      # Clean up NIX_PATH to suppress warnings
      export NIX_PATH=$(echo "$NIX_PATH" | sed 's|/nix/var/nix/profiles/per-user/root/channels[^:]*:||g')

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

      # Set up environment variables
      export PRISMA_QUERY_ENGINE_LIBRARY="${pkgs.prisma-engines}/lib/libquery_engine.node"
      export PRISMA_QUERY_ENGINE_BINARY="${pkgs.prisma-engines}/bin/query-engine"
      export PRISMA_SCHEMA_ENGINE_BINARY="${pkgs.prisma-engines}/bin/schema-engine"
      export PUPPETEER_EXECUTABLE_PATH="$(which chromium)"
      export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
      export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true
      export CYPRESS_CACHE_FOLDER="${centralizedStore}/cypress/cache"
      export CYPRESS_VERIFY_TIMEOUT=100000
      export TSC_NONPOLLING_WATCHER=1
      export TSC_WATCHFILE=UseFsEvents

      # Create cypress cache directory
      mkdir -p "${centralizedStore}/cypress/cache"

      echo ""
      echo "🚀 ✨ JavaScript/TypeScript Development Environment ✨ 🚀"
      echo ""
      echo "📦 Node.js • pnpm • yarn • bun • 🦕 deno"
      echo "🔧 TypeScript • ESLint • Prettier • Webpack • Nodemon"
      echo "🧪 Playwright • Cypress • Testing Ready"
      echo "🗄️  Prisma • PostgreSQL • Database Tools"
      echo "🏗️  NestJS CLI • Vercel CLI • Build Tools"
      echo "🌐 Chromium • Browser Tools Ready"
      echo ""
      echo "⚡ Ready to build amazing things! ⚡"
      echo ""
    '';
  }
