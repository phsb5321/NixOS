# Implementation Plan: NixOS Codebase Optimization & Reduction

**Branch**: `002-codebase-reduction` | **Date**: 2025-11-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/home/notroot/NixOS/specs/002-codebase-reduction/spec.md`

## Summary

This feature reduces the NixOS codebase by 25% (~1457 lines from 5827 total) while maintaining 100% feature parity through three strategies: (1) consolidating overlapping modules, (2) extracting reusable helper functions, and (3) optimizing verbose option definitions. The approach follows NixOS best practices, maintains declarative configuration, respects the constitution's no-Home-Manager policy, and ensures both desktop and laptop configurations continue to build successfully.

## Technical Context

**Language/Version**: Nix 2.31.2 (functional, lazy evaluation)
**Primary Dependencies**: nixpkgs 25.11 (nixos-unstable), flake-parts 1.0
**Storage**: Git repository, `/nix/store` (immutable store)
**Testing**: `nix flake check` (format/lint/eval), `nixos-rebuild build` (integration)
**Target Platform**: NixOS Linux (desktop: x86_64-linux, laptop: x86_64-linux)
**Project Type**: System configuration (NixOS modules, declarative infrastructure)
**Performance Goals**: Build time <5 minutes per host, module evaluation <10s
**Constraints**: 100% feature parity (FR-001), both hosts must build (FR-002), all checks pass (FR-003)
**Scale/Scope**: ~5827 lines across 57 modules, 2 host configurations (desktop/laptop)

**Current Codebase Analysis**:
- Total: 5827 lines across all .nix files
- Modules: 57 files in 11 categories
- Largest modules: core/default.nix (415L), hardware/laptop.nix (407L), document-tools.nix (398L)
- Duplication identified: networking (core + networking dirs), laptop config split
- Helper opportunity: 10+ repeated option patterns (enable/package/extraPackages)

**Target Reductions by Phase**:
- P1 (Consolidation): ~875 lines (15% of total)
- P2 (Helper extraction): ~583 lines (10% of total)
- P3 (Optimization): ~291 lines (5% of total)
- **Total**: ~1749 lines (30% with buffer, target 25% = 1457 lines)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Modularity and Composability ✅ ALIGNED

**Compliance Check**:
- ✅ Preserves independent module configurability
- ✅ Maintains clear module interfaces with explicit options
- ✅ Follows directory structure (core/, networking/, packages/, etc.)
- ✅ Minimizes cross-module dependencies (tracks via consolidation plan)

**Enhancement**: Consolidation IMPROVES modularity by grouping semantically related configs (e.g., networking modules) rather than scattering them across directories.

**Potential Concern**: Merging modules might reduce granularity
**Mitigation**: Only consolidate modules with semantic overlap; preserve distinct modules for different concerns

### Principle II: Declarative Configuration ✅ MAINTAINED

**Compliance Check**:
- ✅ All changes remain in Nix expressions (declarative)
- ✅ No imperative system modifications introduced
- ✅ Maintains reproducibility from repository
- ✅ Hardware configs untouched
- ✅ Nix shells approach preserved

**No Violations**: This is pure refactoring of declarative code. No new imperative constructs.

### Principle III: No Home Manager Policy ✅ RESPECTED

**Compliance Check**:
- ✅ User config remains in chezmoi dotfiles (`~/NixOS/dotfiles/`)
- ✅ Zero mentions of Home Manager in spec or plan
- ✅ Dotfiles module optimization preserves chezmoi integration
- ✅ System vs. user config boundary maintained

**Explicit Protection**: Spec "Out of Scope" explicitly excludes Home Manager. Constitution principle fully respected.

### Principle IV: Testing and Validation ✅ STRENGTHENED

**Compliance Check**:
- ✅ Flake checks enforced after each phase (format/lint/eval)
- ✅ Both hosts build before merge (desktop + laptop)
- ✅ Ale jandra formatting enforced
- ✅ GPU fallback variants preserved
- ✅ Can use `nixswitch` for safe rebuilds

**Enhancement**: Feature adds explicit before/after validation (FR-009, SC-009) comparing system derivations and enabled services.

### Principle V: Documentation and Maintainability ✅ IMPROVED

**Compliance Check**:
- ✅ CLAUDE.md updated with new structure (SC-010)
- ✅ Helper functions documented with docstrings (FR-005)
- ✅ Follows git workflow (feature branch `002-codebase-reduction`)
- ✅ Conventional commits (refactor/feat/docs)

**Enhancement**: Reducing code size and improving organization DIRECTLY improves maintainability (core goal, SC-007).

### Overall Assessment: ✅ FULLY COMPLIANT - PROCEED

**Summary**:
- All 5 core principles aligned or enhanced
- No violations requiring justification
- Feature actively improves Principles I (modularity) and V (maintainability)
- No constitutional amendments needed

**Gates**: ✅ **PASS** - Approved to proceed with Phase 0 research

## Project Structure

### Documentation (this feature)

```text
specs/002-codebase-reduction/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (in progress)
├── research.md          # Phase 0: Research findings (to generate)
├── data-model.md        # Phase 1: Entity definitions (to generate)
├── quickstart.md        # Phase 1: Implementation scenarios (to generate)
└── checklists/
    └── requirements.md  # Spec quality checklist (completed - all pass)
