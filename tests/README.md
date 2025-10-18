# NixOS Configuration Tests

This directory contains testing infrastructure for the NixOS configuration.

## Test Categories

### Formatting Tests (`formatting.nix`)
- **format-check**: Check if all Nix files are properly formatted with Alejandra
- **format-fix**: Auto-format all Nix files
- **lint-check**: Run Nix linting checks
- **pre-commit-check**: Combined formatting and linting checks

### Boot Tests (`boot-test.nix`)
- **boot-test-default**: Test default (desktop) host boot configuration
- **boot-test-laptop**: Test laptop host boot configuration
- **boot-test-all**: Test all hosts
- **vm-test-default**: Create a VM for testing
- **eval-test**: Test system evaluation
- **test-all**: Full test suite

## Running Tests

### Using Nix Flake Packages

```bash
# Formatting checks
nix run .#format-check
nix run .#format-fix

# Boot tests
nix run .#boot-test
nix run .#test-all
```

### Manual Testing

```bash
# Check flake
nix flake check

# Build specific host
nix build .#nixosConfigurations.default.config.system.build.toplevel
nix build .#nixosConfigurations.laptop.config.system.build.toplevel

# Format code
alejandra .

# Create test VM
nix build .#nixosConfigurations.default.config.system.build.vm
./result/bin/run-*-vm
```

## CI/CD Integration

These tests are designed to be run in CI/CD pipelines:

```yaml
# Example GitHub Actions workflow
- name: Check formatting
  run: nix run .#format-check

- name: Run tests
  run: nix run .#test-all
```

## Pre-commit Hooks

For local development, you can set up pre-commit hooks:

```bash
# Add to .git/hooks/pre-commit
#!/usr/bin/env bash
nix run .#format-check
```

## Test Coverage

- ✅ Nix code formatting (Alejandra)
- ✅ Flake syntax validation
- ✅ Host configuration builds
- ✅ System evaluation
- 🔄 VM testing (manual)
- 🔄 Integration tests (future)
- 🔄 Module unit tests (future)
