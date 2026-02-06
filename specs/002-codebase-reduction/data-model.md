# Data Model: NixOS Codebase Optimization

**Feature**: 002-codebase-reduction
**Date**: 2025-11-25
**Status**: Design Complete

## Overview

This data model defines the entities, relationships, and validation rules for the codebase reduction feature. It captures modules, helper functions, and consolidation tasks as they relate to reducing code while maintaining functionality.

---

## Entity Definitions

### Module Configuration

**Purpose**: Represents a NixOS module file that defines system behavior, options, and package installations.

**Attributes**:
- `path`: string (required)
  - File path relative to repository root
  - Example: `modules/core/default.nix`
  - Validation: Must exist in filesystem

- `category`: enum (required)
  - Module category for organizational grouping
  - Values: `core | networking | packages | hardware | desktop | dotfiles | gpu | roles | profiles | services | secrets`
  - Validation: Must match one of defined categories

- `lineCount`: integer (required)
  - Current number of lines in the module file
  - Measured by: `wc -l <path>`
  - Validation: Must be > 0, must match actual file

- `targetLineCount`: integer (optional)
  - Post-optimization target line count
  - Calculated from reduction percentage goals
  - Validation: Must be < lineCount, must be > 0

- `consolidationPriority`: enum (required)
  - Priority for consolidation consideration
  - Values: `high | medium | low | none`
  - Criteria:
    - `high`: Large module (>300 lines) with clear consolidation target
    - `medium`: Medium module (150-300 lines) with potential consolidation
    - `low`: Small module (<150 lines) or minor optimization only
    - `none`: Module should not be consolidated (distinct purpose)

- `dependencies`: list<string> (required)
  - List of module paths imported by this module
  - Example: `["./networking.nix", "../hardware/laptop.nix"]`
  - Validation: All paths must exist

- `options`: map<string, OptionDefinition> (required)
  - Map of NixOS options defined in this module
  - Key: Option path (e.g., `modules.core.default.enable`)
  - Value: OptionDefinition object
  - Validation: All options must be valid Nix attribute sets

**Relationships**:
- Imported by → Host Configuration (1..2)
  - Cardinality: Each module used by 1 or 2 hosts (desktop, laptop, or both)
  - Constraint: At least 1 host must use each module (else delete module)

- Uses → Helper Function (0..*)
  - Cardinality: Module can use zero or more helper functions
  - Constraint: After refactoring, most modules should use ≥1 helper

- Consolidates into → Module Configuration (0..1)
  - Cardinality: Module either remains standalone or merges into one target
  - Constraint: If consolidating, target must exist or be created

**State Transitions**:
```
Original → Analyzing → Targeted for Consolidation/Optimization → In Progress → Complete
                   ↘ No Changes Needed → Preserved
```

**Validation Rules**:
- Path MUST exist in repository
- Line count MUST match `wc -l <path>` output
- Options MUST be valid Nix attribute sets (verified by `nix flake check`)
- If consolidationPriority is `high` or `medium`, targetLineCount MUST be defined
- If consolidationPriority is `none`, module MUST NOT be in consolidation tasks

**Example**:
```json
{
  "path": "modules/core/default.nix",
  "category": "core",
  "lineCount": 415,
  "targetLineCount": 300,
  "consolidationPriority": "medium",
  "dependencies": [],
  "options": {
    "modules.core.default.enable": { "type": "bool", "default": true },
    "modules.core.default.timeZone": { "type": "string", "default": "America/New_York" }
  }
}
```

---

### Helper Function

**Purpose**: Reusable Nix function in `lib/` directory that encapsulates common configuration patterns to reduce boilerplate code.

**Attributes**:
- `name`: string (required)
  - Function identifier
  - Example: `mkCategoryModule`, `mkEnableOption`, `mkConditionalPackages`
  - Validation: Must follow naming convention (`mk*` or `enable*`)

- `signature`: string (required)
  - Nix type signature describing parameters and return type
  - Example: `{ name, packages, description } → module`
  - Validation: Must be valid Nix function signature

- `purpose`: string (required)
  - Human-readable description of what pattern the function abstracts
  - Example: "Create a module with standard enable/package/extraPackages pattern"
  - Validation: Must be non-empty, descriptive

