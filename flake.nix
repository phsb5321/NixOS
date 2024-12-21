{
  description = "Nixos config flake";

  inputs = {
    # Main Nixpkgs input, set to the unstable branch for up-to-date packages
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Bleeding-edge Nixpkgs source from the 'nixpkgs-unstable' branch
    bleed.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Home Manager input for managing user environments
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Additional inputs for custom projects and tools
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
    # Define target architecture
    system = "x86_64-linux";

    # Define system version
    systemVersion = "24.11";

    # Common nixpkgs configuration (unfree, etc.)
    nixpkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true;
    };

    # Define standard (pkgs) and bleeding-edge (bleedPkgs) package sets
    pkgs = import nixpkgs {
      inherit system;
      config = nixpkgsConfig;
    };

    bleedPkgs = import bleed {
      inherit system;
      config = nixpkgsConfig;
    };

    # Common specialArgs to pass into each NixOS system
    commonSpecialArgs = {
      inherit inputs pkgs bleedPkgs systemVersion;
    };

    # Define common modules for all configurations
    commonModules = [
      # Existing module with config overrides
      {
        nixpkgs.config = nixpkgsConfig;
        home-manager.users.notroot.home.enableNixpkgsReleaseCheck = false;
      }
      # Additional module that sets a global download-buffer-size
      {
        nix = {
          settings = {
            download-buffer-size = "1024M";
          };
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

      # Experimental VM configuration
      experimental-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = commonSpecialArgs;
        modules =
          commonModules
          ++ [
            ./hosts/experimental-vm/configuration.nix
          ];
      };
    };
  };
}
