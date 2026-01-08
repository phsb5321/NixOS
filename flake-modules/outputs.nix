# flake-modules/outputs.nix
#
# Per-system outputs for the NixOS configuration flake
# Defines checks, formatter, devShells, apps, and packages using perSystem
{
  perSystem = {pkgs, ...}: {
    # Checks for CI/CD validation
    checks = {
      # Format check
      format-check = pkgs.runCommand "format-check" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${../.} > $out 2>&1 || (
          echo "Formatting issues found. Run 'nix fmt' to fix."
          exit 1
        )
      '';

      # Lint check
      lint-check = pkgs.runCommand "lint-check" {} ''
        ${pkgs.statix}/bin/statix check --config ${../.}/statix.toml ${../.} > $out 2>&1
      '';

      # Dead code check
      deadnix-check = pkgs.runCommand "deadnix-check" {} ''
        ${pkgs.deadnix}/bin/deadnix --fail ${../.} > $out 2>&1
      '';
    };

    # Formatter for this system
    formatter = pkgs.alejandra;

    # Development shells
    devShells.default = pkgs.mkShell {
      name = "nixos-config";
      buildInputs = with pkgs; [
        alejandra # Nix formatter
        statix # Nix linter
        deadnix # Dead code detection
        nixos-rebuild # System rebuild
        git # Version control
      ];
      shellHook = ''
        echo "NixOS Configuration Development Shell"
        echo "Available commands:"
        echo "  alejandra .    - Format Nix files"
        echo "  statix check . - Lint Nix files"
        echo "  deadnix .      - Find dead code"
        echo "  nix flake check - Run all checks"
      '';
    };

    # Apps for common tasks
    apps = {
      # Format all Nix files
      format = {
        type = "app";
        program = "${pkgs.alejandra}/bin/alejandra";
      };

      # Update flake inputs
      update = {
        type = "app";
        program = toString (pkgs.writeShellScript "update" ''
          ${pkgs.nix}/bin/nix flake update
          echo "Flake inputs updated. Review changes with 'git diff flake.lock'"
        '');
      };

      # Check configuration
      check-config = {
        type = "app";
        program = toString (pkgs.writeShellScript "check-config" ''
          echo "Checking NixOS configuration..."
          ${pkgs.nix}/bin/nix flake check
        '');
      };
    };

    # Helper scripts for deployment
    packages = {
      # Script to deploy to a specific host
      deploy = pkgs.writeShellScriptBin "deploy" ''
        set -e
        HOST=''${1:-desktop}

        if [ -z "$HOST" ]; then
          echo "Usage: $0 <hostname>"
          echo "Available hosts: desktop laptop"
          exit 1
        fi

        echo "Deploying to $HOST..."
        nixos-rebuild switch --flake .#$HOST --target-host $HOST --use-remote-sudo
      '';

      # Script to build without switching
      build = pkgs.writeShellScriptBin "build" ''
        set -e
        HOST=''${1:-desktop}
        echo "Building configuration for $HOST..."
        nixos-rebuild build --flake .#$HOST
      '';
    };
  };
}
