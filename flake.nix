{
  description = "Nixos config flake";

  inputs = {
    # Only updating home-manager to match nixpkgs version, rest stays the same
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bleed.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master"; # Updated to master to match unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    firefox-nightly = {
      url = "github:nix-community/flake-firefox-nightly";
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
        home-manager.users.notroot.home.enableNixpkgsReleaseCheck = false; # Added to disable version mismatch warning
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

      # Experimental VM configuration
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
