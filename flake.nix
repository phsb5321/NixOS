{
  description = "NixOS configuration flake";

  inputs = {
    # Use nixos-unstable as the main system channel (bleeding edge but tested)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Use nixpkgs-unstable for most packages (faster updates, package-focused)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Firefox Nightly (official nix-community source)
    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake utilities for better system handling
    flake-utils.url = "github:numtide/flake-utils";

    # Modular flake framework
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Secrets management with sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    ...
  } @ inputs: let
    # Supported systems
    supportedSystems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    # Helper function to create package sets
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Package configuration
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    # Helper function to create a NixOS system
    mkNixosSystem = {
      system,
      hostname,
      configPath, # Path to the host configuration directory
      nixpkgsInput ? nixpkgs, # Allow different nixpkgs versions per host
      extraModules ? [],
      extraSpecialArgs ? {},
    }: let
      # Get NixOS version dynamically from the input
      systemVersion = let
        version = nixpkgsInput.lib.version;
        versionParts = builtins.splitVersion version;
        major = builtins.head versionParts;
        minor = builtins.elemAt versionParts 1;
      in "${major}.${minor}";

      # Create package sets
      pkgs = import nixpkgsInput {
        inherit system;
        config = pkgsConfig;
      };

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = pkgsConfig;
      };

      # Common special args for all hosts
      baseSpecialArgs =
        {
          inherit
            inputs
            systemVersion
            system
            hostname
            ;
          pkgs-unstable = pkgs-unstable;
          stablePkgs = pkgs;
        }
        // extraSpecialArgs;
    in
      nixpkgsInput.lib.nixosSystem {
        inherit system;
        specialArgs = baseSpecialArgs;
        modules =
          [
            # Host-specific configuration
            ./hosts/${configPath}/configuration.nix

            # Base system configuration
            {
              nixpkgs.config = pkgsConfig;

              # Nix settings
              nix = {
                settings = {
                  experimental-features = [
                    "nix-command"
                    "flakes"
                  ];
                  auto-optimise-store = true;
                };

                gc = {
                  automatic = true;
                  dates = "weekly";
                  options = nixpkgsInput.lib.mkDefault "--delete-older-than 7d";
                };
              };

              # System version
              system.stateVersion = systemVersion;

              # Set hostname
              networking.hostName = nixpkgsInput.lib.mkDefault hostname;
            }
          ]
          ++ extraModules;
      };

    # Define all your hosts here
    hosts = {
      # Primary desktop system
      desktop = {
        system = "x86_64-linux";
        hostname = "nixos-desktop";
        configPath = "desktop"; # Maps to hosts/desktop/
        nixpkgsInput = nixpkgs-unstable; # Use unstable as the main channel
      };

      # Laptop system
      laptop = {
        system = "x86_64-linux";
        hostname = "nixos-laptop";
        configPath = "laptop"; # Maps to hosts/laptop/
        # Uses stable nixpkgs by default
      };

      # Example: server using stable for reliability
      # server = {
      #   system = "x86_64-linux";
      #   hostname = "nixos-server";
      #   configPath = "server";
      #   nixpkgsInput = nixpkgs;  # Explicitly stable
      # };
    };
  in {
    # NixOS Configurations - Generated from hosts definition
    nixosConfigurations = nixpkgs.lib.mapAttrs (name: hostConfig: mkNixosSystem hostConfig) hosts // {
      # Compatibility aliases for systems with different hostnames
      nixos = mkNixosSystem hosts.desktop;
      nixos-desktop = mkNixosSystem hosts.desktop;
      nixos-laptop = mkNixosSystem hosts.laptop;
      # Legacy alias for backward compatibility
      default = mkNixosSystem hosts.desktop;
    };

    # Formatter for each system (using alejandra for better formatting)
    formatter = forAllSystems (system: (import nixpkgs {inherit system;}).alejandra);

    # Checks for CI/CD validation
    checks = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = pkgsConfig;
        };
      in {
        # Format check
        format-check = pkgs.runCommand "format-check" {} ''
          ${pkgs.alejandra}/bin/alejandra --check ${./.} > $out 2>&1 || (
            echo "Formatting issues found. Run 'nix fmt' to fix."
            exit 1
          )
        '';

        # Lint check
        lint-check = pkgs.runCommand "lint-check" {} ''
          ${pkgs.statix}/bin/statix check ${./.} > $out 2>&1
        '';

        # Dead code check
        deadnix-check = pkgs.runCommand "deadnix-check" {} ''
          ${pkgs.deadnix}/bin/deadnix --fail ${./.} > $out 2>&1
        '';
      }
    );

    # Development shells (useful for development)
    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = pkgsConfig;
        };
      in {
        default = pkgs.mkShell {
          name = "nixos-config";
          buildInputs = with pkgs; [
            alejandra # Nix formatter
            statix # Nix linter
            deadnix # Dead code detection
            nixos-rebuild # System rebuild
            git # Version control
          ];
          shellHook = ''
            echo "NixOS Configuration Development Shell"
            echo "Available commands:"
            echo "  alejandra .    - Format Nix files"
            echo "  statix check . - Lint Nix files"
            echo "  deadnix .      - Find dead code"
            echo "  nix flake check - Run all checks"
          '';
        };
      }
    );

    # Apps for common tasks
    apps = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = pkgsConfig;
        };
      in {
        # Format all Nix files
        format = {
          type = "app";
          program = "${pkgs.alejandra}/bin/alejandra";
        };

        # Update flake inputs
        update = {
          type = "app";
          program = toString (pkgs.writeShellScript "update" ''
            ${pkgs.nix}/bin/nix flake update
            echo "Flake inputs updated. Review changes with 'git diff flake.lock'"
          '');
        };

        # Check configuration
        check-config = {
          type = "app";
          program = toString (pkgs.writeShellScript "check-config" ''
            echo "Checking NixOS configuration..."
            ${pkgs.nix}/bin/nix flake check
          '');
        };
      }
    );

    # Helper scripts for deployment (optional)
    packages = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          config = pkgsConfig;
        };
      in {
        # Script to deploy to a specific host
        deploy = pkgs.writeShellScriptBin "deploy" ''
          set -e
          HOST=''${1:-desktop}

          if [ -z "$HOST" ]; then
            echo "Usage: $0 <hostname>"
            echo "Available hosts: ${builtins.concatStringsSep " " (builtins.attrNames hosts)}"
            exit 1
          fi

          echo "Deploying to $HOST..."
          nixos-rebuild switch --flake .#$HOST --target-host $HOST --use-remote-sudo
        '';

        # Script to build without switching
        build = pkgs.writeShellScriptBin "build" ''
          set -e
          HOST=''${1:-desktop}
          echo "Building configuration for $HOST..."
          nixos-rebuild build --flake .#$HOST
        '';
      }
    );
  };
}
