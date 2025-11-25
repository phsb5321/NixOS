# Research: Flake-Parts Integration Patterns

**Date**: 2025-11-24
**Feature**: 001-flake-parts-integration
**Purpose**: Research best practices and patterns for migrating a monolithic flake.nix to flake-parts modular structure

---

## 1. Structuring flake-parts Modules in a NixOS Multi-Host Setup

**Decision**: Use a **hybrid directory-based + feature-oriented structure** with separate directories for `hosts/`, `modules/`, and `flake-modules/` for flake-level configuration.

**Rationale**:
- Your existing structure (`hosts/`, `modules/`) already follows community best practices and aligns well with flake-parts patterns
- The "Dendritic Pattern" (every file is a flake-parts module) is gaining traction but requires significant restructuring
- A hybrid approach balances modularity with maintainability while preserving your existing organization
- flake-parts works best when you separate concerns: host configs → `flake.nixosConfigurations`, reusable modules → `flake.nixosModules`, per-system outputs → `perSystem`

**Alternatives considered**:
1. **Fully Dendritic Pattern**: Every file becomes a flake-parts module with imports for automatic discovery (e.g., using `import-tree` or similar). Rejected because it requires complete restructuring and has a steeper learning curve for collaborators.
2. **Flat structure in flake.nix**: Keep all logic in `flake.nix` with minimal modularization. Rejected because it defeats the purpose of flake-parts and doesn't scale.
3. **Directory-based auto-wiring** (like `srid/nixos-config` with ez-configs): Automatically generate outputs from directory structure. Rejected because it adds magic/indirection that may be harder to debug.

**Implementation notes**:
```nix
# Recommended structure:
flake.nix                      # Entry point using mkFlake
flake-modules/
  hosts.nix                    # Host definitions and mkNixosSystem logic
  outputs.nix                  # System-agnostic outputs (apps, packages, checks)
hosts/
  desktop/configuration.nix    # Host-specific configs (unchanged)
  laptop/configuration.nix
modules/
  core/                        # NixOS modules (unchanged)
  packages/
  hardware/
```

Key principle: **Put flake-level configuration in `flake-modules/`, NixOS module configuration in `modules/`, host-specific overrides in `hosts/`**

---

## 2. Migrating from Monolithic flake.nix to flake-parts

**Decision**: Use **incremental migration** with the `flake` attribute to preserve backward compatibility during transition.

**Rationale**:
- Incremental migration minimizes risk and allows testing at each step
- The `flake` attribute acts as an escape hatch for outputs that haven't been migrated yet
- You can migrate system-specific outputs (`checks`, `devShells`, `formatter`, `apps`, `packages`) to `perSystem` first, then tackle `nixosConfigurations` later
- This approach maintains working configurations throughout the migration

**Alternatives considered**:
1. **Big-bang rewrite**: Migrate everything at once. Rejected due to high risk and difficulty troubleshooting if something breaks.
2. **Parallel systems**: Keep old flake.nix and create new flake-parts.nix side-by-side. Rejected because it creates maintenance burden and confusion.
3. **No migration**: Stick with current monolithic approach. Rejected because flake-parts provides significant benefits for maintainability and reducing boilerplate.

**Implementation notes**:

**Step 1: Initial Setup** (preserve all existing functionality)
```nix
{
  outputs = inputs @ { self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Declare supported systems
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Import modular flake configuration
      imports = [
        ./flake-modules/hosts.nix
        ./flake-modules/outputs.nix
      ];

      # Escape hatch: preserve existing outputs during migration
      flake = {
        # Temporarily keep your current nixosConfigurations here
        # Move to flake-modules/hosts.nix incrementally
      };
    };
}
```

**Migration checklist**:
1. ✅ Add flake-parts input (already done in your config)
2. ✅ Wrap outputs in `mkFlake`
3. ✅ Declare `systems = [ "x86_64-linux" "aarch64-linux" ];`
4. ✅ Create `flake-modules/` directory
5. ✅ Migrate `perSystem` outputs first (checks, devShells, formatter, apps, packages)
6. ✅ Test: `nix flake check`, `nix develop`, `nix fmt`
7. ✅ Migrate `nixosConfigurations` using `withSystem`
8. ✅ Test: `nixos-rebuild build --flake .#desktop`
9. ✅ Remove escape hatch `flake = { }` when all outputs migrated
10. ✅ Final validation: `nix flake check` and system rebuilds