- `usageCount`: integer (required)
  - Number of modules currently using this helper function
  - Updated dynamically as refactoring progresses
  - Validation: Must be ≥ 0

- `estimatedReduction`: integer (required)
  - Estimated lines saved per usage of this helper
  - Calculated from pattern analysis
  - Example: 30 lines saved per module using mkCategoryModule
  - Validation: Must be > 0

- `documentationPath`: string (required)
  - Path to documentation/examples for this helper
  - Example: `lib/README.md#mkCategoryModule`
  - Validation: Path must exist

**Relationships**:
- Used by → Module Configuration (1..*)
  - Cardinality: Helper function must be used by at least 1 module (else remove)
  - Constraint: usageCount must match actual usage across modules

- Defined in → lib/ file (1)
  - Cardinality: Each helper defined in exactly one lib/ file
  - Values: `lib/builders.nix | lib/utils.nix`
  - Constraint: File must exist

**Validation Rules**:
- Name MUST follow `mk*` or `enable*` convention (e.g., mkCategoryModule, not categoryModule)
- Signature MUST be documented with clear parameter names and types
- Usage count MUST be ≥1 after implementation (if 0, remove helper)
- Estimated reduction MUST be validated by actual usage (measure before/after)
- Documentation MUST include usage example

**Example**:
```json
{
  "name": "mkCategoryModule",
  "signature": "{ name, packages, description } → module",
  "purpose": "Create a package category module with standard enable/package/extraPackages pattern",
  "usageCount": 7,
  "estimatedReduction": 30,
  "documentationPath": "lib/README.md#mkCategoryModule"
}
```

---

### Consolidation Task

**Purpose**: Represents a module merge, split, extract, or optimization operation that reduces code size.

**Attributes**:
- `taskId`: string (required)
  - Unique identifier for the task
  - Format: `CONS-NNN` (consolidation) or `REF-NNN` (refactoring) or `OPT-NNN` (optimization)
  - Example: `CONS-001`, `REF-002`, `OPT-003`
  - Validation: Must be unique across all tasks

- `sourceModules`: list<string> (required)
  - List of module paths being consolidated/refactored
  - Example: `["modules/core/networking.nix", "modules/networking/default.nix"]`
  - Validation: All paths must exist, list must not be empty

- `targetModule`: string (required)
  - Resulting module path after consolidation
  - Example: `modules/networking/default.nix`
  - Validation: Must be a valid path (may not exist yet if creating new module)

- `strategy`: enum (required)
  - Type of operation being performed
  - Values: `merge | split | extract | optimize`
  - Definitions:
    - `merge`: Combine multiple modules into one
    - `split`: Divide one module into multiple focused modules
    - `extract`: Pull shared code into helper function
    - `optimize`: Refactor single module using shortcuts/helpers
  - Validation: Must match one of defined strategies

- `estimatedReduction`: integer (required)
  - Estimated lines of code saved by this task
  - Calculated from: sourceModules.lineCount - targetModule.targetLineCount
  - Example: 424 lines (source) - 350 lines (target) = 74 lines saved
  - Validation: Must be > 0 (positive reduction)

- `riskLevel`: enum (required)
  - Assessment of risk for this consolidation
  - Values: `low | medium | high`
  - Criteria:
    - `low`: Clear semantic overlap, no behavioral differences, simple merge
    - `medium`: Some abstraction needed, minor behavioral differences
    - `high`: Complex dependencies, significant behavioral differences
  - Validation: Must match one of defined levels

- `status`: enum (required)
  - Current state of the consolidation task
  - Values: `planned | in_progress | testing | complete | rolled_back`
  - Validation: Must match one of defined statuses

- `validationChecklist`: list<string> (required)
  - Steps to validate this consolidation
  - Example: ["nix flake check passes", "Desktop builds successfully", "Laptop builds successfully", "Services match baseline"]
  - Validation: Must have at least 3 validation steps

**Relationships**:
- Operates on → Module Configuration (1..*)
  - Cardinality: Task operates on 1 or more source modules
  - Constraint: At least 1 source module required

- Produces → Module Configuration (1)
  - Cardinality: Task produces exactly one target module
  - Constraint: Target module must build successfully

- Validated by → Build Test (1..*)
  - Cardinality: Task must be validated by 1 or more build tests
  - Constraint: All validations must pass before marking complete

