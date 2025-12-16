# Quickstart: Flake-Parts Migration Guide

**Date**: 2025-11-24
**Feature**: 001-flake-parts-integration
**Purpose**: Step-by-step instructions for migrating from monolithic flake.nix to flake-parts structure

**Estimated Time**: 2-3 hours
**Skill Level**: Intermediate NixOS/Nix Flakes knowledge required

---

## Prerequisites

Before starting the migration:

1. ✅ Ensure your current configuration builds successfully:
   ```bash
   nix flake check
   nixos-rebuild build --flake .#desktop
   nixos-rebuild build --flake .#laptop
   ```

2. ✅ Commit all pending changes:
   ```bash
   git add -A
   git commit -m "chore: checkpoint before flake-parts migration"
   ```

3. ✅ Verify flake-parts input exists in flake.nix:
   ```nix
   inputs.flake-parts = {
     url = "github:hercules-ci/flake-parts";
     inputs.nixpkgs-lib.follows = "nixpkgs";
   };
   ```

4. ✅ Create feature branch (already done if running via /speckit workflow):
   ```bash
   git checkout -b 001-flake-parts-integration develop
   ```

---

## Phase 1: Setup & Escape Hatch (20 minutes)

### Goal
Wrap existing flake in `mkFlake` with escape hatch to preserve all functionality.

### Steps

**1.1. Backup current flake.nix**
```bash
cp flake.nix flake.nix.backup
```

**1.2. Create flake-modules directory**
```bash
mkdir -p flake-modules
```

**1.3. Modify flake.nix structure**

Replace the entire `outputs` section with:

```nix
{
  description = "NixOS configuration flake";

  inputs = {
    # ... keep all existing inputs unchanged ...
  };

  outputs = inputs @ { self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Declare supported systems
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Placeholder for future flake-modules imports
      imports = [
        # Will add: ./flake-modules/outputs.nix
        # Will add: ./flake-modules/hosts.nix
      ];

      # Escape hatch: preserve ALL existing outputs temporarily
      flake = let
        # Copy your ENTIRE current outputs implementation here
        # (everything from `supportedSystems` through the final attrset)
        
        # (See next step for what to copy)
        
      in {
        # Paste your current outputs here
        nixosConfigurations = # ...existing code...
        formatter = # ...existing code...
        checks = # ...existing code...
        apps = # ...existing code...
        devShells = # ...existing code...
      };
    };
}
```

**1.4. Copy existing outputs into escape hatch**

Take everything from your current `outputs = ... let ... in {` and put it inside the `flake = let ... in {` block. This means:
- Copy `supportedSystems`, `forAllSystems`, `pkgsConfig` definitions
- Copy `mkNixosSystem` helper function
- Copy `hosts` definition
- Copy all output generation (nixosConfigurations, formatter, checks, apps, devShells)

**1.5. Test Phase 1**
```bash
# Format code
alejandra .

# Check flake
nix flake check

# Verify outputs exist
nix flake show

# Test builds
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop

# Test other outputs
nix develop  # Should enter dev shell
nix fmt      # Should format code
nix run .#format  # Should run format app
```

**Expected Result**: Everything works exactly as before. No functional changes.

**1.6. Commit Phase 1**
```bash
git add flake.nix flake-modules/
git commit -m "feat(flake): setup flake-parts with escape hatch

- Wrap outputs in mkFlake
- Declare systems for x86_64-linux and aarch64-linux
- Create flake-modules/ directory for modular config
- Move existing outputs to escape hatch (no functional changes)
- Phase 1/4 of flake-parts migration

All tests passing: flake check, builds for desktop and laptop"
```

---

## Phase 2: Migrate Per-System Outputs (30 minutes)

### Goal
Move checks, devShells, formatter, apps, packages to `perSystem` in `flake-modules/outputs.nix`.

### Steps

**2.1. Create flake-modules/outputs.nix**

