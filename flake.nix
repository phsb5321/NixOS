{
  description = "Nixos config flake";

  inputs = {
    # Main Nixpkgs input, set to the unstable branch for up-to-date packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Bleeding-edge Nixpkgs source from the 'nixpkgs-unstable' branch
    bleed.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager input for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager input with dependencies following main nixpkgs and home-manager inputs
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Additional inputs for custom projects and tools
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
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
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # Define the common nixpkgs configuration
    nixpkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    # Define standard and bleeding-edge package sets for easy access
    pkgs = import nixpkgs {
      inherit system;
      config = nixpkgsConfig;
    };

    bleedPkgs = import bleed {
      inherit system;
      config = nixpkgsConfig;
    };

    # Define common modules for all configurations
    commonModules = [
      {
        nixpkgs.config = nixpkgsConfig;
      }
    ];
  in {
    # Define NixOS configurations, with different hosts for specific setups
    nixosConfigurations = {
      # Default configuration, references './hosts/default/configuration.nix'
      default = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs pkgs bleedPkgs;};
        modules =
          commonModules
          ++ [
            ./hosts/default/configuration.nix
          ];
      };

      # Laptop-specific configuration
      laptop = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs pkgs bleedPkgs;};
        modules =
          commonModules
          ++ [
            ./hosts/laptop/configuration.nix
          ];
      };

      # Experimental VM configuration, uses bleeding-edge packages when needed
      experimental-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs pkgs bleedPkgs;};
        modules =
          commonModules
          ++ [
            ./hosts/experimental-vm/configuration.nix
          ];
      };
    };
  };
}