```

### Source Code (repository root)

```text
/home/notroot/NixOS/
├── modules/
│   ├── core/              # 9 files, 1794 lines → TARGET: ~1300 lines
│   ├── networking/        # 6 files, 922 lines → TARGET: ~750 lines
│   ├── packages/          # 8 files, 691 lines → TARGET: ~550 lines
│   ├── hardware/          # 4 files, 632 lines → TARGET: ~530 lines
│   ├── desktop/           # 5 files, 494 lines → TARGET: ~450 lines
│   ├── dotfiles/          # 2 files, 451 lines → TARGET: ~350 lines
│   ├── gpu/               # 5 files, 375 lines → TARGET: ~350 lines (minor)
│   ├── roles/             # 5 files, 223 lines → TARGET: ~200 lines (minor)
│   ├── profiles/          # 2 files, 186 lines → MERGE into hardware/
│   ├── services/          # 5 files, 181 lines → TARGET: ~170 lines (minor)
│   └── secrets/           # 1 file, 76 lines → NO CHANGES
├── lib/
│   ├── builders.nix       # TO EXPAND: Add 5+ new module builders
│   ├── utils.nix          # TO EXPAND: Add 5+ new option helpers
│   └── default.nix        # TO UPDATE: Export new helpers
├── hosts/
│   ├── desktop/           # NO CHANGES (per spec scope)
│   └── laptop/            # NO CHANGES (per spec scope)
├── flake-modules/         # NO CHANGES (recently completed flake-parts migration)
└── flake.nix              # NO CHANGES
```

## Phase 0: Outline & Research

### Research Tasks

#### R001: NixOS Module Best Practices (2025)
**Objective**: Identify current NixOS community standards for module organization and helper functions

**Questions**:
1. What are recommended patterns for module option definitions in nixpkgs (2025)?
2. Which `lib` helper functions should be used (mkEnableOption, mkPackageOption, etc.)?
3. How should modules be organized to balance modularity with file count?
4. When should modules be consolidated vs. kept separate?

**Sources**:
- nixpkgs/lib/modules.nix documentation
- NixOS Wiki: Module development
- nixpkgs module examples (pkgs/servers/, pkgs/services/)

**Deliverable**: List of recommended patterns and anti-patterns

#### R002: Code Deduplication Strategies in Nix
**Objective**: Research proven strategies for reducing Nix code duplication

**Questions**:
1. How do large NixOS configs handle repeated option patterns?
2. What are effective module builder patterns?
3. How to balance DRY principles with Nix explicitness?
4. What are common over-abstraction pitfalls?

**Sources**:
- nixpkgs module builder examples
- NixOS community configurations (search GitHub)
- Nix language best practices

**Deliverable**: Module builder pattern examples and guidelines

#### R003: Module Consolidation Strategy
**Objective**: Safe approaches for merging modules without breaking functionality

**Questions**:
1. How to identify consolidation-safe modules?
2. What testing ensures no functionality loss?
3. How to handle modules with different host requirements?
4. What is the safest consolidation order?

**Sources**:
- NixOS refactoring case studies
- Module dependency analysis tools
- Constitution Principle I guidelines

**Deliverable**: Decision criteria and testing checklist

#### R004: Helper Function Audit
**Objective**: Catalog existing helpers and identify new opportunities

**Questions**:
1. What helpers exist in `lib/builders.nix` and `lib/utils.nix`?
2. What patterns in modules could use helpers?
3. How do nixpkgs/flake-parts handle module builders?
4. What are naming and documentation standards?

**Sources**:
- Current lib/ directory audit
- nixpkgs/lib/ function catalog
- Module pattern frequency analysis

**Deliverable**: 10+ helper function candidates with signatures

### Consolidation (research.md format)

```markdown
# Research Findings: NixOS Codebase Optimization