```nix
# flake-modules/outputs.nix
{ self, inputs, ... }: {
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    # Checks (replaces forAllSystems boilerplate)
    checks = {
      format-check = pkgs.runCommand "format-check" {} ''
        ${pkgs.alejandra}/bin/alejandra --check ${self} > $out 2>&1 || (
          echo "Formatting issues found. Run 'nix fmt' to fix."
          exit 1
        )
      '';

      lint-check = pkgs.runCommand "lint-check" {} ''
        ${pkgs.statix}/bin/statix check ${self} > $out 2>&1 || (
          echo "Lint issues found."
          exit 1
        )
      '';

      deadnix-check = pkgs.runCommand "deadnix-check" {} ''
        ${pkgs.deadnix}/bin/deadnix --fail ${self} > $out 2>&1 || (
          echo "Dead code found."
          exit 1
        )
      '';
    };

    # Formatter (no more forAllSystems!)
    formatter = pkgs.alejandra;

    # Development shell
    devShells.default = pkgs.mkShell {
      name = "nixos-config";
      buildInputs = with pkgs; [
        alejandra
        statix
        deadnix
        nixos-rebuild
        git
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

    # Apps
    apps = {
      format = {
        type = "app";
        program = toString (pkgs.writeShellScript "format" ''
          ${pkgs.alejandra}/bin/alejandra "$@"
        '');
      };

      update = {
        type = "app";
        program = toString (pkgs.writeShellScript "update" ''
          ${pkgs.nix}/bin/nix flake update
          echo "Flake inputs updated. Review changes with 'git diff flake.lock'"
        '');
      };

      check-config = {
        type = "app";
        program = toString (pkgs.writeShellScript "check-config" ''
          echo "Checking NixOS configuration..."
          ${pkgs.nix}/bin/nix flake check
        '');
      };
    };

    # Packages
    packages = {
      deploy = pkgs.writeShellScriptBin "deploy" ''
        set -e
        HOST=''${1:-desktop}
        echo "Deploying to $HOST..."
        nixos-rebuild switch --flake .#$HOST --target-host $HOST --use-remote-sudo
      '';

      build = pkgs.writeShellScriptBin "build" ''
        set -e
        HOST=''${1:-desktop}
        echo "Building configuration for $HOST..."
        nixos-rebuild build --flake .#$HOST
      '';
    };
  };
}
```

**2.2. Import outputs.nix in flake.nix**

In `flake.nix`, update the `imports` array:
```nix
imports = [
  ./flake-modules/outputs.nix
];
```

**2.3. Remove per-system outputs from escape hatch**

In `flake.nix`, in the `flake = let ... in {` block, remove:
- `checks = forAllSystems ...`
- `formatter = forAllSystems ...`
- `devShells = forAllSystems ...` (if present)
- `apps = forAllSystems ...` (if present)
- `packages = forAllSystems ...` (if present)

Keep ONLY `nixosConfigurations` in the escape hatch for now.

**2.4. Test Phase 2**
```bash
# Format
alejandra .

# Check flake
nix flake check

# Verify outputs
nix flake show | grep -E "(checks|formatter|devShells|apps|packages)"

# Test each output type
nix develop  # Dev shell should work
nix fmt flake.nix  # Formatter should work
nix run .#format  # App should work
nix run .#update  # App should work
nix run .#check-config  # App should work
nix build .#deploy  # Package should build
nix build .#build  # Package should build

# Verify checks run
nix flake check
```

**Expected Result**: All per-system outputs work. No more `forAllSystems` boilerplate.

**2.5. Commit Phase 2**
```bash
git add flake.nix flake-modules/outputs.nix
git commit -m "feat(flake): migrate per-system outputs to perSystem

- Create flake-modules/outputs.nix with perSystem outputs
- Move checks, formatter, devShells, apps, packages to perSystem
- Remove forAllSystems boilerplate (eliminated ~50 lines)
- nixosConfigurations still in escape hatch (migrate in Phase 3)
- Phase 2/4 of flake-parts migration

All tests passing: flake check, per-system outputs work"
```

---

## Phase 3: Migrate Host Configurations (60 minutes)

### Goal
Move `nixosConfigurations` to `flake-modules/hosts.nix` using `withSystem`.

### Steps

**3.1. Create flake-modules/hosts.nix**

