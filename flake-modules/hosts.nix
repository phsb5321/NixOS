# flake-modules/hosts.nix
#
# Host configurations for multi-host NixOS flake
# Defines nixosConfigurations using withSystem for perSystem context integration
{
  inputs,
  withSystem,
  ...
}: {
  flake = let
    # Package configuration shared across all hosts
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true; # Temporarily allow broken packages during upgrade
      permittedInsecurePackages = [
        "gradle-7.6.6" # Required for Android development, marked insecure after Gradle 9 release
        "electron-36.9.5" # EOL Electron version required by installed packages
      ];
    };

    # Helper function to create a NixOS system with perSystem context
    # Uses withSystem to access perSystem outputs (pkgs, config, self', inputs')
    mkNixosSystem = {
      system,
      hostname,
      configPath, # Path to the host configuration directory
      nixpkgsInput ? inputs.nixpkgs, # Allow different nixpkgs versions per host
      extraModules ? [],
      extraSpecialArgs ? {},
    }:
      withSystem system ({
        pkgs,
        config,
        self',
        inputs',
        ...
      }: let
        # Get NixOS version dynamically from the input
        systemVersion = let
          version = nixpkgsInput.lib.version;
          versionParts = builtins.splitVersion version;
          major = builtins.head versionParts;
          minor = builtins.elemAt versionParts 1;
        in "${major}.${minor}";

        # Create package sets
        # Note: pkgs from perSystem is already configured with system
        # We create custom package sets for different nixpkgs inputs
        pkgsForHost = import nixpkgsInput {
          inherit system;
          config = pkgsConfig;
        };

        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = pkgsConfig;
        };

        # Common special args for all hosts
        # Includes perSystem context (self', inputs') for accessing per-system outputs
        baseSpecialArgs =
          {
            inherit
              inputs
              systemVersion
              system
              hostname
              self'
              inputs'
              ;
            pkgs-unstable = pkgs-unstable;
            stablePkgs = pkgsForHost;
          }
          // extraSpecialArgs;
      in
        nixpkgsInput.lib.nixosSystem {
          inherit system;
          specialArgs = baseSpecialArgs;
          modules =
            [
              # Host-specific configuration
              ../hosts/${configPath}/configuration.nix

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
        });

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

      # Server using stable for reliability
      server = {
        system = "x86_64-linux";
        hostname = "nixos-server";
        configPath = "server";
        nixpkgsInput = inputs.nixpkgs; # Explicitly stable
      };
    };
  in {
    # NixOS Configurations - Generated from hosts definition
    nixosConfigurations =
      inputs.nixpkgs.lib.mapAttrs (name: hostConfig: mkNixosSystem hostConfig) hosts
      // {
        # Compatibility aliases for systems with different hostnames
        nixos = mkNixosSystem hosts.desktop;
        nixos-desktop = mkNixosSystem hosts.desktop;
        nixos-laptop = mkNixosSystem hosts.laptop;
        nixos-server = mkNixosSystem hosts.server;
        # Legacy alias for backward compatibility
        default = mkNixosSystem hosts.desktop;
      };
  };
}
