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

  # Create a module with standard enable/package/extraPackages pattern
  # Usage: mkCategoryModule { name = "browsers"; packages = [ pkgs.firefox ]; description = "Web browsers"; }
  mkCategoryModule = {
    name,
    packages,
    description,
    extraPackagesDefault ? [],
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.modules.packages.categories.${name};
  in {
    options.modules.packages.categories.${name} = {
      enable = lib.mkEnableOption description;
      package = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packages;
        description = "Default packages for ${description}";
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = extraPackagesDefault;
        description = "Additional packages for ${description}";
      };
    };

    config = lib.mkIf cfg.enable {
      environment.systemPackages = cfg.package ++ cfg.extraPackages;
    };
  };

  # Create a service module with standard enable/package pattern
  # Usage: mkServiceModule { name = "syncthing"; package = pkgs.syncthing; description = "File synchronization"; serviceConfig = {...}; }
  mkServiceModule = {
    name,
    package,
    description,
    serviceConfig ? {},
  }: {
    config,
    lib,
    ...
  }: let
    cfg = config.modules.services.${name};
  in {
    options.modules.services.${name} = {
      enable = lib.mkEnableOption description;
      package = lib.mkOption {
        type = lib.types.package;
        default = package;
        description = "The ${description} package to use";
      };
    };

    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        {environment.systemPackages = [cfg.package];}
        serviceConfig
      ]
    );
  };

  # Create a GPU configuration module
  # Usage: mkGPUModule { vendor = "amd"; drivers = [ "amdgpu" ]; packages = [ pkgs.rocmPackages.clr ]; }
  mkGPUModule = {
    vendor,
    drivers,
    packages ? [],
    extraConfig ? {},
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.modules.gpu.${vendor};
  in {
    options.modules.gpu.${vendor} = {
      enable = lib.mkEnableOption "${vendor} GPU support";
      drivers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = drivers;
        description = "Kernel drivers for ${vendor} GPU";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = packages;
        description = "Additional packages for ${vendor} GPU";
      };
    };

    config = lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          services.xserver.videoDrivers = cfg.drivers;
          environment.systemPackages = cfg.packages;
        }
        extraConfig
      ]
    );
  };

  # Create a document tool module (for LaTeX, Typst, Markdown sections)
  # Usage: mkDocumentToolModule { name = "latex"; packages = [ pkgs.texlive.combined.scheme-full ]; description = "LaTeX typesetting"; }
  mkDocumentToolModule = {
    name,
    packages,
    description,
    extraOptions ? {},
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.modules.core.document-tools.${name};
  in {
    options.modules.core.document-tools.${name} =
      {
        enable = lib.mkEnableOption description;
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = packages;
          description = "Packages for ${description}";
        };
      }
      // extraOptions;

    config = lib.mkIf cfg.enable {
      environment.systemPackages = cfg.packages;
    };
  };

  # Auto-import all .nix files in a directory
  # Usage: mkImportList ./path/to/modules "*.nix"
  mkImportList = path: pattern:
    let
      files = builtins.readDir path;
      nixFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) files;
    in
      map (name: path + "/${name}") (lib.attrNames nixFiles);
}
