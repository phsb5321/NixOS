# Feature Specification: Flake-Parts Integration for Multi-Host NixOS

**Feature Branch**: `001-flake-parts-integration`
**Created**: 2025-11-24
**Status**: Draft
**Input**: User description: "How to use flake parts on My NixOS multi host System?"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Modular Flake Structure (Priority: P1)

As a NixOS system maintainer, I need to organize my multi-host configuration using flake-parts modules so that my flake.nix remains maintainable and scalable as I add more hosts and features.

**Why this priority**: This is the foundation for all other improvements. Without proper modularization, the flake.nix will continue to grow monolithically and become harder to maintain.

**Independent Test**: Can be fully tested by restructuring the existing desktop and laptop hosts into flake-parts modules, verifying that `nix flake check` passes and both systems build successfully with `nixos-rebuild build --flake .#desktop` and `nixos-rebuild build --flake .#laptop`.

**Acceptance Scenarios**:

1. **Given** an existing monolithic flake.nix with 2+ hosts, **When** I restructure it using flake-parts modules, **Then** both host configurations build successfully without errors
2. **Given** a modularized flake structure, **When** I run `nix flake show`, **Then** I see all outputs (nixosConfigurations, checks, formatter, apps, devShells) properly organized
3. **Given** modular host definitions, **When** I add a new host, **Then** I only need to create a new module file without modifying the main flake.nix structure

---

### User Story 2 - Per-Host Custom Outputs (Priority: P2)

As a NixOS developer, I want each host to be able to define its own custom outputs (development shells, deployment scripts, VM tests) so that host-specific tooling doesn't clutter the main flake structure.

**Why this priority**: Enables hosts to have specialized development and testing environments without mixing concerns in the main flake.

**Independent Test**: Can be tested by adding a host-specific development shell to the desktop configuration, verifying it appears in `nix flake show`, and launching it with `nix develop .#desktop`.

**Acceptance Scenarios**:

1. **Given** a desktop host module, **When** I define a custom devShell with desktop-specific tools, **Then** it appears as `.#desktop` in nix develop
2. **Given** a laptop host with power management tools, **When** I define laptop-specific scripts as apps, **Then** they are accessible via `nix run .#laptop-<script-name>`
3. **Given** multiple hosts with different VM test requirements, **When** each defines its own VM tests, **Then** they run independently via `nix build .#checks.<system>.vm-test-<host>`

---

### User Story 3 - Shared Module System (Priority: P3)

As a system administrator managing multiple NixOS hosts, I want to define shared functionality (common packages, base configuration, reusable components) in flake-parts modules so that I can compose host configurations from reusable building blocks.

**Why this priority**: Reduces duplication and ensures consistency across hosts while maintaining the flexibility to override settings per-host.

**Independent Test**: Can be tested by extracting common configuration (like base packages, networking, users) into shared modules, then importing them in both desktop and laptop hosts, and verifying both systems build with the shared configuration.

**Acceptance Scenarios**:

1. **Given** common package sets used by all hosts, **When** I extract them into a shared packages module, **Then** all hosts can import and use these packages
2. **Given** base system configuration (users, locale, timezone), **When** I define it as a shared module with override capability, **Then** hosts can import it and customize specific values
3. **Given** role-based modules (desktop, laptop, server), **When** a host imports a role module, **Then** it receives all the role's default configuration with the ability to override specifics

---

### Edge Cases

- What happens when a host-specific module conflicts with a shared module setting?
  - **Expected**: Host-specific settings should take precedence using `lib.mkForce` or proper priority ordering
- What happens when flake-parts module structure changes but host modules haven't been updated?
  - **Expected**: Build should fail with clear error messages indicating the incompatibility
- What happens when a new output type needs to be added to all hosts?
  - **Expected**: Should be able to add it to the flake-parts configuration once and have it propagate to all hosts
- What happens when a host is temporarily disabled but its module still exists?
  - **Expected**: The module should be easily toggleable without deletion, and disabled hosts shouldn't appear in flake outputs

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Configuration MUST migrate from monolithic flake.nix structure to flake-parts modular structure while maintaining all existing functionality
- **FR-002**: Configuration MUST support multiple hosts (desktop, laptop, and future additions) using the flake-parts module system
- **FR-003**: Each host MUST be definable as an independent flake-parts module with its own configuration
- **FR-004**: Configuration MUST preserve all existing flake outputs (nixosConfigurations, formatter, checks, apps, devShells)
- **FR-005**: System MUST support per-host custom outputs (host-specific dev shells, apps, checks)
- **FR-006**: Configuration MUST allow shared modules that can be imported by multiple hosts to reduce duplication
- **FR-007**: Configuration MUST maintain backward compatibility with existing build commands (`nixos-rebuild switch --flake .#desktop`)
- **FR-008**: System MUST support host configuration composition (role-based modules + host-specific overrides)
- **FR-009**: Configuration MUST maintain the existing directory structure (hosts/desktop, hosts/laptop, modules/, etc.)
- **FR-010**: Migration MUST preserve all host-specific settings (GPU configuration, package selections, hardware settings)
- **FR-011**: Configuration MUST support different nixpkgs inputs per host (desktop uses unstable, laptop uses stable)
- **FR-012**: System MUST continue to pass all existing validation checks (format-check, lint-check, eval-test)

### Key Entities

- **Flake-Parts Module**: A modular unit of flake configuration that can define outputs, configurations, and be composed with other modules
- **Host Definition**: A flake-parts module representing a single NixOS system with its specific configuration
- **Shared Module**: A reusable flake-parts module that can be imported by multiple host definitions
- **Output Definition**: Configuration for flake outputs (nixosConfigurations, checks, apps, devShells, formatter) within flake-parts structure
- **Host Role**: A categorical configuration pattern (desktop, laptop, server) that can be applied to hosts

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Both existing hosts (desktop and laptop) build successfully after migration with zero functionality loss
- **SC-002**: All existing flake outputs remain accessible with identical paths (backward compatible)
- **SC-003**: Configuration complexity reduces by at least 30% in main flake.nix (measured by line count and nesting depth)
- **SC-004**: Adding a new host requires only creating a new module file, reducing setup time by at least 50%
- **SC-005**: All validation checks (format-check, lint-check, eval-test) pass after migration
- **SC-006**: Flake evaluation time remains within 5% of current baseline (no significant performance regression)
- **SC-007**: Host-specific development shells are accessible and contain the correct tools for each host
- **SC-008**: Shared configuration is defined once and successfully reused across multiple hosts without duplication

## Assumptions

- The flake-parts input is already present in flake.nix inputs (confirmed from codebase analysis)
- Current flake structure follows best practices and all hosts build successfully
- The directory structure (hosts/, modules/) will remain unchanged
- Existing module system and role-based architecture will be preserved
- No breaking changes to the constitution principles (modularity, declarative config, no home manager)
- The migration will be done incrementally with each commit maintaining a working state
