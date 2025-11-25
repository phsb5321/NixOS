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

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Declare supported systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Flake-parts modules for modular configuration
      imports = [
        ./flake-modules/outputs.nix
        # Will add: ./flake-modules/hosts.nix
      ];

      # Escape hatch: preserve ALL existing outputs temporarily
      flake = let
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
          allowBroken = true; # Temporarily allow broken packages during upgrade
          permittedInsecurePackages = [
            "gradle-7.6.6" # Required for Android development, marked insecure after Gradle 9 release
            "electron-36.9.5" # EOL Electron version required by installed packages
          ];
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

          pkgs-unstable = import inputs.nixpkgs-unstable {
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
            nixpkgsInput = inputs.nixpkgs-unstable; # Use unstable as the main channel
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
        # Note: Per-system outputs (formatter, checks, devShells, apps, packages)
        # have been migrated to flake-modules/outputs.nix using perSystem
        nixosConfigurations =
          nixpkgs.lib.mapAttrs (name: hostConfig: mkNixosSystem hostConfig) hosts
          // {
            # Compatibility aliases for systems with different hostnames
            nixos = mkNixosSystem hosts.desktop;
            nixos-desktop = mkNixosSystem hosts.desktop;
            nixos-laptop = mkNixosSystem hosts.laptop;
            # Legacy alias for backward compatibility
            default = mkNixosSystem hosts.desktop;
          };
      };
    };
}