## Decision: Module Consolidation Targets

**Chosen Approach**: [Consolidate semantically overlapping modules in phases]

**Rationale**: [Minimizes risk, allows validation per merge]

**Alternatives Considered**:
- Big-bang consolidation (rejected: too risky)
- No consolidation (rejected: misses 15% reduction target)

**Implementation**: [Specific consolidation plan with order]

---

## Decision: Helper Function Library

**Chosen Functions**: [List of 10+ helpers with signatures]

**Rationale**: [ROI analysis showing line reduction per helper]

**Alternatives Considered**: [Alternative abstraction patterns]

**Implementation**: [lib/ structure updates]

---

[Additional research decisions...]
```

## Phase 1: Design & Contracts

### Data Model (data-model.md)

#### Entity: Module Configuration
**Purpose**: NixOS module file defining system behavior

**Attributes**:
- `path`: string (file path, e.g., `modules/core/default.nix`)
- `category`: enum (core | networking | packages | hardware | desktop | dotfiles | gpu | roles | profiles | services | secrets)
- `lineCount`: integer (current lines)
- `targetLineCount`: integer (post-optimization target)
- `consolidationPriority`: enum (high | medium | low | none)
- `dependencies`: list<string> (imported modules)
- `options`: map<string, OptionDef> (defined options)

**Relationships**:
- Imported by → Host Configuration (1..2)
- Uses → Helper Function (0..*)
- Consolidates into → Module Configuration (0..1)

**Validation**:
- Path MUST exist in repository
- Line count MUST match `wc -l` output
- Options MUST be valid Nix attribute sets

#### Entity: Helper Function
**Purpose**: Reusable Nix function in `lib/`

**Attributes**:
- `name`: string (function name, e.g., `mkCategoryModule`)
- `signature`: string (Nix type signature)
- `purpose`: string (what pattern it abstracts)
- `usageCount`: integer (modules using it)
- `estimatedReduction`: integer (lines saved per use)

**Relationships**:
- Used by → Module Configuration (1..*)
- Defined in → lib/ file

**Validation**:
- Name MUST follow `mk*` convention
- Usage count MUST be ≥1 (else remove)

#### Entity: Consolidation Task
**Purpose**: Module merge/refactor operation

**Attributes**:
- `taskId`: string (CONS-001, etc.)
- `sourceModules`: list<string> (modules to consolidate)
- `targetModule`: string (result path)
- `strategy`: enum (merge | split | extract | optimize)
- `estimatedReduction`: integer (lines saved)
- `riskLevel`: enum (low | medium | high)

**State Transitions**:
```
Planned → In Progress → Testing → Complete
                ↓
         Rolled Back (if tests fail)
