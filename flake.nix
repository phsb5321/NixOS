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
    # System configuration
    system = "x86_64-linux";

    # Get NixOS version dynamically
    systemVersion = let
      version = nixpkgs.lib.version;
      versionParts = builtins.splitVersion version;
      major = builtins.head versionParts;
      minor = builtins.elemAt versionParts 1;
    in "${major}.${minor}";

    # Package configuration
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    # Create package sets
    pkgs = import nixpkgs {
      inherit system;
      config = pkgsConfig;
    };

    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config = pkgsConfig;
    };

    # Special args for modules
    specialArgs = {
      inherit inputs systemVersion system;
      pkgs-unstable = pkgs-unstable;
      stablePkgs = pkgs;
      bleedPkgs = pkgs-unstable;
    };
  in {
    # NixOS Configurations
    nixosConfigurations = {
      default = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/default/configuration.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
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
                options = nixpkgs.lib.mkDefault "--delete-older-than 7d";
              };
            };

            # System version
            system.stateVersion = systemVersion;
          }
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/laptop/configuration.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = specialArgs;
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
                options = nixpkgs.lib.mkDefault "--delete-older-than 7d";
              };
            };

            # System version
            system.stateVersion = systemVersion;
          }
        ];
      };
    };

    # Formatter
    formatter.${system} = pkgs.nixpkgs-fmt;
  };
}
