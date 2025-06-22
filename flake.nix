{
  description = "Nixos config flake";

  inputs = {
    # Main Nixpkgs input, set to the unstable branch for up-to-date packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Bleeding-edge Nixpkgs source from the 'nixpkgs-unstable' branch
    bleed.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Stable Nixpkgs source from the 'nixos-25.05' branch
    stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager input for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs for custom projects and tools
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    firefox-nightly = {
      url = "github:andersk/flake-firefox-nightly/612c986d422af5a58acf3bfc5c18be8e7b97afd5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = {
    self,
    nixpkgs,
    bleed,
    stable,
    home-manager,
    ...
  } @ inputs: let
    # Define target architecture
    system = "x86_64-linux";

    # Define system version
    systemVersion = "25.05";

    # Common nixpkgs configuration with performance optimizations
    nixpkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true;
      # Performance optimizations
      config.allowParallelBuilding = true;
      config.contentAddressedByDefault = false;
    };

    # Create package sets for different channels
    bleedPkgs = import bleed {
      inherit system;
      config = nixpkgsConfig;
    };

    stablePkgs = import stable {
      inherit system;
      config = nixpkgsConfig;
    };

    # Common specialArgs to pass into each NixOS system
    commonSpecialArgs = {
      inherit inputs systemVersion bleedPkgs stablePkgs system;
    };

    # Define common modules for all configurations
    commonModules = [
      # Configure nixpkgs
      {
        nixpkgs = {
          config = nixpkgsConfig;
          overlays = [];
        };
      }

      # Home-manager configuration
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true; # Changed from true to false
          useUserPackages = true;
          extraSpecialArgs = commonSpecialArgs;
        };
      }
    ];
  in {
    # Declare the various NixOS configurations
    nixosConfigurations = {
      # Default configuration
      default = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules =
          commonModules
          ++ [
            ./hosts/default/configuration.nix
          ];
      };

      # Laptop-specific configuration
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules =
          commonModules
          ++ [
            ./hosts/laptop/configuration.nix
          ];
      };
    };
  };
}