```

**Validation**:
- Sources MUST exist
- Target MUST build successfully
- Reduction MUST be positive

### File Structure (Consolidation Plan)

**Phase 1 Consolidations**:

1. **CONS-001: Networking Merge** (HIGH PRIORITY, LOW RISK)
   - Sources: `core/networking.nix` (224L) + `networking/default.nix` (200L)
   - Target: `networking/default.nix` (~350L)
   - Savings: ~74 lines (17%)
   - Risk: LOW (clear semantic overlap)

2. **CONS-002: Laptop Config Merge** (MEDIUM PRIORITY, MEDIUM RISK)
   - Sources: `hardware/laptop.nix` (407L) + `profiles/laptop.nix` (180L)
   - Target: `hardware/laptop.nix` (~450L)
   - Savings: ~137 lines (23%)
   - Risk: MEDIUM (need to preserve profile abstraction)

3. **CONS-003: Core Default Refactor** (MEDIUM PRIORITY, LOW RISK)
   - Source: `core/default.nix` (415L)
   - Target: `core/default.nix` (~300L) using helpers
   - Savings: ~115 lines (28%)
   - Risk: LOW (no merge, just optimization)

**Phase 2 Refactorings** (Helper-based):

4. **REF-001: Package Categories** (7 modules)
   - Refactor with `mkPackageCategoryModule` builder
   - Savings: ~208 lines total (30% avg per module)

5. **REF-002: Document Tools** (1 module)
   - Optimize `core/document-tools.nix` (398L → ~320L)
   - Savings: ~78 lines (20%)

6. **REF-003: Dotfiles Module** (1 module)
   - Optimize `dotfiles/default.nix` (396L → ~300L)
   - Savings: ~96 lines (24%)

**Total Estimated Savings**: ~708 lines from consolidations + ~382 lines from refactorings = ~1090 lines (19% of total)

**Phase 3 Optimizations**: ~360 additional lines from option definition shortcuts

**TOTAL**: ~1450 lines (25% target achieved)

### Quickstart Scenarios (quickstart.md)

#### Scenario 1: Establish Baseline Metrics
**Goal**: Document current state for comparison

**Steps**:
1. Checkout feature branch: `git checkout 002-codebase-reduction`
2. Generate baseline metrics:
   ```bash
   find modules -name "*.nix" -type f | xargs wc -l > metrics-baseline.txt
   wc -l modules/**/*.nix | tail -1  # Total: 5827 lines
   ```
3. Build both configurations:
   ```bash
   nix flake check
   nixos-rebuild build --flake .#desktop
   nixos-rebuild build --flake .#laptop
   ```
4. Capture system paths:
   ```bash
   readlink -f /run/current-system > baseline-desktop-path.txt
   ```

**Expected Outcome**: Baseline documented, all builds passing

#### Scenario 2: Consolidate Networking Modules (CONS-001)
**Goal**: Merge core/networking.nix into networking/default.nix

**Steps**:
1. Backup: `cp modules/networking/default.nix{,.bak}`
2. Merge content:
   ```bash
   # Combine option definitions (remove duplicates)
   # Merge config sections
   # Ensure no conflicts
   ```
3. Remove `core/networking.nix`
4. Update host imports (if any direct references)
5. Build and validate:
   ```bash
   nix flake check
   nixos-rebuild build --flake .#desktop
   nixos-rebuild build --flake .#laptop
   ```
6. Compare outputs:
   ```bash
   nix derivation show ./result | diff - baseline-desktop-derivation.json
   ```

**Expected Outcome**: ~74 lines saved, functionality preserved

#### Scenario 3: Create Helper Function Library
**Goal**: Build reusable module builders

**Steps**:
1. Create `mkCategoryModule` in `lib/builders.nix`:
   ```nix
   mkCategoryModule = { name, packages, description }: { config, lib, pkgs, ... }:
     with lib; let
       cfg = config.modules.packages.${name};
     in {
       options.modules.packages.${name} = {
         enable = mkEnableOption description;
         extraPackages = mkOption {
           type = with types; listOf package;
           default = [];
         };
       };
       
       config = mkIf cfg.enable {
         environment.systemPackages = packages ++ cfg.extraPackages;
       };
     };
   ```
2. Document with docstring
3. Export from `lib/default.nix`
4. Test in one package category module
5. Run checks: `nix flake check`

**Expected Outcome**: Helper working, ready for refactoring

#### Scenario 4: Refactor Package Category Module
**Goal**: Apply builder to simplify package modules

**Steps**:
1. Backup: `cp modules/packages/categories/browsers.nix{,.bak}`
2. Refactor to use builder:
   ```nix
   # Before: 54 lines with explicit options + config
   # After: ~35 lines using mkCategoryModule
   ```
3. Build and test: `nix flake check && nixos-rebuild build --flake .#desktop`
4. Measure reduction: `diff -u browsers.nix.bak browsers.nix | wc -l`
5. Repeat for 6 other categories

**Expected Outcome**: ~208 lines saved across package categories

#### Scenario 5: Final Validation & Metrics
**Goal**: Verify 25% reduction with feature parity

**Steps**:
1. Generate final metrics:
   ```bash
   find modules -name "*.nix" -type f | xargs wc -l > metrics-final.txt
   wc -l modules/**/*.nix | tail -1  # Expected: ~4370 lines
   ```