```nix
# flake-modules/hosts.nix
{ self, inputs, withSystem, ... }: {
  flake.nixosConfigurations = let
    # Package configuration (shared across all hosts)
    pkgsConfig = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
      allowBroken = true;
    };

    # Helper function to create a NixOS system (adapted for flake-parts)
    mkNixosSystem = {
      system,
      hostname,
      configPath,
      nixpkgsInput ? inputs.nixpkgs,
      extraModules ? [],
      extraSpecialArgs ? {},
    }:
      withSystem system ({
        config,
        self',
        inputs',
        ...
      }: let
        # Get NixOS version dynamically
        systemVersion = let
          version = nixpkgsInput.lib.version;
          versionParts = builtins.splitVersion version;
          major = builtins.head versionParts;
          minor = builtins.elemAt versionParts 1;
        in "${major}.${minor}";

        # Create package sets
        pkgs = import nixpkgsInput {
          inherit system;
          config = pkgsConfig;
        };

        pkgs-unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = pkgsConfig;
        };

        # Special args - now with access to self' and inputs' from flake-parts
        baseSpecialArgs =
          {
            inherit inputs systemVersion system hostname;
            inherit self' inputs'; # From flake-parts perSystem
            pkgs-unstable = pkgs-unstable;
            stablePkgs = pkgs;
            # Can also pass: packages = config.packages; to access perSystem packages
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

                nix = {
                  settings = {
                    experimental-features = ["nix-command" "flakes"];
                    auto-optimise-store = true;
                  };
                  gc = {
                    automatic = true;
                    dates = "weekly";
                    options = nixpkgsInput.lib.mkDefault "--delete-older-than 7d";
                  };
                };

                system.stateVersion = systemVersion;
                networking.hostName = nixpkgsInput.lib.mkDefault hostname;
              }
            ]
            ++ extraModules;
        });

    # Define all hosts
    hosts = {
      desktop = {
        system = "x86_64-linux";
        hostname = "nixos-desktop";
        configPath = "desktop";
        nixpkgsInput = inputs.nixpkgs-unstable;
      };

      laptop = {
        system = "x86_64-linux";
        hostname = "nixos-laptop";
        configPath = "laptop";
        # Uses stable nixpkgs by default
      };
    };
  in
    inputs.nixpkgs.lib.mapAttrs (name: hostConfig: mkNixosSystem hostConfig) hosts
    // {
      # Compatibility aliases
      nixos = mkNixosSystem hosts.desktop;
      nixos-desktop = mkNixosSystem hosts.desktop;
      nixos-laptop = mkNixosSystem hosts.laptop;
      default = mkNixosSystem hosts.desktop;
    };
}
```

**3.2. Import hosts.nix in flake.nix**

In `flake.nix`, update the `imports` array:
```nix
imports = [
  ./flake-modules/outputs.nix
  ./flake-modules/hosts.nix
];
```

**3.3. Remove escape hatch from flake.nix**

Delete the entire `flake = let ... in { }` block from flake.nix. The file should now be very minimal:

```nix
{
  description = "NixOS configuration flake";

  inputs = {
    # ... all inputs ...
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./flake-modules/outputs.nix
        ./flake-modules/hosts.nix
      ];
    };
}
```

**3.4. Test Phase 3 (CRITICAL)**
```bash
# Format
alejandra .

# Check flake structure
nix flake show

# CRITICAL: Test both hosts build
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop

# Test aliases
nixos-rebuild build --flake .#nixos
nixos-rebuild build --flake .#nixos-desktop
nixos-rebuild build --flake .#nixos-laptop
nixos-rebuild build --flake .#default

# Full flake check
nix flake check

# Test per-system outputs still work
nix develop
nix fmt flake.nix
nix run .#format
```

**Expected Result**: Both hosts build successfully. All aliases work. All outputs function.

**3.5. Commit Phase 3**
```bash
git add flake.nix flake-modules/hosts.nix
git commit -m "feat(flake): migrate nixosConfigurations to flake-parts

- Create flake-modules/hosts.nix with nixosConfigurations
- Adapt mkNixosSystem to use withSystem for perSystem access
- Add self' and inputs' to specialArgs for host configs
- Remove escape hatch - full migration to flake-parts complete
- flake.nix reduced from 307 lines to ~30 lines
- Phase 3/4 of flake-parts migration

All tests passing: desktop and laptop build successfully"
```

---

## Phase 4: Documentation & Polish (30 minutes)

### Goal
Add documentation and verify everything works.

### Steps

**4.1. Create flake-modules/README.md**

