# Implementation Plan: Flake-Parts Integration for Multi-Host NixOS

**Branch**: `001-flake-parts-integration` | **Date**: 2025-11-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-flake-parts-integration/spec.md`

## Summary

Migrate the existing 307-line monolithic flake.nix to a modular flake-parts structure while preserving all functionality and maintaining backward compatibility. The migration will use an incremental approach with three main phases: setup with escape hatch, migration of per-system outputs to `perSystem`, and migration of host configurations using `withSystem`. The target is ~280 lines total with improved organization split across `flake.nix` (30-50 lines), `flake-modules/hosts.nix` (~150 lines), and `flake-modules/outputs.nix` (~100 lines).

## Technical Context

**Language/Version**: Nix language with NixOS 25.11+ (nixpkgs-unstable)
**Primary Dependencies**:
- flake-parts (already in inputs)
- nixpkgs (stable for laptop)
- nixpkgs-unstable (for desktop and packages)
- hercules-ci/flake-parts framework
**Storage**: N/A (configuration management, no persistent storage)
**Testing**: Built-in NixOS evaluation, `nix flake check`, `nixos-rebuild build`, existing checks (format-check, lint-check, deadnix-check)
**Target Platform**: Linux x86_64 (desktop and laptop), with aarch64-linux support declared
**Project Type**: NixOS Configuration Management (infrastructure-as-code)
**Performance Goals**:
- Flake evaluation time within 5% of current baseline
- Build time under 5 minutes per host
- No degradation in check execution time
**Constraints**:
- Must maintain backward compatibility throughout migration
- All existing build commands must continue to work
- Zero functionality loss during and after migration
- Must pass all existing validation checks
**Scale/Scope**:
- 2 active hosts (desktop, laptop) + compatibility aliases (4 total configurations)
- 307 lines current flake.nix → ~280 lines modular structure
- 51 existing NixOS modules (unchanged)
- 7 package categories (unchanged)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ I. Modularity and Composability
**Status**: PASS - This feature explicitly enhances modularity

- ✅ Host configurations will remain in separate files with no duplication
- ✅ flake-parts modules are discrete with clear interfaces
- ✅ New directory structure (`flake-modules/`) follows established patterns
- ✅ Dependencies are explicitly documented in this plan

**Rationale**: This migration embodies the modularity principle by breaking down the 307-line monolithic flake.nix into focused, composable modules.

### ✅ II. Declarative Configuration
**Status**: PASS - No imperative modifications introduced

- ✅ All configuration remains in Nix expressions
- ✅ Migration is fully declarative (no runtime modifications)
- ✅ Reproducibility maintained throughout
- ✅ No changes to user-level configuration approach

**Rationale**: flake-parts is a declarative framework that enhances the declarative nature of the configuration.

### ✅ III. No Home Manager Policy
**Status**: PASS - Not applicable

- ✅ This feature does not involve user configuration
- ✅ Dotfiles system remains unchanged
- ✅ No Home Manager suggestions or usage

**Rationale**: This is a flake-level reorganization that doesn't touch user configuration.

### ✅ IV. Testing and Validation
**Status**: PASS - Testing strategy defined

- ✅ All existing checks (format-check, lint-check, eval-test) will be preserved
- ✅ Incremental migration allows testing at each step
- ✅ Both hosts must build successfully before each commit
- ✅ `nix flake check` must pass throughout
- ✅ No test infrastructure changes needed

**Rationale**: Incremental migration minimizes risk and allows validation at each step.

### ✅ V. Documentation and Maintainability
**Status**: PASS - Documentation plan included

- ✅ This plan documents the architectural change
- ✅ CLAUDE.md will be updated with new flake-parts patterns
- ✅ Inline documentation will be added to flake-modules
- ✅ Migration follows git workflow (feature branch)
- ✅ Commits will follow conventional commits format

**Rationale**: Comprehensive documentation ensures maintainability and knowledge transfer.

### Constitution Compliance: ✅ ALL GATES PASSED

No violations detected. This feature aligns perfectly with all constitution principles.

## Project Structure

### Documentation (this feature)

```text
specs/001-flake-parts-integration/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (flake-parts best practices)
├── data-model.md        # Phase 1 output (entity relationships)
├── quickstart.md        # Phase 1 output (migration guide)
└── checklists/
    └── requirements.md  # Spec validation (already complete)
```

### Source Code (repository root)

```text
# CURRENT STRUCTURE (preserved):
hosts/
├── desktop/
│   ├── configuration.nix       # Host-specific config (unchanged)
│   └── hardware-configuration.nix
└── laptop/
    ├── configuration.nix       # Host-specific config (unchanged)
    └── hardware-configuration.nix

modules/
├── core/                       # Core modules (unchanged)
├── hardware/                   # Hardware modules (unchanged)
├── networking/                 # Network modules (unchanged)
├── packages/                   # Package modules (unchanged)
├── desktop/                    # Desktop modules (unchanged)
└── roles/                      # Role modules (unchanged)

shells/                         # Development shells (unchanged)
tests/                          # Test infrastructure (unchanged)
lib/                           # Helper functions (unchanged)

