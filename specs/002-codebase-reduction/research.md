# Research Findings: NixOS Codebase Optimization

**Feature**: 002-codebase-reduction
**Date**: 2025-11-25
**Status**: Complete

## Decision: Module Consolidation Candidates

**Chosen Approach**: Phased semantic consolidation - merge modules with overlapping responsibilities in order of risk (LOW → MEDIUM → HIGH)

**Rationale**:
- Minimizes blast radius by consolidating one module pair at a time
- Allows validation and rollback between each consolidation
- Prioritizes high-value, low-risk merges first (networking, laptop config)
- Preserves module boundaries for distinct concerns (GPU, services, roles)

**Alternatives Considered**:
- **Big-bang consolidation**: Merge all overlapping modules at once (REJECTED - too risky, hard to debug failures)
- **No consolidation**: Focus only on helper functions and optimization (REJECTED - misses 15% P1 target)
- **Fine-grained modules**: Keep all modules separate, only optimize internally (REJECTED - doesn't address duplication)

**Implementation Impact**:
- CONS-001 (networking): Merge `core/networking.nix` → `networking/default.nix` (~74 lines saved)
- CONS-002 (laptop): Merge `hardware/laptop.nix` + `profiles/laptop.nix` (~137 lines saved)
- CONS-003 (core): Optimize `core/default.nix` with helpers (~115 lines saved)

**Consolidation Order** (by risk):
1. Networking (LOW risk - clear semantic overlap, well-defined interface)
2. Core optimization (LOW risk - no merge, just refactor)
3. Laptop merge (MEDIUM risk - need to preserve profile abstraction for potential future use)

---

## Decision: Helper Function Library Design

**Chosen Functions**: 10 reusable helpers focusing on most common patterns

**Core Helpers** (to implement in lib/builders.nix and lib/utils.nix):

1. **mkCategoryModule** (builder for package categories)
   - Signature: `{ name, packages, description } → module`
   - Pattern: Standard enable/package/extraPackages + conditional installation
   - Usage: 7 package category modules
   - Estimated reduction: ~30 lines per module = ~210 lines total

2. **mkEnableOption** shortcut (already in nixpkgs lib, use more)
   - Pattern: `mkOption { type = types.bool; default = false; description = "Enable X"; }`
   - Usage: 50+ enable options across modules
   - Estimated reduction: ~3 lines per option = ~150 lines total

3. **mkPackageOption** shortcut (already in nixpkgs lib, use more)
   - Pattern: `mkOption { type = types.package; default = pkgs.X; description = "The X package"; }`
   - Usage: 20+ package options
   - Estimated reduction: ~2 lines per option = ~40 lines total

4. **mkConditionalPackages** (helper for conditional package lists)
   - Signature: `condition → packages → packages list`
   - Pattern: `if cfg.enable then [ pkg1 pkg2 ] else []`
   - Usage: 30+ conditional package blocks
   - Estimated reduction: ~2 lines per use = ~60 lines total

5. **mkServiceModule** (builder for simple services)
   - Signature: `{ name, package, description, serviceConfig } → module`
   - Pattern: Standard service with enable toggle and package option
   - Usage: 4 service modules (docker, printing, ssh, syncthing)
   - Estimated reduction: ~20 lines per module = ~80 lines total

6. **mkOptionDefault** (simplified option with common defaults)
   - Pattern: `mkOption { type = X; default = Y; description = Z; }`
   - Usage: 100+ simple options
   - Estimated reduction: ~1 line per option = ~100 lines total

7. **mkGPUModule** (builder for GPU configuration modules)
   - Signature: `{ vendor, drivers, packages } → module`
   - Pattern: Standard GPU with enable, driver selection, package list
   - Usage: 4 GPU modules (AMD, Intel, NVIDIA, Hybrid)
   - Estimated reduction: ~15 lines per module = ~60 lines total

8. **mkMergedOptions** (combine option sets)
   - Signature: `[ options ] → merged options`
   - Pattern: `lib.mkMerge [ options1 options2 ]`
   - Usage: 10+ multi-option merges
   - Estimated reduction: ~5 lines per use = ~50 lines total

9. **mkImportList** (simplify module imports)
   - Signature: `path → glob pattern → import list`
   - Pattern: Automatically import all modules in a directory
   - Usage: 5 module default.nix files
   - Estimated reduction: ~10 lines per use = ~50 lines total

10. **mkDocumentToolModule** (specialized for document-tools.nix)
    - Signature: `{ tool, packages, extraOptions } → module options`
    - Pattern: Repeating pattern in document-tools.nix (LaTeX/Typst/Markdown)
    - Usage: 3 sections in document-tools.nix
    - Estimated reduction: ~30 lines per section = ~90 lines total

**Total Estimated Helper Savings**: ~890 lines

**Rationale**:
- Focus on highest-frequency patterns (enable options, package lists, conditional blocks)
- Reuse existing nixpkgs lib functions where possible (mkEnableOption, mkPackageOption)
- Create specialized builders for complex repeating patterns (module builders, service builders)
- Document with clear docstrings and usage examples

**Alternatives Considered**:
- **Mega-builder**: Single universal module builder (REJECTED - too complex, reduces clarity)
- **No helpers**: Manual optimization only (REJECTED - misses 10% P2 target)
- **Copy nixpkgs patterns**: Use only existing lib functions (CONSIDERED - good but insufficient for custom patterns)

**Implementation Impact**:
- New helpers in lib/builders.nix (5 functions)
- New helpers in lib/utils.nix (5 functions)
- Updated lib/default.nix to export all new helpers
- README.md in lib/ documenting each helper with examples

---

## Decision: Module Option Definition Optimization

**Chosen Approach**: Apply lib shortcuts systematically, prioritize readability

**Optimization Strategies**:

1. **Replace verbose enable options**:
   ```nix
   # Before (4 lines)
   enable = mkOption {
     type = types.bool;
     default = false;
     description = "Enable feature X";
   };
   
   # After (1 line)
   enable = mkEnableOption "feature X";
   ```
   - Usage: 50+ enable options
   - Savings: 3 lines × 50 = 150 lines

2. **Replace verbose package options**:
   ```nix
   # Before (4 lines)
   package = mkOption {
     type = types.package;
     default = pkgs.firefox;
     description = "The Firefox package to use";
   };
   
   # After (1 line)
   package = mkPackageOption pkgs "firefox" { };
   ```
   - Usage: 20+ package options
   - Savings: 3 lines × 20 = 60 lines

3. **Simplify conditional config blocks**:
   ```nix
   # Before (5 lines)
   config = mkIf cfg.enable {
     environment.systemPackages =
       if cfg.minimal then
         [ pkgs.essential ]
       else
         [ pkgs.essential pkgs.extra ];
   };
   
   # After (3 lines)
   config = mkIf cfg.enable {
     environment.systemPackages = [ pkgs.essential ] ++ (mkConditionalPackages (!cfg.minimal) [ pkgs.extra ]);
   };
   ```
   - Usage: 30+ conditional blocks
   - Savings: 2 lines × 30 = 60 lines

4. **Merge redundant options**:
   - Identify overly granular options that could be combined
   - Example: Multiple boolean toggles → single enum option
   - Usage: 10 option sets
   - Savings: ~10 lines per set = 100 lines

**Total Optimization Savings**: ~370 lines

**Rationale**:
- Use established nixpkgs lib functions for credibility and consistency
- Maintain or improve readability (shortcuts are self-documenting)
- Focus on mechanical replacements (low risk, high repeatability)
- Avoid clever abstractions that obscure intent

**Alternatives Considered**:
- **No shortcuts**: Keep explicit option definitions (REJECTED - misses 5% P3 target)
- **Over-optimization**: Remove all intermediate variables, inline everything (REJECTED - reduces readability)

**Implementation Impact**:
- Update 50+ modules with mkEnableOption
- Update 20+ modules with mkPackageOption
- Refactor 30+ conditional blocks
- Simplify 10 option sets

---

## Decision: Testing and Validation Strategy

**Chosen Approach**: Multi-layered validation with before/after comparison

**Validation Layers**:

1. **Syntax validation**: `nix flake check` (format/lint/eval)
   - Run after EVERY change
   - Must pass before commit

2. **Build validation**: `nixos-rebuild build --flake .#<host>`
   - Run after module consolidation or major refactor
   - Must succeed for both desktop and laptop

3. **Derivation comparison**: Compare system derivation JSON
   ```bash
   nix derivation show $(readlink -f /run/current-system) > before.json
   nixos-rebuild build --flake .#desktop
   nix derivation show ./result > after.json
   diff before.json after.json  # Only timestamps should differ
   ```
   - Run after consolidation to ensure identical outputs
   - Catches subtle behavior changes

4. **Service verification**: Compare enabled services
   ```bash
   systemctl list-units --state=active > services-before.txt
   # After rebuild
   systemctl list-units --state=active > services-after.txt
   diff services-before.txt services-after.txt  # Should be identical
   ```
   - Run after deployment to ensure no services lost

5. **Regression testing**: Boot test in VM
   - Optional for high-risk consolidations
   - Verify desktop environment starts correctly

**Rationale**:
- Layered validation catches different error types (syntax → build → runtime)
- Before/after comparison ensures 100% feature parity (FR-001)
- Derivation comparison is gold standard for "identical system"

**Alternatives Considered**:
- **Manual testing only**: Test by using the system (REJECTED - not reproducible, misses subtle changes)
- **Build-only validation**: Skip derivation comparison (REJECTED - might miss behavior changes)

**Implementation Impact**:
- Validation scripts in specs/002-codebase-reduction/scripts/
- Baseline metrics captured before starting
- Validation checklist for each consolidation task

---

## Research Artifacts

**Documentation Created**:
- This file (research.md)
- Consolidation decision matrix
- Helper function catalog (10 functions)
- Validation strategy checklist

**References Consulted**:
- nixpkgs lib/modules.nix documentation
- NixOS module best practices (Wiki)
- nixpkgs module examples (pkgs/servers/, pkgs/services/)
- Nix language patterns (nixpkgs manual)
- Constitution.md (governance principles)

**Knowledge Gaps Resolved**:
- ✅ R001: NixOS module patterns (mkEnableOption, mkPackageOption standard)
- ✅ R002: Deduplication strategies (module builders, helper functions)
- ✅ R003: Consolidation safety (semantic grouping, incremental validation)
- ✅ R004: Helper function design (10 helpers identified with ROI)

**Status**: ✅ RESEARCH COMPLETE - Ready for Phase 1 design
