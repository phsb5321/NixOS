{
  description = "NixOS configuration flake";

  inputs = {
    # Use nixos-unstable as the main system channel (bleeding edge but tested)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Use nixpkgs-unstable for most packages (faster updates, package-focused)
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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

    # Flake utilities for better system handling
    flake-utils.url = "github:numtide/flake-utils";

    # Modular flake framework
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Secrets management with sops
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      # Declare supported systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Flake-parts modules for modular configuration
      imports = [
        ./flake-modules/outputs.nix
        ./flake-modules/hosts.nix
      ];

      # Migration complete - all outputs now in flake-modules/
      # - outputs.nix: perSystem outputs (checks, formatter, devShells, apps, packages)
      # - hosts.nix: nixosConfigurations with withSystem integration
    };
}