# NEW STRUCTURE (to be created):
flake-modules/
├── hosts.nix                   # Host definitions and mkNixosSystem
│                               # (~150 lines: mkNixosSystem helper, hosts data, nixosConfigurations)
├── outputs.nix                 # Per-system outputs (checks, devShells, formatter, apps, packages)
│                               # (~100 lines: perSystem outputs)
└── README.md                   # Documentation for flake-modules structure

# MODIFIED FILES:
flake.nix                       # Entry point using mkFlake
                                # (from 307 lines → 30-50 lines: just imports and mkFlake wrapper)
```

**Structure Decision**: Preserve existing `hosts/` and `modules/` directories unchanged (respects constitution principle I and maintains existing architecture). Create new `flake-modules/` directory for flake-level configuration organization. This separates concerns:
- **flake.nix**: Entry point and coordination (minimal)
- **flake-modules/**: Flake-level output definitions
- **hosts/**: Host-specific NixOS configurations
- **modules/**: Reusable NixOS modules

**Total line count**: ~280 lines for flake code (down from 307), with significantly better organization and maintainability.

## Complexity Tracking

No constitution violations detected. This section intentionally left empty as no complexity justification is required.

## Phase 0: Research & Planning

### Research Completed ✅

Comprehensive research has been conducted covering:

1. **flake-parts Structure Patterns**: Directory-based + feature-oriented hybrid approach
2. **Migration Strategy**: Incremental migration with escape hatch for safety
3. **Per-Host Outputs**: Using `withSystem` for accessing `perSystem` context
4. **Multi-nixpkgs Support**: Per-host `nixpkgsInput` parameter with overlay options
5. **Shared Modules**: `flake.nixosModules` for reusability, imports for organization

**Key Findings**:
- Incremental migration via `flake` escape hatch minimizes risk
- `perSystem` eliminates `forAllSystems` boilerplate
- `withSystem` provides access to per-system packages in host configs
- Existing `hosts/` and `modules/` structure aligns perfectly with flake-parts patterns
- Migration can be completed in 3-4 commits with testing at each step

See [research.md](./research.md) for detailed findings.

### Research Decisions Summary

| Decision Point | Choice | Rationale |
|----------------|--------|-----------|
| Directory Structure | Hybrid: existing + `flake-modules/` | Preserves working structure, adds flake organization |
| Migration Strategy | Incremental with escape hatch | Minimizes risk, allows testing at each step |
| Per-System Outputs | `perSystem` for checks/devShells/etc | Eliminates boilerplate, cleaner code |
| Host Configurations | `withSystem` + `mkNixosSystem` | Access to per-system context, maintains flexibility |
| Multi-nixpkgs | Per-host `nixpkgsInput` param | Preserves existing desktop/laptop channel differences |
| Shared Modules | Import-based with optional `nixosModules` export | Clear, explicit, maintainable |

## Phase 1: Design & Contracts

### Data Model

See [data-model.md](./data-model.md) for complete entity relationship diagram and attribute definitions.

**Key Entities**:
1. **Flake-Parts Module**: Defines flake outputs, uses `perSystem` or `flake` attributes
2. **Host Definition**: Data structure describing a NixOS system (system, hostname, configPath, nixpkgsInput)
3. **Per-System Output**: System-specific outputs (checks, devShells, formatter, apps, packages) defined in `perSystem`
4. **NixOS Configuration**: Generated by `mkNixosSystem`, consumed by `nixos-rebuild`
5. **Shared Config Module**: Reusable flake-level configuration imported in flake.nix

### API/Interface Contracts

This is a configuration management system, not a service API. However, the "contracts" are the interfaces between components:

**Contract 1: flake.nix → flake-modules**
```nix
# Input: flake inputs
# Output: imports array of flake-modules
# Constraint: Each module must be valid flake-parts module

imports = [
  ./flake-modules/hosts.nix      # MUST export flake.nixosConfigurations
  ./flake-modules/outputs.nix    # MUST define perSystem outputs
];
```

**Contract 2: flake-modules/hosts.nix**
```nix
# Input: inputs (flake inputs), withSystem (flake-parts helper)
# Output: flake.nixosConfigurations (attrset of NixOS systems)
# Constraint: Each config must build successfully with nixos-rebuild

flake.nixosConfigurations = {
  desktop = <nixosSystem>;    # MUST: builds for x86_64-linux
  laptop = <nixosSystem>;     # MUST: builds for x86_64-linux
  nixos = <alias to desktop>; # MUST: identical to desktop
  nixos-desktop = <alias>;    # MUST: identical to desktop
  nixos-laptop = <alias>;     # MUST: identical to laptop
  default = <alias to desktop>; # MUST: identical to desktop
};
```

**Contract 3: flake-modules/outputs.nix**
```nix
# Input: inputs, perSystem context (pkgs, system, self', inputs')
# Output: perSystem outputs for each declared system
# Constraint: Must work for all systems in `systems = [ ... ]`

