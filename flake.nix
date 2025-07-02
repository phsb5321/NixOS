{
  description = "NixOS configuration flake";

  inputs = {
    # Use NixOS 25.05 LTS
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Unstable for latest packages when needed
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flake utilities for better system handling
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    flake-utils,
    ...
  } @ inputs: let
    # Supported systems
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

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
          inherit inputs systemVersion system hostname;
          pkgs-unstable = pkgs-unstable;
          stablePkgs = pkgs;
          bleedPkgs = pkgs-unstable;
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

            # Home Manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = baseSpecialArgs;
              };
            }

            # Base system configuration
            {
              nixpkgs.config = pkgsConfig;

              # Nix settings
              nix = {
                settings = {
                  experimental-features = ["nix-command" "flakes"];
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
      default = {
        system = "x86_64-linux";
        hostname = "nixos-desktop";
        configPath = "default"; # Maps to hosts/default/
        # Uses stable nixpkgs by default
      };

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

      # Example: development machine using unstable
      # dev = {
      #   system = "x86_64-linux";
      #   hostname = "nixos-dev";
      #   configPath = "dev";
      #   nixpkgsInput = nixpkgs-unstable;  # Latest packages
      # };
    };
  in {
    # NixOS Configurations - Generated from hosts definition
    nixosConfigurations =
      nixpkgs.lib.mapAttrs (
        name: hostConfig:
          mkNixosSystem hostConfig
      )
      hosts;

    # Formatter for each system
    formatter = forAllSystems (
      system:
        (import nixpkgs {inherit system;}).nixpkgs-fmt
    );

    # Development shells (useful for development)
    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = pkgsConfig;
      };
    in {
      default = pkgs.mkShell {
        name = "nixos-config";
        buildInputs = with pkgs; [
          nixpkgs-fmt
          statix # Nix linter
          deadnix # Dead code detection
        ];
      };
    });

    # Helper scripts for deployment (optional)
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        config = pkgsConfig;
      };
    in {
      # Script to deploy to a specific host
      deploy = pkgs.writeShellScriptBin "deploy" ''
        set -e
        HOST=''${1:-default}

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
        HOST=''${1:-default}
        echo "Building configuration for $HOST..."
        nixos-rebuild build --flake .#$HOST
      '';
    });
  };
}
