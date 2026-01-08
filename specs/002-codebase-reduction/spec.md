# Feature Specification: NixOS Codebase Optimization & Reduction

**Feature Branch**: `002-codebase-reduction`  
**Created**: 2025-11-25  
**Status**: Draft  
**Input**: User description: "My goal is to reduce the code base size while maintaining all the features and using the best practices."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consolidate Modular Configuration (Priority: P1) 🎯 MVP

As a system maintainer, I need to consolidate and refactor overlapping module configurations to reduce code duplication while preserving all existing functionality, so that the codebase becomes easier to maintain and understand.

**Why this priority**: This is the foundation for all other optimization work. Removing duplication and consolidating overlapping modules directly addresses the core goal of reducing codebase size while maintaining features. This provides immediate value by making the codebase more maintainable.

**Independent Test**: Can be fully tested by building both desktop and laptop configurations with `nixos-rebuild build --flake .#desktop` and `nixos-rebuild build --flake .#laptop`, verifying all services start correctly, and confirming no features are lost by comparing the before/after system paths and enabled services.

**Acceptance Scenarios**:

1. **Given** the current codebase has ~5827 lines across all .nix files, **When** overlapping module configurations are consolidated, **Then** the total line count is reduced by at least 15% (~875 lines) without losing any functionality
2. **Given** modules with similar purposes exist (e.g., networking modules, GNOME modules), **When** these are analyzed for consolidation opportunities, **Then** at least 3 modules are successfully merged or refactored with improved clarity
3. **Given** the current module structure, **When** consolidation is complete, **Then** both desktop and laptop configurations build successfully and all system services function identically to the pre-consolidation state

---

### User Story 2 - Extract Reusable Module Components (Priority: P2)