2. Calculate reduction:
   ```bash
   BASELINE=5827
   FINAL=$(wc -l modules/**/*.nix | tail -1 | awk '{print $1}')
   REDUCTION=$((BASELINE - FINAL))
   PERCENT=$((REDUCTION * 100 / BASELINE))
   echo "Reduced by $REDUCTION lines ($PERCENT%)"  # Should be ≥25%
   ```
3. Validate builds:
   ```bash
   nix flake check  # Must pass
   nixos-rebuild build --flake .#desktop  # Must succeed
   nixos-rebuild build --flake .#laptop   # Must succeed
   ```
4. Compare system behavior:
   ```bash
   # After rebuild on desktop
   systemctl list-units --state=active > services-after.txt
   diff services-before.txt services-after.txt  # Should be identical
   ```
5. Verify derivation equivalence:
   ```bash
   nix derivation show $(readlink -f /run/current-system) > current.json
   nix derivation show ./result > new.json
   diff current.json new.json  # Only timestamps should differ
   ```

**Expected Outcome**: 25%+ reduction confirmed, 100% feature parity validated

### Agent Context Update

After Phase 1 completion, update agent context:

```bash
.specify/scripts/bash/update-agent-context.sh claude
```

**New Technologies to Add**:
- NixOS module builder patterns
- Helper function library design
- Code consolidation strategies
- Validation techniques (derivation comparison, service diffing)

## Post-Design Constitution Re-check

After completing Phase 1 design, re-evaluate:

### Principle I: Modularity ✅ ENHANCED
- Consolidation groups semantically related configs
- Helper functions improve composability
- Module interfaces remain explicit

### Principle II: Declarative ✅ MAINTAINED
- All changes are Nix expressions
- No imperative modifications

### Principle III: No Home Manager ✅ RESPECTED
- Dotfiles system preserved
- Zero Home Manager usage

### Principle IV: Testing ✅ STRENGTHENED
- Enhanced validation (before/after comparison)
- Incremental testing per consolidation

### Principle V: Documentation ✅ IMPROVED
- Helper function docs added
- CLAUDE.md updated
- Clearer module structure

**Final Assessment**: ✅ ALL PRINCIPLES UPHELD

## Success Metrics Tracking

| Criterion | Measurement | Target | Status |
|-----------|-------------|--------|--------|
| SC-001: 25% reduction | Line count diff | ≥1457 lines | Planned |
| SC-002: Build time | `time nixos-rebuild build` | <5 min | Baseline TBD |
| SC-003: Flake checks | `nix flake check` exit code | 0 | Baseline: PASS |
| SC-004: Zero duplication | Code review | No duplicates | Planned |
| SC-005: 20% module avg | Per-file diff | ≥20% | Planned |
| SC-006: 10 helpers | Count in lib/ | ≥10 | Planned |
| SC-007: Maintainability | Review checklist | PASS | Planned |
| SC-008: Build perf | Time comparison | No regression | Planned |
| SC-009: Identical behavior | System path + service diff | Exact match | Planned |
| SC-010: Docs updated | CLAUDE.md, lib/README.md | Complete | Planned |

## Risk Mitigation

### Risk 1: Consolidation Breaks Functionality (MEDIUM)
**Mitigation**:
- Incremental consolidation (one at a time)
- Build both configs after each merge
- Maintain .bak files
- Compare system derivations
- Test in VM first

### Risk 2: Helper Abstractions Reduce Clarity (LOW)
**Mitigation**:
- Document all helpers with docstrings
- Provide usage examples
- Code review each helper
- Max 2 abstraction levels

### Risk 3: Target Not Achieved (LOW)
**Mitigation**:
- Conservative estimates (30% planned vs. 25% target)
- Track reduction per phase
- Identify additional targets if needed

### Risk 4: Build Time Regression (LOW)
**Mitigation**:
- Benchmark build time before/after
- Monitor per phase
- Avoid complex runtime evaluation

## Next Steps

1. ✅ **Review this plan**: Technical approach validated
2. **Generate tasks**: Run `/speckit.tasks` to create detailed breakdown
3. **Begin implementation**: Start with baseline metrics

**Plan Status**: ✅ COMPLETE - Ready for task generation

---

**Generated**: 2025-11-25
**Author**: Claude Code (via /speckit.plan)
**Branch**: 002-codebase-reduction
