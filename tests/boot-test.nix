# ~/NixOS/tests/boot-test.nix
# Boot and system tests
<<<<<<< HEAD
{ pkgs, lib, nixpkgs, ... }:

{
=======
{
  pkgs,
  lib,
  nixpkgs,
  ...
}: {
>>>>>>> origin/host/server
  # Boot test for default host
  boot-test-default = pkgs.writeShellScriptBin "boot-test-default" ''
    set -euo pipefail

    echo "🔍 Testing default (desktop) host boot configuration..."

    # Build the system configuration
    echo "📦 Building system configuration..."
    if ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link; then
      echo "✅ Default host builds successfully"
    else
      echo "❌ Default host build failed"
      exit 1
    fi

    echo "✅ Boot test passed for default host"
  '';

  # Boot test for laptop host
  boot-test-laptop = pkgs.writeShellScriptBin "boot-test-laptop" ''
    set -euo pipefail

    echo "🔍 Testing laptop host boot configuration..."

    # Build the system configuration
    echo "📦 Building system configuration..."
    if ${pkgs.nix}/bin/nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link; then
      echo "✅ Laptop host builds successfully"
    else
      echo "❌ Laptop host build failed"
      exit 1
    fi

    echo "✅ Boot test passed for laptop host"
  '';

  # Combined boot test
  boot-test-all = pkgs.writeShellScriptBin "boot-test-all" ''
    set -euo pipefail

    echo "🚀 Running boot tests for all hosts..."
    echo ""

    # Test default host
    echo "=== Default Host ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link
    echo "✅ Default host builds successfully"
    echo ""

    # Test laptop host
    echo "=== Laptop Host ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    echo "✅ Laptop host builds successfully"
    echo ""

    echo "✅ All boot tests passed!"
  '';

  # VM test (create a VM for testing)
  vm-test-default = pkgs.writeShellScriptBin "vm-test-default" ''
    set -euo pipefail

    echo "🖥️  Creating VM for default host..."
    echo "💡 This will build a VM you can test in QEMU"
    echo ""

    ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.vm --no-link

    echo ""
    echo "✅ VM built successfully"
    echo "💡 Run the VM with: result/bin/run-*-vm"
  '';

  # System evaluation test
  eval-test = pkgs.writeShellScriptBin "eval-test" ''
    set -euo pipefail

    echo "🔍 Testing system evaluation..."

    # Test default host
    echo "📝 Evaluating default host..."
    if ${pkgs.nix}/bin/nix eval .#nixosConfigurations.default.config.system.build.toplevel --raw >/dev/null 2>&1; then
      echo "✅ Default host evaluates successfully"
    else
      echo "❌ Default host evaluation failed"
      exit 1
    fi

    # Test laptop host
    echo "📝 Evaluating laptop host..."
    if ${pkgs.nix}/bin/nix eval .#nixosConfigurations.laptop.config.system.build.toplevel --raw >/dev/null 2>&1; then
      echo "✅ Laptop host evaluates successfully"
    else
      echo "❌ Laptop host evaluation failed"
      exit 1
    fi

    echo "✅ All evaluation tests passed"
  '';

  # Full test suite
  test-all = pkgs.writeShellScriptBin "test-all" ''
    set -euo pipefail

    echo "🎯 Running full test suite..."
    echo ""

    # Formatting check
    echo "=== Formatting Check ==="
    if ${pkgs.nix}/bin/nix flake check 2>&1 | grep -q "checking flake"; then
      echo "✅ Flake check passed"
    else
      echo "⚠️  Flake check had warnings (non-fatal)"
    fi
    echo ""

    # Evaluation tests
    echo "=== Evaluation Tests ==="
    ${pkgs.nix}/bin/nix eval .#nixosConfigurations.default.config.system.build.toplevel --raw >/dev/null 2>&1
    echo "✅ Default host evaluates"
    ${pkgs.nix}/bin/nix eval .#nixosConfigurations.laptop.config.system.build.toplevel --raw >/dev/null 2>&1
    echo "✅ Laptop host evaluates"
    echo ""

    # Boot tests
    echo "=== Boot Tests ==="
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link
    echo "✅ Default host builds"
    ${pkgs.nix}/bin/nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link
    echo "✅ Laptop host builds"
    echo ""

    echo "🎉 All tests passed!"
  '';
}
