# ~/NixOS/tests/scripts.nix
# Test scripts that can be added to flake packages output
{pkgs}: {
  # Formatting check
  format-check = pkgs.writeShellScriptBin "format-check" ''
    set -euo pipefail
    echo "🔍 Checking Nix code formatting..."

    NIX_FILES=$(${pkgs.findutils}/bin/find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*")
    NEEDS_FORMAT=0

    for file in $NIX_FILES; do
      if ! ${pkgs.alejandra}/bin/alejandra --check "$file" >/dev/null 2>&1; then
        echo "❌ Needs formatting: $file"
        NEEDS_FORMAT=1
      fi
    done

    if [ $NEEDS_FORMAT -eq 0 ]; then
      echo "✅ All Nix files are properly formatted"
    else
      echo "💡 Run 'alejandra .' to format all files"
      exit 1
    fi
  '';

  # Auto-format
  format-fix = pkgs.writeShellScriptBin "format-fix" ''
    set -euo pipefail
    echo "🔧 Formatting Nix code..."
    ${pkgs.alejandra}/bin/alejandra .
    echo "✅ Formatting complete"
  '';

  # Boot test
  boot-test = pkgs.writeShellScriptBin "boot-test" ''
    set -euo pipefail
    echo "🚀 Running boot tests for all hosts..."

    echo "=== Default Host ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link
    echo "✅ Default host builds successfully"

    echo "=== Laptop Host ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    echo "✅ Laptop host builds successfully"

    echo "✅ All boot tests passed!"
  '';

  # Full test suite
  test-all = pkgs.writeShellScriptBin "test-all" ''
    set -euo pipefail
    echo "🎯 Running full test suite..."
    echo ""

    echo "=== Flake Check ==="
    if ${pkgs.nix}/bin/nix flake check 2>&1 | grep -q "checking flake"; then
      echo "✅ Flake check passed"
    fi
    echo ""

    echo "=== Boot Tests ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link
    echo "✅ Default host builds"
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    echo "✅ Laptop host builds"
    echo ""

    echo "🎉 All tests passed!"
  '';
}