As a system maintainer, I need to extract commonly repeated configuration patterns into reusable helper functions and shared modules, so that configuration becomes more DRY (Don't Repeat Yourself) and changes can be made in one place.

**Why this priority**: After consolidating modules (P1), extracting reusable components provides additional size reduction and maintenance benefits. This builds on P1's foundation by creating abstractions that prevent future code duplication.

**Independent Test**: Can be tested by verifying that extracted helper functions work correctly across all modules that use them, that the total line count is further reduced, and that `nix flake check` passes all validation.

**Acceptance Scenarios**:

1. **Given** configuration patterns repeated across multiple modules, **When** these patterns are extracted into reusable helper functions in `lib/`, **Then** at least 5 helper functions are created that reduce overall line count by 10%
2. **Given** common module option patterns (enable/package/extraPackages), **When** a standardized module builder is created, **Then** module definitions become at least 30% shorter on average
3. **Given** the extracted helper functions, **When** they are used in multiple modules, **Then** changing shared behavior only requires updating one function instead of multiple modules

---

### User Story 3 - Optimize Module Option Definitions (Priority: P3)

As a system maintainer, I need to optimize verbose module option definitions by using attribute set shortcuts and improved defaults, so that module files become more concise without sacrificing readability.

**Why this priority**: This provides additional polish and optimization after the structural improvements from P1 and P2. It focuses on code quality improvements that make modules easier to read and maintain.

**Independent Test**: Can be tested by comparing module file sizes before and after optimization, verifying that all options still work correctly with `nix flake check`, and confirming that module behavior remains unchanged.

**Acceptance Scenarios**:

1. **Given** verbose option definitions with explicit type, default, and description attributes, **When** these are optimized using `lib.mkEnableOption`, `lib.mkPackageOption`, and other helper functions, **Then** option definitions become 20-40% more concise
2. **Given** module option definitions, **When** redundant or overly granular options are identified, **Then** at least 10 options are simplified or merged while maintaining equivalent functionality
3. **Given** the optimized module definitions, **When** reviewing the code, **Then** the intent and behavior of each option is equally clear or clearer than before optimization

---

### Edge Cases

- What happens when a consolidated module is used by both desktop and laptop configurations with different requirements?
- How does the system handle module consolidation when there are subtle behavioral differences between similar modules?
- What happens if a helper function abstraction makes debugging more difficult?
- How do we ensure that reducing code doesn't make the configuration harder to understand for new contributors?
- What happens when optimizing module options removes flexibility needed by a specific host configuration?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST maintain 100% feature parity before and after codebase reduction (no functionality loss)
- **FR-002**: System MUST successfully build both desktop and laptop configurations after each optimization phase
- **FR-003**: System MUST pass all existing flake checks (`nix flake check`) after codebase reduction
- **FR-004**: Consolidated modules MUST preserve all existing module options and their behavior
- **FR-005**: Extracted helper functions MUST be documented with clear docstrings explaining purpose, parameters, and return values
- **FR-006**: Module option definitions MUST maintain clarity and readability when optimized
- **FR-007**: System MUST preserve all existing services, packages, and configurations enabled in both host configurations
- **FR-008**: Refactored code MUST follow NixOS best practices and conventions
- **FR-009**: Changes MUST be validated through before/after comparisons of system build outputs
- **FR-010**: Code reduction MUST be measured and tracked with specific line count and percentage metrics

### Key Entities

- **Module Configuration**: NixOS module files defining system behavior, options, and package installations
- **Helper Function**: Reusable Nix functions in `lib/` that encapsulate common configuration patterns
- **Module Option**: Configurable parameters defined in modules (enable, package, extraPackages, etc.)
- **Host Configuration**: Desktop and laptop-specific configurations that import and use modules
- **Service Definition**: systemd services and other system services configured by modules

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Total codebase size (line count) is reduced by at least 25% (~1457 lines) while maintaining all features
- **SC-002**: Both desktop and laptop configurations build successfully in under 5 minutes (current baseline time)
- **SC-003**: All flake checks pass (`nix flake check`) with zero errors or warnings
- **SC-004**: Module duplication is reduced from current overlapping patterns to zero duplicate configurations
- **SC-005**: Average module file size is reduced by at least 20% through consolidation and optimization
- **SC-006**: At least 10 reusable helper functions are created that replace repeated code patterns
- **SC-007**: Code review confirms that maintainability is improved (clearer structure, better organization)
- **SC-008**: Build time for both configurations remains the same or improves (no performance degradation)
- **SC-009**: System behavior is identical before and after changes (verified by comparing system paths and enabled services)
- **SC-010**: Documentation is updated to reflect new module structure and helper function usage

## Non-Functional Requirements *(optional)*

### Maintainability

- Consolidated modules SHOULD use clear, descriptive names that indicate their purpose
- Helper functions SHOULD follow consistent naming conventions (e.g., `mk*` for builders)
- Code SHOULD include inline comments explaining non-obvious refactoring decisions
- Module structure SHOULD group related functionality logically

### Performance

- Build time SHOULD NOT increase as a result of codebase reduction
- Module evaluation time SHOULD remain constant or improve

## Assumptions

1. **Current State**: The codebase currently has ~5827 total lines across all .nix files with some duplication and overlapping module configurations
2. **Module Consolidation**: Modules with similar purposes (networking, GNOME configuration, etc.) can be safely consolidated without breaking existing configurations
3. **Testing Infrastructure**: Existing flake checks and build processes are sufficient to validate that functionality is preserved
4. **Host Configurations**: Both desktop and laptop configurations will continue to exist and need to be fully functional after optimization
5. **Best Practices**: NixOS community best practices (as of 2025) will guide optimization decisions
6. **Helper Functions**: The `lib/` directory can be expanded with additional helper functions as needed
7. **Backwards Compatibility**: The optimization will not require changes to external dependencies or nixpkgs versions

## Scope

### In Scope

- Consolidating overlapping module configurations in `modules/`
- Extracting reusable patterns into `lib/` helper functions
- Optimizing verbose module option definitions
- Reducing code duplication across modules
- Improving module organization and structure
- Documenting new helper functions and refactored modules
- Validating that all features work after each optimization phase

### Out of Scope

- Removing features or functionality from the system
- Changing host-specific configurations in `hosts/desktop/` or `hosts/laptop/`
- Modifying flake structure or flake-parts integration (recently completed)
- Upgrading to different versions of nixpkgs or external dependencies
- Changing system behavior or default settings
- Rewriting the build system or test infrastructure
- Optimizing shell scripts or non-Nix files

## Dependencies

- Completion of flake-parts migration (already complete as of feature 001)
- Existing flake checks and validation infrastructure
- Current module structure and organization
