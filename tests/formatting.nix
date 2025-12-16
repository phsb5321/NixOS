# ~/NixOS/tests/formatting.nix
# Code formatting and linting tests
<<<<<<< HEAD
{ pkgs, lib, ... }:

{
=======
{
  pkgs,
  lib,
  ...
}: {
>>>>>>> origin/host/server
  # Formatting check script
  format-check = pkgs.writeShellScriptBin "format-check" ''
    set -euo pipefail

    echo "🔍 Checking Nix code formatting..."

    # Find all .nix files
    NIX_FILES=$(${pkgs.findutils}/bin/find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*")

    # Check if files need formatting
    NEEDS_FORMAT=0
    for file in $NIX_FILES; do
      if ! ${pkgs.alejandra}/bin/alejandra --check "$file" >/dev/null 2>&1; then
        echo "❌ Needs formatting: $file"
        NEEDS_FORMAT=1
      fi
    done

    if [ $NEEDS_FORMAT -eq 0 ]; then
      echo "✅ All Nix files are properly formatted"
      exit 0
    else
      echo ""
      echo "💡 Run 'alejandra .' to format all files"
      exit 1
    fi
  '';

  # Auto-format script
  format-fix = pkgs.writeShellScriptBin "format-fix" ''
    set -euo pipefail

    echo "🔧 Formatting Nix code..."
    ${pkgs.alejandra}/bin/alejandra .
    echo "✅ Formatting complete"
  '';

  # Linting check script
  lint-check = pkgs.writeShellScriptBin "lint-check" ''
    set -euo pipefail

    echo "🔍 Linting Nix code..."

    # Check flake syntax
    echo "📝 Checking flake syntax..."
    if ${pkgs.nix}/bin/nix flake check --all-systems 2>&1 | tee /tmp/flake-check.log; then
      echo "✅ Flake check passed"
    else
      echo "❌ Flake check failed"
      cat /tmp/flake-check.log
      exit 1
    fi

    echo "✅ All linting checks passed"
  '';

  # Combined check script
  pre-commit-check = pkgs.writeShellScriptBin "pre-commit-check" ''
    set -euo pipefail

    echo "🚀 Running pre-commit checks..."
    echo ""

    ${pkgs.writeShellScriptBin "format-check" (builtins.readFile "${format-check}/bin/format-check")}/bin/format-check
    echo ""

    ${pkgs.writeShellScriptBin "lint-check" (builtins.readFile "${lint-check}/bin/lint-check")}/bin/lint-check
    echo ""

    echo "✅ All pre-commit checks passed!"
  '';
}