**State Transitions**:
```
Planned → In Progress → Testing → Complete
                    ↓
              Rolled Back (if tests fail)
```

**Validation Rules**:
- Source modules MUST exist in repository
- Target module MUST build successfully (nix flake check, nixos-rebuild build)
- Estimated reduction MUST be positive (> 0)
- All validation checklist items MUST pass before status = complete
- If status = complete, usageCount of any related helper functions MUST be updated
- If status = rolled_back, source modules MUST be restored

**Example**:
```json
{
  "taskId": "CONS-001",
  "sourceModules": ["modules/core/networking.nix", "modules/networking/default.nix"],
  "targetModule": "modules/networking/default.nix",
  "strategy": "merge",
  "estimatedReduction": 74,
  "riskLevel": "low",
  "status": "planned",
  "validationChecklist": [
    "nix flake check passes",
    "Desktop builds successfully (nixos-rebuild build --flake .#desktop)",
    "Laptop builds successfully (nixos-rebuild build --flake .#laptop)",
    "System derivations match baseline (only timestamps differ)",
    "Enabled services match baseline"
  ]
}
```

---

## Entity Relationships Diagram

```
┌─────────────────────┐
│ Host Configuration  │
│ (desktop, laptop)   │
└──────────┬──────────┘
           │
           │ imports (1..2)
           ↓
┌─────────────────────┐       uses (0..*)      ┌──────────────────┐
│ Module              │─────────────────────→ │ Helper Function  │
│ Configuration       │                        │ (lib/)           │
└──────────┬──────────┘                        └────────┬─────────┘
           │                                            │
           │ consolidates into (0..1)                   │ defined in (1)
           │                                            ↓
           │                                   ┌──────────────────┐
           │                                   │ lib/ file        │
           │                                   │ (builders.nix,   │
           │                                   │  utils.nix)      │
           │                                   └──────────────────┘
           │
           │ operated on by (1..*)
           ↓
┌─────────────────────┐       validated by     ┌──────────────────┐
│ Consolidation Task  │─────────────────────→ │ Build Test       │
│ (CONS/REF/OPT)      │        (1..*)          │ (checks, builds) │
└─────────────────────┘                        └──────────────────┘
           │
           │ produces (1)
           ↓
┌─────────────────────┐
│ Module              │
│ Configuration       │
│ (target)            │
└─────────────────────┘
```

---

## Validation Matrix

| Entity | Validation Rule | Check Method | Failure Action |
|--------|----------------|--------------|----------------|
| Module Configuration | Path exists | `test -f <path>` | Error: Path not found |
| Module Configuration | Line count accurate | `wc -l <path>` | Update lineCount |
| Module Configuration | Options valid | `nix flake check` | Error: Invalid syntax |
| Helper Function | Name follows convention | Regex: `^(mk\|enable).*` | Error: Rename function |
| Helper Function | Usage count ≥1 | Count modules using function | Warning: Consider removing |
| Helper Function | Documentation exists | `test -f <docPath>` | Error: Add docs |
| Consolidation Task | Sources exist | `test -f <source>` | Error: Invalid source |
| Consolidation Task | Target builds | `nixos-rebuild build` | Rollback: Restore sources |
| Consolidation Task | Reduction positive | `estimatedReduction > 0` | Error: No benefit |
| Consolidation Task | All checks pass | Run validation checklist | Rollback: Fix issues |

---

## Metrics Tracking

**Baseline Metrics** (before reduction):
- Total lines: 5827
- Module count: 57
- Average module size: 102 lines
- Largest module: 415 lines (core/default.nix)
- Helper function count: 4 (existing in lib/)

**Target Metrics** (after reduction):
- Total lines: ≤4370 (25% reduction = 1457 lines saved)
- Module count: ≤55 (2 merges expected)
- Average module size: ≤80 lines (20% reduction)
- Largest module: ≤350 lines
- Helper function count: ≥14 (10 new + 4 existing)

**Progress Tracking**:
- Lines saved: Sum of estimatedReduction across all complete consolidation tasks
- Reduction percentage: (lines saved / 5827) × 100%
- Modules consolidated: Count of tasks with status = complete
- Helpers implemented: Count of Helper Functions with usageCount > 0

---

**Status**: ✅ DESIGN COMPLETE - Ready for implementation