---

## 3. Per-Host Output Definitions in flake-parts

**Decision**: Use **`withSystem` for per-host nixosConfigurations** while keeping the host definition data structure (your `hosts = { ... }` pattern) for maintainability.

**Rationale**:
- `withSystem` provides access to `perSystem` context (packages, checks, etc.) for each host's system architecture
- Your existing `hosts` data structure is clean and declarative - it should be preserved
- This pattern allows each host to reference system-specific packages/apps defined in `perSystem`
- Maintains backward compatibility with existing host configuration files

**Alternatives considered**:
1. **Direct `nixpkgs.lib.nixosSystem` without `withSystem`**: Simpler but loses access to `perSystem` packages/config. Rejected because it doesn't leverage flake-parts benefits.
2. **`moduleWithSystem` for each host**: More complex, intended for reusable modules not host configs. Rejected because it's overkill for host definitions.
3. **Auto-generation from directory structure** (ez-configs pattern): Creates configs automatically from `hosts/*/default.nix`. Rejected because it's too magical and your explicit `hosts = { ... }` structure is clearer.

**Implementation notes**:

Key pattern for accessing `perSystem` outputs in host configs:
```nix
# In flake-modules/hosts.nix
mkNixosSystem = { system, ... }:
  withSystem system ({ config, self', inputs', pkgs, ... }:
    # Now you have access to:
    # - config.packages (perSystem packages for this system)
    # - self'.packages.foo (shorthand for self.packages.${system}.foo)
    # - inputs'.someInput.packages.bar (system-specific input packages)
    # - pkgs (from perSystem, respects overlays)

    nixpkgsInput.lib.nixosSystem {
      specialArgs = {
        inherit self' inputs';  # Pass these to host modules
        packages = config.packages;  # Access to perSystem packages
        # ... other args
      };
      modules = [ ... ];
    }
  );
```

**Important**: Use `specialArgs` (not `_module.args`) because it works in module `imports`, avoiding infinite recursion.

---

## 4. Handling Different nixpkgs Inputs Per Host

**Decision**: Use **per-host `nixpkgsInput` parameter with overlay-based unstable access** for packages that need different nixpkgs versions.

**Rationale**:
- Your current approach (desktop uses `nixpkgs-unstable`, laptop uses `nixpkgs` stable) is already sound
- flake-parts doesn't change this - you still pass different `nixpkgsInput` to each host
- For accessing both stable/unstable packages in the same system, use overlays or `specialArgs` to pass multiple package sets
- The `easyOverlay` module in flake-parts can help but has limitations with `allowUnfree` predicates

**Alternatives considered**:
1. **Single nixpkgs for all hosts with overlays**: All hosts use one nixpkgs input, use overlays to cherry-pick unstable packages. Rejected because desktop wants bleeding-edge by default.
2. **flake-parts `easyOverlay` module**: Makes `pkgs.unstable` available via overlay. Partially accepted - good for selective unstable packages, but not for whole-system channel differences.
3. **System-wide `pkgs` override in perSystem**: Set `perSystem._module.args.pkgs` per system. Rejected because it doesn't allow per-host differences.

**Implementation notes**:

**Approach 1: Per-host nixpkgs (your current approach - preserve it)**
```nix
# flake-modules/hosts.nix
hosts = {
  desktop = {
    nixpkgsInput = inputs.nixpkgs-unstable;  # Bleeding edge
    # ...
  };
  laptop = {
    nixpkgsInput = inputs.nixpkgs;  # Stable
    # ...
  };
};
```

**Approach 2: Multiple package sets via specialArgs** (most flexible)
```nix
# In mkNixosSystem helper:
pkgs-stable = import inputs.nixpkgs { inherit system; config = pkgsConfig; };
pkgs-unstable = import inputs.nixpkgs-unstable { inherit system; config = pkgsConfig; };

specialArgs = {
  pkgs = if useUnstable then pkgs-unstable else pkgs-stable;
  pkgs-stable = pkgs-stable;
  pkgs-unstable = pkgs-unstable;
  # Now modules can choose: with pkgs; [ firefox ] vs. with pkgs-unstable; [ firefox ]
};
```

