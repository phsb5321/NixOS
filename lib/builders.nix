# ~/NixOS/lib/builders.nix
# System builder functions for NixOS configuration
{
  lib,
  inputs,
}: {
  # Build a NixOS system with sensible defaults
  mkSystem = {
    hostname,
    system ? "x86_64-linux",
    role,
    hardware ? [],
    extraModules ? [],
    nixpkgsInput ? inputs.nixpkgs-unstable,
  }: let
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };

    pkgs = import nixpkgsInput {
      inherit system;
      config = pkgsConfig;
    };

    pkgs-unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config = pkgsConfig;
    };

    systemVersion = let
      version = nixpkgsInput.lib.version;
      versionParts = builtins.splitVersion version;
      major = builtins.head versionParts;
      minor = builtins.elemAt versionParts 1;
    in "${major}.${minor}";
  in
    nixpkgsInput.lib.nixosSystem {
      inherit system;

      specialArgs = {
        inherit inputs systemVersion hostname pkgs-unstable;
        stablePkgs = pkgs;
      };

      modules =
        [
          # Base configuration
          {
            nixpkgs.config = pkgsConfig;
            nix.settings = {
              experimental-features = ["nix-command" "flakes"];
              auto-optimise-store = true;
            };
            nix.gc = {
              automatic = true;
              dates = "weekly";
              options = "--delete-older-than 7d";
            };
            system.stateVersion = systemVersion;
            networking.hostName = lib.mkDefault hostname;
          }

          # Import all modules
          ../modules

          # Role-based configuration
          {modules.roles.${role}.enable = true;}

          # Hardware modules
        ]
        ++ hardware ++ extraModules;
    };

  # Helper to create package category modules
  mkPackageCategory = {
    name,
    description ? "packages for ${name}",
    packages,
    extraOptions ? {},
  }: {
    config,
    lib,
    pkgs,
    pkgs-unstable,
    ...
  }: {
    options.modules.packages.${name} =
      {
        enable = lib.mkEnableOption "${name} packages";
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = packages;
          description = "List of ${description}";
        };
      }
      // extraOptions;

    config = lib.mkIf config.modules.packages.${name}.enable {
      environment.systemPackages = config.modules.packages.${name}.packages;
    };
  };
}