perSystem = { pkgs, system, self', inputs', ... }: {
  checks = {
    format-check = <derivation>;   # MUST: exits 0 if formatted
    lint-check = <derivation>;     # MUST: exits 0 if no lint issues
    deadnix-check = <derivation>;  # MUST: exits 0 if no dead code
  };
  formatter = pkgs.alejandra;      # MUST: executable
  devShells.default = <shell>;     # MUST: provides development tools
  apps = {
    format = { type = "app"; program = <path>; };      # MUST: valid app
    update = { type = "app"; program = <path>; };      # MUST: valid app
    check-config = { type = "app"; program = <path>; }; # MUST: valid app
  };
  packages = {
    deploy = <derivation>;         # MUST: script to deploy to host
    build = <derivation>;          # MUST: script to build for host
  };
};
```

**Contract 4: mkNixosSystem helper**
```nix
# Input: { system, hostname, configPath, nixpkgsInput?, extraModules?, extraSpecialArgs? }
# Output: nixosSystem derivation
# Constraint: Must produce bootable NixOS system

mkNixosSystem = { system, hostname, configPath, ... }:
  withSystem system ({ config, self', inputs', ... }:
    nixpkgsInput.lib.nixosSystem {
      inherit system;
      specialArgs = { /* MUST include: inputs, self', inputs', hostname, systemVersion, pkgs-unstable, stablePkgs */ };
      modules = [ /* MUST include: host config, base config */ ];
    }
  );
```

**Contract 5: Host Configuration Files**
```nix
# Input: specialArgs (inputs, self', inputs', pkgs-unstable, stablePkgs, hostname, etc.)
# Output: NixOS module
# Constraint: Must not rely on flake.nix internals

# hosts/desktop/configuration.nix
{ config, pkgs, self', inputs', pkgs-unstable, ... }:
{
  imports = [ /* NixOS modules from modules/ */ ];
  # Configuration...
}
```

See [contracts/](./contracts/) directory for formal schema definitions (if needed for tooling).

### Migration Quickstart Guide

See [quickstart.md](./quickstart.md) for step-by-step migration instructions with examples and testing procedures.

**Summary**: 4-phase migration over 3-4 commits:
1. **Setup**: Wrap outputs in `mkFlake`, add escape hatch
2. **Migrate perSystem**: Move checks/devShells/formatter/apps/packages
3. **Migrate Hosts**: Adapt `mkNixosSystem`, move to flake-modules/hosts.nix
4. **Cleanup**: Remove escape hatch, add documentation

Each phase maintains a working state and can be tested independently.

## Post-Design Constitution Re-Check

### ✅ I. Modularity and Composability
**Status**: PASS - Design enhances modularity

- ✅ flake-modules/ creates clear separation of concerns
- ✅ Each module has well-defined interface (contracts documented)
- ✅ Host configs remain independent and composable
- ✅ Cross-module dependencies minimized (only via imports)

**Evidence**: Design splits 307-line monolith into 3 focused files with explicit interfaces.

### ✅ II. Declarative Configuration
**Status**: PASS - Fully declarative design

- ✅ All changes are declarative Nix expressions
- ✅ No imperative scripts or manual steps in final state
- ✅ Configuration remains reproducible

**Evidence**: Migration itself may involve manual steps (creating files), but final state is fully declarative.

### ✅ III. No Home Manager Policy
**Status**: PASS - Not applicable

- ✅ Design does not touch user configuration
- ✅ No Home Manager usage or suggestions

**Evidence**: This is purely flake-level reorganization.

### ✅ IV. Testing and Validation
**Status**: PASS - Testing plan defined

- ✅ All existing checks preserved in perSystem.checks
- ✅ Incremental testing at each phase
- ✅ No new test infrastructure needed
- ✅ Validation commands documented in quickstart

**Evidence**: contracts/ defines expected test outcomes, quickstart.md includes test commands for each phase.

### ✅ V. Documentation and Maintainability
**Status**: PASS - Comprehensive documentation

- ✅ plan.md documents architecture (this file)
- ✅ research.md captures decision rationale
- ✅ data-model.md defines entities and relationships
- ✅ quickstart.md provides migration steps
- ✅ flake-modules/README.md will document module structure
- ✅ CLAUDE.md will be updated with flake-parts patterns

**Evidence**: 5 documentation files created, CLAUDE.md update planned.

### Final Constitution Compliance: ✅ ALL GATES PASSED

Design maintains compliance with all constitution principles. No violations introduced.

## Next Steps

This planning phase is complete. To proceed with implementation:

1. **Review this plan**: Ensure understanding of migration strategy and architecture
2. **Run `/speckit.tasks`**: Generate detailed task breakdown for implementation
3. **Execute migration**: Follow quickstart.md, test at each phase
4. **Update CLAUDE.md**: Document new flake-parts patterns for future reference

**Branch**: `001-flake-parts-integration` (already created and checked out)
**Artifacts Generated**:
- ✅ plan.md (this file)
- ✅ research.md (detailed research findings)
- ✅ data-model.md (entity relationships)
- ✅ quickstart.md (migration guide)
- ✅ contracts/ (interface definitions - if needed)

**Ready for**: Task generation via `/speckit.tasks` command