**Recommendation**: Keep your per-host `nixpkgsInput` approach + add overlay for cases where a host needs selective packages from the other channel.

---

## 5. Shared/Common flake-parts Modules Across Hosts

**Decision**: Use **`flake.nixosModules` for reusable NixOS configuration**, keep per-system logic in `perSystem`, and use imports in `flake.nix` for flake-level modularity.

**Rationale**:
- Your existing `modules/` directory already contains shared NixOS modules - these don't change with flake-parts
- `flake.nixosModules` exposes reusable modules for use in this flake or others
- Flake-level configuration (like common output definitions) should be in `flake-modules/` and imported in `flake.nix`
- This creates clear separation: flake config vs. NixOS config vs. per-system outputs

**Alternatives considered**:
1. **Everything in flake.nix**: No modular files, all logic inline. Rejected due to maintainability issues.
2. **Dendritic pattern**: Every file is a flake-parts module with auto-discovery. Rejected due to complexity and learning curve.
3. **Module-per-output-type**: Separate `flake-modules/checks.nix`, `flake-modules/devshells.nix`, etc. Partially accepted - good for large configs, may be overkill for yours.

**Implementation notes**:

**Pattern 1: Flake-level modular configuration** (for organizing flake.nix)
```nix
# flake.nix
{
  outputs = inputs @ { self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Import flake-level modules (these define outputs)
      imports = [
        ./flake-modules/hosts.nix      # nixosConfigurations
        ./flake-modules/outputs.nix    # checks, devShells, apps, packages, formatter
      ];
    };
}
```

**Best practices**:
1. **NixOS modules stay in `modules/`** - no need to move them
2. **Flake-level config goes in `flake-modules/`** - for organizing flake.nix
3. **Export commonly used modules via `flake.nixosModules`** - for reusability
4. **Use `moduleWithSystem` only when needed** - most modules don't need perSystem access
5. **Keep host configs in `hosts/`** - they import from `modules/` as before

---

## Summary: Recommended Migration Path

### Phase 1: Setup (Low Risk)
1. Create `flake-modules/` directory
2. Wrap existing outputs in `mkFlake` with `flake = { }` escape hatch
3. Add `systems = [ "x86_64-linux" "aarch64-linux" ];`
4. Test: existing functionality should still work

### Phase 2: Migrate Per-System Outputs (Medium Risk)
1. Create `flake-modules/outputs.nix` with `perSystem` definitions
2. Move `checks`, `devShells`, `formatter`, `apps`, `packages` to `perSystem`
3. Remove `forAllSystems` boilerplate
4. Test: `nix flake check`, `nix develop`, `nix fmt`, `nix run .#format`

### Phase 3: Migrate Host Configurations (Higher Risk)
1. Create `flake-modules/hosts.nix`
2. Adapt `mkNixosSystem` to use `withSystem`
3. Pass `self'`, `inputs'`, and per-system `packages` via `specialArgs`
4. Move `hosts` definition and `nixosConfigurations` generation
5. Test: `nixos-rebuild build --flake .#desktop` for each host

### Phase 4: Cleanup & Polish (Low Risk)
1. Remove `flake = { }` escape hatch
2. Consider exposing modules via `flake.nixosModules`
3. Add overlays if needed for stable/unstable mixing
4. Update documentation

### Benefits Achieved
- ✅ No more `forAllSystems` boilerplate
- ✅ Clear separation: flake config, NixOS modules, per-system outputs
- ✅ Better modularity and reusability
- ✅ Access to `self'` and `inputs'` for cleaner cross-references
- ✅ Foundation for future enhancements (CI/CD, more hosts, etc.)
- ✅ Maintains backward compatibility throughout migration

### Key Files After Migration
```
flake.nix                      # 30-50 lines (just mkFlake + imports)
flake-modules/
  hosts.nix                    # ~150 lines (mkNixosSystem + hosts def)
  outputs.nix                  # ~100 lines (perSystem outputs)
hosts/                         # Unchanged
modules/                       # Unchanged
```

**Total estimated size**: ~280 lines of flake code (down from 307), but with much better organization and maintainability.