```bash
cat > flake-modules/README.md << 'EOF'
# Flake Modules

This directory contains modular flake-parts configuration for the NixOS system.

## Structure

- **hosts.nix**: NixOS host configurations (nixosConfigurations output)
  - Defines `hosts` attrset with desktop and laptop
  - `mkNixosSystem` helper function
  - Generates nixosConfigurations using `withSystem`
  - Adds compatibility aliases

- **outputs.nix**: Per-system outputs (checks, devShells, formatter, apps, packages)
  - Defines `perSystem` outputs for each supported system
  - Eliminates `forAllSystems` boilerplate
  - Provides access to `self'` and `inputs'` for cross-references

## Adding a New Host

1. Create host config: `hosts/newhost/configuration.nix`
2. Add to `hosts` in `hosts.nix`:
   ```nix
   newhost = {
     system = "x86_64-linux";
     hostname = "nixos-newhost";
     configPath = "newhost";
     nixpkgsInput = inputs.nixpkgs;  # or nixpkgs-unstable
   };
   ```
3. Build: `nixos-rebuild build --flake .#newhost`

## Adding Per-System Outputs

Edit `outputs.nix` and add to the appropriate section:
- Checks: `perSystem.checks.<name> = ...`
- Dev shells: `perSystem.devShells.<name> = ...`
- Apps: `perSystem.apps.<name> = ...`
- Packages: `perSystem.packages.<name> = ...`

No need for `forAllSystems` - it's automatic!

## Benefits

- **Less boilerplate**: No more `forAllSystems` everywhere
- **Better organization**: Clear separation of concerns
- **Access to perSystem**: Hosts can reference `self'` and `inputs'`
- **Easier maintenance**: Adding hosts and outputs is simpler
- **Flake schema validation**: flake-parts ensures correct structure
EOF
```

**4.2. Update CLAUDE.md**

Add a new section to `CLAUDE.md` after the "Architecture Overview" section:

```markdown
### Flake-Parts Structure

The flake uses **flake-parts** for modular organization:

- **flake.nix**: Entry point (~30 lines) - declares systems and imports modules
- **flake-modules/hosts.nix**: Host definitions and nixosConfigurations
- **flake-modules/outputs.nix**: Per-system outputs (checks, devShells, formatter, apps, packages)

**Benefits**:
- No `forAllSystems` boilerplate
- Clear separation of flake-level, per-system, and host configuration
- Access to `self'` and `inputs'` for cleaner cross-references
- Easier to add new hosts and outputs

**Adding a new host**:
1. Create `hosts/newhost/configuration.nix`
2. Add entry to `hosts` attrset in `flake-modules/hosts.nix`
3. Build with `nixos-rebuild build --flake .#newhost`

See `flake-modules/README.md` for details.
```

**4.3. Measure improvements**

```bash
# Line count comparison
echo "Old flake.nix: $(wc -l flake.nix.backup | awk '{print $1}') lines"
echo "New flake.nix: $(wc -l flake.nix | awk '{print $1}') lines"
echo "flake-modules/hosts.nix: $(wc -l flake-modules/hosts.nix | awk '{print $1}') lines"
echo "flake-modules/outputs.nix: $(wc -l flake-modules/outputs.nix | awk '{print $1}') lines"
echo "Total modular: $(cat flake.nix flake-modules/*.nix | wc -l | awk '{print $1}') lines"

# Performance comparison (evaluation time)
echo "Evaluation time before:"
time nix flake show --legacy > /dev/null 2>&1

echo "Evaluation time after (using backup):"
cp flake.nix flake.nix.new
cp flake.nix.backup flake.nix
time nix flake show --legacy > /dev/null 2>&1
cp flake.nix.new flake.nix
```

**4.4. Final validation**

Run the complete test suite:

```bash
# Formatting
alejandra .

# All checks
nix flake check

# Build all configurations
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop

# Test all aliases
nixos-rebuild build --flake .#nixos
nixos-rebuild build --flake .#default

# Test per-system outputs
nix develop --command echo "Dev shell works"
nix fmt flake.nix
nix run .#format -- --version
nix run .#update -- --version
nix run .#check-config
nix build .#deploy
nix build .#build

# Verify flake metadata
nix flake metadata
nix flake show
```

**Expected Result**: Everything passes. System is fully migrated.

**4.5. Commit Phase 4**

```bash
git add flake-modules/README.md CLAUDE.md flake.nix.backup
git commit -m "docs(flake): document flake-parts migration

- Add flake-modules/README.md with usage guide
- Update CLAUDE.md with flake-parts structure explanation
- Keep flake.nix.backup for reference
- Phase 4/4 of flake-parts migration complete

