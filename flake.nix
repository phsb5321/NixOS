{
  description = "Nixos config flake";

  inputs = {
    # Stable NixOS system for 25.05 - used for system configuration
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Bleeding-edge Nixpkgs source for packages
    bleed.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Stable Nixpkgs source matching system version
    stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager input for managing user environments - use stable branch for 25.05
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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
      allowParallelBuilding = true;
      contentAddressedByDefault = false;
      # Build optimizations
      maxJobs = "auto";
      buildCores = 0; # Use all available cores
      # Sandbox settings for security and reproducibility
      sandbox = true;
      # Store optimizations
      autoOptimiseStore = true;
      # Build settings
      keepOutputs = false;
      keepDerivations = false;
      # Parallel downloading
      downloadAttempts = 3;
      connectTimeout = 5;
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
      # Configure nixpkgs - system uses stable, packages can use bleeding edge
      {
        nixpkgs = {
          config = nixpkgsConfig;
          overlays = [
            # Allow using bleeding edge packages while keeping system stable
            (final: prev: {
              # Bleeding edge packages overlay
              bleeding = bleedPkgs;

              # Triple buffering for GNOME performance - temporarily disabled
              # TODO: Re-enable with working version
              # mutter = prev.mutter.overrideAttrs (old: {
              #   src = final.fetchFromGitLab {
              #     domain = "gitlab.gnome.org";
              #     owner = "vanvugt";
              #     repo = "mutter";
              #     rev = "triple-buffering-v4-47";
              #     hash = "sha256-fkPjB/5DPBX06t7yj0Rb3UEuu5b9mu3aS5EnM32jOJ4=";
              #   };
              # });
            })
          ];
        };

        # Performance and build optimizations
        nix = {
          settings = {
            # Build performance
            max-jobs = "auto";
            cores = 0; # Use all available cores

            # Store optimizations
            auto-optimise-store = true;
            keep-outputs = false;
            keep-derivations = false;

            # Download optimizations
            download-attempts = 3;
            connect-timeout = 5;

            # Garbage collection settings
            min-free = 1073741824; # 1GB
            max-free = 5368709120; # 5GB

            # Cache settings
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];

            # Experimental features for performance
            experimental-features = [
              "nix-command"
              "flakes"
              "ca-derivations"
              "auto-allocate-uids"
            ];
          };

          # Garbage collection automation
          gc = {
            automatic = true;
            dates = "weekly";
            options = nixpkgs.lib.mkDefault "--delete-older-than 7d";
          };

          # Nix daemon optimizations
          daemonCPUSchedPolicy = "batch";
          daemonIOSchedClass = "best-effort";
          daemonIOSchedPriority = 7;
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
