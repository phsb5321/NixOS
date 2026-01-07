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

    # Overlays to fix package issues
    overlays = [
      # Fix clipboard-indicator extension schema compilation
      (_final: prev: {
        gnomeExtensions =
          prev.gnomeExtensions
          // {
            clipboard-indicator = prev.gnomeExtensions.clipboard-indicator.overrideAttrs (oldAttrs: {
              postInstall =
                (oldAttrs.postInstall or "")
                + ''
                  # Recompile schemas to fix type mismatch bug
                  ${prev.glib.dev}/bin/glib-compile-schemas $out/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas/
                '';
            });
          };
      })
    ];

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
        self',
        inputs',
        ...
      }: let
        # Get NixOS version dynamically from the input
        systemVersion = let
          inherit (nixpkgsInput.lib) version;
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
          inherit overlays;
        };

        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = pkgsConfig;
          inherit overlays;
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
            inherit pkgs-unstable;
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
                nixpkgs.overlays = overlays;

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

                # System version (mkDefault allows host-specific override)
                system.stateVersion = nixpkgsInput.lib.mkDefault systemVersion;

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
      inputs.nixpkgs.lib.mapAttrs (_name: mkNixosSystem) hosts
      // {
        # Compatibility aliases for systems with different hostnames
        nixos = mkNixosSystem hosts.desktop;
        nixos-desktop = mkNixosSystem hosts.desktop;
        nixos-laptop = mkNixosSystem hosts.laptop;
        nixos-server = mkNixosSystem hosts.server;
        # Legacy alias for backward compatibility
        default = mkNixosSystem hosts.desktop;
      };

    # Colmena configuration for remote deployment
    # Usage: colmena build, colmena apply --on <host>
    # Note: Colmena requires special args that match what nixosSystem provides
    colmena = let
      # Helper to create colmena node config from our hosts definition
      mkColmenaNode = _hostName: hostConfig: {pkgs, ...}: let
        nixpkgsInput = hostConfig.nixpkgsInput or inputs.nixpkgs;
        systemVersion = let
          inherit (nixpkgsInput.lib) version;
          versionParts = builtins.splitVersion version;
          major = builtins.head versionParts;
          minor = builtins.elemAt versionParts 1;
        in "${major}.${minor}";

        pkgs-unstable = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          config = pkgsConfig;
          inherit overlays;
        };
      in {
        deployment = {
          targetHost = hostConfig.hostname;
          targetUser = "root";
          allowLocalDeployment = true;
          tags =
            if _hostName == "desktop"
            then ["desktop" "workstation" "canary"]
            else if _hostName == "laptop"
            then ["laptop" "portable"]
            else if _hostName == "server"
            then ["server" "production"]
            else [];
        };

        imports = [../hosts/${hostConfig.configPath}/configuration.nix];

        # Provide the same specialArgs that mkNixosSystem provides
        _module.args = {
          inherit inputs;
          systemVersion = systemVersion;
          system = hostConfig.system;
          hostname = hostConfig.hostname;
          inherit pkgs-unstable;
          stablePkgs = pkgs;
          # self' and inputs' are not available in colmena context
        };
      };
    in {
      meta = {
        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
          config = pkgsConfig;
          inherit overlays;
        };

        # Node-specific nixpkgs (for different channels per host)
        nodeNixpkgs = {
          desktop = import inputs.nixpkgs-unstable {
            system = "x86_64-linux";
            config = pkgsConfig;
            inherit overlays;
          };
          laptop = import inputs.nixpkgs {
            system = "x86_64-linux";
            config = pkgsConfig;
            inherit overlays;
          };
          server = import inputs.nixpkgs {
            system = "x86_64-linux";
            config = pkgsConfig;
            inherit overlays;
          };
        };

        # Special args available to all nodes
        specialArgs = {
          inherit inputs;
        };
      };

      # Default configuration applied to all nodes
      defaults = {...}: {
        # Common settings for all colmena-managed nodes
        nixpkgs.config = pkgsConfig;
        nixpkgs.overlays = overlays;
      };

      # Generate node configs from hosts definition
      desktop = mkColmenaNode "desktop" hosts.desktop;
      laptop = mkColmenaNode "laptop" hosts.laptop;
      server = mkColmenaNode "server" hosts.server;
    };
  };
}