Migration results:
- flake.nix: 307 → ~30 lines (-90%)
- Total: ~280 lines across 3 organized files
- All tests passing, zero functionality loss
- Evaluation time within 5% of baseline"
```

**4.6. Cleanup (optional)**

```bash
# Remove backup after confirming everything works
rm flake.nix.backup

git add flake.nix.backup
git commit -m "chore: remove flake.nix backup after successful migration"
```

---

## Verification Checklist

After completing all phases, verify:

- [ ] `nix flake check` passes
- [ ] `nix flake show` displays all outputs correctly
- [ ] Desktop builds: `nixos-rebuild build --flake .#desktop`
- [ ] Laptop builds: `nixos-rebuild build --flake .#laptop`
- [ ] All aliases work (nixos, nixos-desktop, nixos-laptop, default)
- [ ] Dev shell works: `nix develop`
- [ ] Formatter works: `nix fmt flake.nix`
- [ ] Apps work: `nix run .#format`, `nix run .#update`, `nix run .#check-config`
- [ ] Packages build: `nix build .#deploy`, `nix build .#build`
- [ ] Evaluation time is within 5% of baseline
- [ ] flake.nix is ~30 lines (from 307)
- [ ] Total lines across flake code is ~280
- [ ] Documentation updated (CLAUDE.md, flake-modules/README.md)
- [ ] All commits follow conventional commits format
- [ ] Feature branch ready for PR to develop

---

## Troubleshooting

### Issue: infinite recursion error

**Cause**: Using `_module.args` instead of `specialArgs` in `mkNixosSystem`.

**Fix**: Ensure you're passing `self'` and `inputs'` via `specialArgs`, not `_module.args`.

### Issue: checks fail with "path not found"

**Cause**: `${self}` in checks might not expand correctly in perSystem.

**Fix**: Use `${./.}` or pass `flakeRoot` as a parameter if needed.

### Issue: host doesn't build after migration

**Cause**: Missing `specialArgs` or incorrect `withSystem` usage.

**Fix**: 
1. Check that `mkNixosSystem` uses `withSystem` correctly
2. Verify all required `specialArgs` are passed (inputs, systemVersion, etc.)
3. Ensure `nixpkgsInput` is valid for that host

### Issue: "attribute 'nixosConfigurations' missing"

**Cause**: `hosts.nix` not imported or has syntax error.

**Fix**:
1. Verify `imports = [ ./flake-modules/hosts.nix ];` in flake.nix
2. Check `hosts.nix` for syntax errors with `nix flake check`

### Issue: evaluation is significantly slower

**Cause**: Possible inefficiency in `withSystem` usage or package set creation.

**Fix**:
1. Profile with `nix flake show --profile-file profile.json`
2. Consider caching package sets if created multiple times
3. Ensure you're not importing nixpkgs redundantly

---

## Next Steps

After successful migration:

1. **Test on actual hardware** (if not already done):
   ```bash
   sudo nixos-rebuild switch --flake .#desktop
   # Verify system boots and works correctly
   ```

2. **Create Pull Request** to merge feature branch to develop:
   ```bash
   git push origin 001-flake-parts-integration
   # Create PR: 001-flake-parts-integration → develop
   ```

3. **Merge to develop** after review and testing on both hosts

4. **Eventually merge to main** when stable

5. **Future enhancements**:
   - Add more hosts easily (servers, VMs, etc.)
   - Create reusable NixOS modules via `flake.nixosModules`
   - Add CI/CD checks for each host
   - Create per-host development shells
   - Add deployment automation

---

## Summary

You've successfully migrated your NixOS flake to flake-parts! 🎉

**Achievements**:
- ✅ Reduced flake.nix from 307 lines to ~30 (-90%)
- ✅ Organized code into focused modules
- ✅ Eliminated `forAllSystems` boilerplate
- ✅ Added access to `self'` and `inputs'` for better ergonomics
- ✅ Maintained 100% backward compatibility
- ✅ Zero functionality loss
- ✅ Improved maintainability and scalability

**What changed**:
- flake.nix: Entry point with imports
- flake-modules/outputs.nix: Per-system outputs
- flake-modules/hosts.nix: Host configurations
- No changes to hosts/, modules/, or any other directories

**What stayed the same**:
- All build commands work identically
- All host configurations unchanged
- All NixOS modules unchanged
- All existing functionality preserved

Congratulations! Your configuration is now more maintainable and easier to extend.
